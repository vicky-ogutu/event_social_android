package com.example.invyte.data.repository

import com.example.invyte.data.network.ApiService
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AdminRepository @Inject constructor(
    private val api: ApiService
) {
    // Add admin endpoints here if needed
}