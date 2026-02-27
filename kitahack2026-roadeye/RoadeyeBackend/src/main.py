import os
import pygeohash as geohash
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
from datetime import datetime
import firebase_admin
from firebase_admin import credentials, firestore

# Initialize Firebase (requires GOOGLE_APPLICATION_CREDENTIALS)
# try:
#     firebase_admin.initialize_app()
#     db = firestore.client()
# except Exception as e:
#     print(f"Warning: Firebase initialization skipped. {e}")

app = FastAPI(
    title="RoadEye Backend Service",
    description="FastAPI service for ingesting automated road hazard reports and verifying them via AI.",
    version="1.0.0"
)

class IncidentReport(BaseModel):
    id: str
    type: str # e.g. "pothole"
    latitude: float
    longitude: float
    timestamp: int
    confidence: float
    imageBase64: Optional[str] = None

@app.get("/health")
def health_check():
    """Simple health check endpoint for Cloud Run scaling metrics."""
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/v1/incidents/report", status_code=201)
async def report_incident(report: IncidentReport):
    """
    Ingestion Endpoint: 
    Receives an automated pothole report from the Android CameraX AI model.
    """
    # 1. Generate a Geohash string (e.g. 7 characters for ~153mx153m grid resolution)
    #    Useful for quick DB querying when DBSCAN needs to cluster points.
    geo_hash = geohash.encode(report.latitude, report.longitude, precision=7)

    # 2. For MVP: we might just store directly to Firestore
    # In production, we would push to Google Cloud Pub/Sub
    
    # Optional Firebase insertion snippet (Uncomment when credentials are set)
    # try:
    #     doc_ref = db.collection('incidents').document(report.id)
    #     doc_ref.set({
    #         "type": report.type,
    #         "location": firestore.GeoPoint(report.latitude, report.longitude),
    #         "geohash": geo_hash,
    #         "timestamp": report.timestamp,
    #         "confidence": report.confidence,
    #         "status": "pending_verification" # Let Gemini or humans verify if confidence is low
    #     })
    # except Exception as e:
    #     raise HTTPException(status_code=500, detail="Database write failed")

    return {
        "message": "Incident reported successfully",
        "incident_id": report.id,
        "geohash": geo_hash
    }

if __name__ == "__main__":
    import uvicorn
    # uvicorn handles the local server. Cloud Run sets PORT environment variable.
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port)
