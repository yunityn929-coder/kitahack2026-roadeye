const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentCreated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const { getStorage } = require("firebase-admin/storage");
const { VertexAI } = require("@google-cloud/vertexai");
const axios = require("axios");

initializeApp();

const db = getFirestore();
const storage = getStorage();

const PROJECT_ID = "roadeye-hackathon";
const LOCATION = "asia-southeast1";
const MODEL      = "gemini-1.5-flash";

const vertexAI = new VertexAI({ project: PROJECT_ID, location: LOCATION });
const geminiModel = vertexAI.getGenerativeModel({ model: MODEL });

const SYSTEM_PROMPT = `You are a road hazard detection AI.
Analyze the image and determine if it contains a pothole or road damage.

Respond ONLY in this exact JSON format (no markdown, no extra text):
{
  "isPothole": true or false,
  "confidence": 0.0 to 1.0,
  "severity": "LOW" or "MEDIUM" or "HIGH",
  "description": "brief one-sentence description"
}

Confidence scoring guide:
- 0.0–0.49 → not a pothole / very minor surface wear
- 0.50–0.79 → moderate pothole / road damage
- 0.80–1.00 → severe pothole / dangerous hazard`;

exports.submitPothole = onCall(
  { region: LOCATION, timeoutSeconds: 60 },
  async (request) => {
    const { imageBase64, imageUrl, lat, lng, detectedBy } = request.data;

    if (!lat || !lng) {
      throw new HttpsError("invalid-argument", "lat and lng are required.");
    }
    if (!imageBase64 && !imageUrl) {
      throw new HttpsError("invalid-argument", "imageBase64 or imageUrl is required.");
    }

    let storedImageUrl = imageUrl ?? null;
    if (imageBase64 && !imageUrl) {
      storedImageUrl = await uploadBase64Image(imageBase64, detectedBy);
    }

    const docRef = await db.collection("hazards_raw").add({
      lat,
      lng,
      detectedBy: detectedBy ?? "UNKNOWN",
      imageUrl: storedImageUrl ?? "",
      status: "PENDING",
      confidence: 0,
      severity: "UNKNOWN",
      description: "",
      createdAt: FieldValue.serverTimestamp(),
      verifiedAt: null,
    });

    await runGeminiVerification(docRef.id, storedImageUrl, imageBase64);

    return { success: true, docId: docRef.id };
  }
);

exports.onHazardCreated = onDocumentCreated(
  { document: "hazards_raw/{docId}", region: LOCATION },
  async (event) => {
    const docId  = event.params.docId;
    const data   = event.data.data();

    // Skip if already processed
    if (data.status !== "PENDING") return;

    const imageUrl    = data.imageUrl ?? null;
    const imageBase64 = data.imageBase64 ?? null;

    await runGeminiVerification(docId, imageUrl, imageBase64);
  }
);

exports.retryVerification = onCall(
  { region: LOCATION, timeoutSeconds: 60 },
  async (request) => {
    const { docId } = request.data;
    if (!docId) throw new HttpsError("invalid-argument", "docId is required.");

    const docSnap = await db.collection("hazards_raw").doc(docId).get();
    if (!docSnap.exists) throw new HttpsError("not-found", "Document not found.");

    const data = docSnap.data();
    await runGeminiVerification(docId, data.imageUrl, null);

    return { success: true };
  }
);

async function runGeminiVerification(docId, imageUrl, imageBase64) {
  try {
    let imagePart;

    if (imageBase64) {
      // Use raw base64 directly
      imagePart = {
        inlineData: {
          mimeType: "image/jpeg",
          data: imageBase64,
        },
      };
    } else if (imageUrl) {
      const base64 = await fetchImageAsBase64(imageUrl);
      imagePart = {
        inlineData: {
          mimeType: "image/jpeg",
          data: base64,
        },
      };
    } else {
      await db.collection("hazards_raw").doc(docId).update({
        status: "UNVERIFIED",
        verifiedAt: FieldValue.serverTimestamp(),
        errorMessage: "No image provided for verification.",
      });
      return;
    }

    const response = await geminiModel.generateContent({
      contents: [
        {
          role: "user",
          parts: [
            { text: SYSTEM_PROMPT },
            imagePart,
            { text: "Analyze this road image now." },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.1,   
        maxOutputTokens: 256,
      },
    });

    const rawText = response.response.candidates[0].content.parts[0].text;

    const parsed = parseGeminiResponse(rawText);

    const newStatus = (parsed.isPothole && parsed.confidence >= 0.5)
      ? "ACTIVE"
      : "RESOLVED";

    await db.collection("hazards_raw").doc(docId).update({
      status:      newStatus,
      confidence:  parsed.confidence,
      severity:    parsed.severity,
      description: parsed.description,
      isPothole:   parsed.isPothole,
      verifiedAt:  FieldValue.serverTimestamp(),
      errorMessage: null,
      geminiRaw:   rawText, 
    });

    console.log(`[RoadEye] Doc ${docId} → ${newStatus} (confidence: ${parsed.confidence})`);

  } catch (err) {
    console.error(`[RoadEye] Gemini verification failed for ${docId}:`, err);

    // Mark doc as ERROR so dashboard can flag it
    await db.collection("hazards_raw").doc(docId).update({
      status: "ERROR",
      errorMessage: err.message ?? "Unknown error during verification.",
      verifiedAt: FieldValue.serverTimestamp(),
    });
  }
}

function parseGeminiResponse(rawText) {
  try {
    const cleaned = rawText
      .replace(/```json/gi, "")
      .replace(/```/g, "")
      .trim();

    const json = JSON.parse(cleaned);

    return {
      isPothole:   Boolean(json.isPothole),
      confidence:  Math.min(1, Math.max(0, Number(json.confidence) || 0)),
      severity:    ["LOW", "MEDIUM", "HIGH"].includes(json.severity)
                     ? json.severity
                     : "LOW",
      description: String(json.description ?? ""),
    };
  } catch (e) {
    console.warn("[RoadEye] Could not parse Gemini JSON, using defaults. Raw:", rawText);
    return {
      isPothole:   false,
      confidence:  0,
      severity:    "LOW",
      description: "Parse error — manual review required.",
    };
  }
}

async function fetchImageAsBase64(url) {
  const response = await axios.get(url, { responseType: "arraybuffer" });
  return Buffer.from(response.data).toString("base64");
}

async function uploadBase64Image(base64, detectedBy) {
  const bucket    = storage.bucket();
  const filename  = `hazards/${detectedBy ?? "unknown"}_${Date.now()}.jpg`;
  const file      = bucket.file(filename);
  const buffer    = Buffer.from(base64, "base64");

  await file.save(buffer, {
    metadata: { contentType: "image/jpeg" },
    public: true,
  });

  const [url] = await file.getSignedUrl({
    action: "read",
    expires: "01-01-2100",
  });

  return url;
}
