const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const {VertexAI} = require("@google-cloud/vertexai");

admin.initializeApp();

const vertexAI = new VertexAI({
  project: process.env.GCLOUD_PROJECT,
  location: "asia-southeast1",
});

const generativeModel = vertexAI.getGenerativeModel({
  model: "gemini-1.5-flash",
});

/**
 * @param {string} imageUrl The URL of the image to convert
 * @return {Promise<string>} Base64 encoded image data
 */
async function getImageBase64(imageUrl) {
  if (imageUrl.startsWith("gs://")) {
    const bucket = admin.storage().bucket();
    const filePath = imageUrl.replace(/^gs:\/\/[^/]+\//, "");
    const file = bucket.file(filePath);

    const [exists] = await file.exists();
    if (!exists) {
      throw new Error(`File not found in storage: ${imageUrl}`);
    }

    const [buffer] = await file.download();
    return buffer.toString("base64");
  } else if (imageUrl.startsWith("http")) {
    const https = require("https");
    const http = require("http");

    return new Promise((resolve, reject) => {
      const client = imageUrl.startsWith("https") ? https : http;

      client.get(imageUrl, (res) => {
        if (res.statusCode !== 200) {
          const msg = `Failed to fetch image: HTTP ${res.statusCode}`;
          reject(new Error(msg));
          return;
        }

        const chunks = [];
        res.on("data", (chunk) => chunks.push(chunk));
        res.on("end", () => {
          const buffer = Buffer.concat(chunks);
          resolve(buffer.toString("base64"));
        });
        res.on("error", reject);
      }).on("error", reject);
    });
  } else {
    throw new Error(`Unsupported image URL format: ${imageUrl}`);
  }
}

exports.onHazardCreated = onDocumentCreated(
    {document: "hazards_raw/{hazardId}", region: "asia-southeast1"},
    async (event) => {
      const snapshot = event.data;
      if (!snapshot) {
        console.log("No snapshot data received");
        return;
      }

      const hazardData = snapshot.data();
      const hazardId = event.params.hazardId;

      const imageUrl = hazardData.imageUrl;
      const initialDetection = hazardData.detectedBy || "unknown";
      const confidence = hazardData.confidence || 0;

      if (!imageUrl) {
        console.error(`Missing imageUrl for hazard ${hazardId}`);
        await snapshot.ref.update({
          status: "AI_ERROR",
          errorLog: "Missing imageUrl",
        });
        return;
      }

      const msg = `🔍 AI Processing Hazard: ${hazardId} ` +
        `(Detected as: ${initialDetection})`;
      console.log(msg);

      const prompt = `
You are an expert road safety inspector for RoadEye OS.
An on-device AI has detected a potential "${initialDetection}" with ` +
        `${Math.round(confidence * 100)}% confidence.

Analyze the provided image and verify the claim.
Return ONLY a JSON object with this exact structure ` +
        `(no markdown, no extra text):
{
  "is_hazard": true or false,
  "verifiedLabel": "POTHOLE" or "ACCIDENT" or "FLOOD" or "DEBRIS",
  "severity": "LOW" or "MEDIUM" or "HIGH",
  "reason": "short explanation of what you see"
}
        `.trim();

      try {
        console.log(`Fetching image from: ${imageUrl}`);
        const imageBase64 = await getImageBase64(imageUrl);

        const result = await generativeModel.generateContent({
          contents: [{
            role: "user",
            parts: [
              {text: prompt},
              {
                inlineData: {
                  mimeType: "image/jpeg",
                  data: imageBase64,
                },
              },
            ],
          }],
        });

        if (!result.response) {
          throw new Error("No response from Gemini");
        }

        if (!result.response.candidates ||
            result.response.candidates.length === 0) {
          throw new Error("No candidates in Gemini response");
        }

        const candidate = result.response.candidates[0];

        if (!candidate.content || !candidate.content.parts ||
            candidate.content.parts.length === 0) {
          throw new Error("No content parts in Gemini response");
        }

        const responseText = candidate.content.parts[0].text;
        if (!responseText) {
          throw new Error("Empty response text from Gemini");
        }

        console.log(`Gemini raw response: ${responseText}`);

        const cleanedText = responseText.replace(/```json|```/g, "").trim();
        const aiResponse = JSON.parse(cleanedText);

        if (typeof aiResponse.is_hazard !== "boolean") {
          throw new Error(
              "Invalid AI response: missing or invalid is_hazard field",
          );
        }

        const logMsg = `AI Analysis: is_hazard=${aiResponse.is_hazard}, ` +
          `label=${aiResponse.verifiedLabel}`;
        console.log(logMsg);

        if (aiResponse.is_hazard) {
          const verifiedData = {
            lat: hazardData.lat,
            lng: hazardData.lng,
            imageUrl: imageUrl,
            verifiedLabel: aiResponse.verifiedLabel,
            severity: aiResponse.severity,
            aiReason: aiResponse.reason,
            verifiedAt: Date.now(),
            deviceId: hazardData.deviceId || null,
            originalConfidence: confidence,
            originalDetection: initialDetection,
            reportedBy: hazardData.reportedBy || null,
          };

          await admin.firestore()
              .collection("hazards_verified")
              .doc(hazardId)
              .set(verifiedData);

          await snapshot.ref.update({
            status: "VERIFIED",
            verifiedAt: Date.now(),
          });

          const successMsg = `Hazard ${hazardId} VERIFIED and ` +
            `Promoted as ${aiResponse.verifiedLabel}`;
          console.log(successMsg);
        } else {
          await admin.firestore()
              .collection("hazards_rejected")
              .doc(hazardId)
              .set({
                ...hazardData,
                aiReason: aiResponse.reason,
                rejectedAt: Date.now(),
              });

          await snapshot.ref.update({
            status: "REJECTED",
            rejectionReason: aiResponse.reason,
            rejectedAt: Date.now(),
          });

          const rejectMsg = `Hazard ${hazardId} REJECTED ` +
            `(${aiResponse.reason})`;
          console.log(rejectMsg);
        }
      } catch (error) {
        console.error(
            `❗ Critical Brain Error for ${hazardId}:`,
            error.message,
        );
        console.error("Full error:", error);

        try {
          await snapshot.ref.update({
            status: "AI_ERROR",
            errorLog: error.message,
            errorAt: Date.now(),
          });
        } catch (updateError) {
          console.error("Failed to update error status:", updateError);
        }

        try {
          await admin.firestore()
              .collection("hazards_errors")
              .doc(hazardId)
              .set({
                hazardData: hazardData,
                error: error.message,
                errorStack: error.stack,
                errorAt: Date.now(),
              });
        } catch (dbError) {
          console.error("Failed to log error to Firestore:", dbError);
        }
      }
    },
);

