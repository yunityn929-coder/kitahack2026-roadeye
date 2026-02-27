package com.example.roadeyedriver.data.repository

import android.util.Log
import com.example.roadeyedriver.api.RoadeyeApiClient
import com.example.roadeyedriver.data.models.IncidentReport
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

class IncidentRepository {

    suspend fun sendReport(report: IncidentReport): Result<Unit> = withContext(Dispatchers.IO) {
        try {
            Log.d("IncidentRepository", "Attempting to send report: ${report.id}")
            // Uncomment the actual API call once the backend is ready
            // val response = RoadeyeApiClient.apiService.reportIncident(report)
            // if (response.isSuccessful) {
            //     Log.d("IncidentRepository", "Report sent successfully!")
            //     Result.success(Unit)
            // } else {
            //     Log.e("IncidentRepository", "API Error: ${response.errorBody()?.string()}")
            //     Result.failure(Exception("HTTP Error: ${response.code()}"))
            // }

            // Mock success for now
            kotlinx.coroutines.delay(1000)
            Log.d("IncidentRepository", "Mock API call successful")
            Result.success(Unit)
        } catch (e: Exception) {
            Log.e("IncidentRepository", "Network or generic exception", e)
            Result.failure(e)
        }
    }
}
