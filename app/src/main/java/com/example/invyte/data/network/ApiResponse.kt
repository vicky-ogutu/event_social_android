package com.example.invyte.data.network

data class ApiResponse<T>(
    val success: Boolean,
    val message: String? = null,
    val data: T? = null
)