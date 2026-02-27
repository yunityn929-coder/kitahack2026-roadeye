package com.example.roadeyedriver.api

import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

object RoadeyeApiClient {
    // For local testing use 10.0.2.2 instead of localhost for the Android Emulator
    // E.g. "http://10.0.2.2:8000/" for local FastAPI development
    private const val BASE_URL = "https://roadeye-mvp.uc.r.appspot.com/" // Replace with real deployed URL

    private val httpClient: OkHttpClient by lazy {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY // Useful for debugging in MVP phase
        }

        OkHttpClient.Builder()
            .addInterceptor(loggingInterceptor)
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .build()
    }

    private val retrofit: Retrofit by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(httpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    val apiService: RoadeyeApiService by lazy {
        retrofit.create(RoadeyeApiService::class.java)
    }
}
