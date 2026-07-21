package com.example.invyte.data.repository

import com.example.invyte.data.network.ApiService
import jakarta.inject.Inject
import jakarta.inject.Singleton

@Singleton
class AdminRepository @Inject constructor(
    private val api: ApiService
) {
    // Add admin endpoints here if needed
}