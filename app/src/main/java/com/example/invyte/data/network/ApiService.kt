package com.example.invyte.data.network

import com.example.invyte.data.model.AuthResponse
import com.example.invyte.data.model.LoginRequest
import com.example.invyte.data.model.RegisterRequest
import retrofit2.http.Body
import retrofit2.http.POST

interface ApiService {
    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): AuthResponse

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): AuthResponse
}