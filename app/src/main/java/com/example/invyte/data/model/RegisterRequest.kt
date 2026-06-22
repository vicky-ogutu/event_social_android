package com.example.invyte.data.model

import com.google.gson.annotations.SerializedName

data class RegisterRequest(
    val email: String,
    val password: String,
    @SerializedName("full_name") val fullName: String,
    @SerializedName("user_type") val userType: String // "vendor" or "consumer"
)