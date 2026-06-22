package com.example.invyte.data.model

data class AuthResponse(
    val success: Boolean,
    val message: String,
    val data: AuthData?
)

data class AuthData(
    val token: String?,
    val user: User?,
    val dashboard: String? // e.g., "consumer_home" or "vendor_home"
)