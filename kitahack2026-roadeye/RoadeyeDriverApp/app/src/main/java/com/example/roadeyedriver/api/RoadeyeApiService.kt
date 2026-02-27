package com.example.roadeyedriver.api

import com.example.roadeyedriver.data.models.IncidentReport
import retrofit2.Response
import retrofit2.http.Body
import retrofit2.http.POST

interface RoadeyeApiService {
    /**
     * Sends a new pothole or road hazard report to the Cloud Run / Cloud Functions backend.
     */
    @POST("api/v1/incidents/report")
    suspend fun reportIncident(@Body report: IncidentReport): Response<Unit>
}
