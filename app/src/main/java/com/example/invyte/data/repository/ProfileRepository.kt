package com.example.invyte.data.repository


import com.example.invyte.data.model.*
import com.example.invyte.data.network.ApiService
import com.example.invyte.utils.TokenManager
import okhttp3.MultipartBody
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProfileRepository @Inject constructor(
    private val api: ApiService,
    private val tokenManager: TokenManager
) {

    suspend fun updateProfile(fullName: String, bio: String?): AuthResponse {
        val response = api.updateProfile(UpdateProfileRequest(fullName, bio))
        return if (response.isSuccessful) {
            response.body() ?: AuthResponse(false, "Unknown error", null)
        } else {
            AuthResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun changePassword(oldPassword: String, newPassword: String): AuthResponse {
        val response = api.changePassword(ChangePasswordRequest(oldPassword, newPassword))
        return if (response.isSuccessful) {
            response.body() ?: AuthResponse(false, "Unknown error", null)
        } else {
            AuthResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun uploadAvatar(filePart: MultipartBody.Part): AuthResponse {
        val response = api.uploadAvatar(filePart)
        return if (response.isSuccessful) {
            response.body() ?: AuthResponse(false, "Unknown error", null)
        } else {
            AuthResponse(false, "Server error: ${response.code()}", null)
        }
    }
}