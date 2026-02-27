package com.example.roadeyedriver.data.models

data class IncidentReport(
    val id: String,
    val type: String,
    val latitude: Double,
    val longitude: Double,
    val timestamp: Long,
    val confidence: Float,
    val imageBase64: String? = null // For MVP, we can send base64 image or upload via Storage later
)
