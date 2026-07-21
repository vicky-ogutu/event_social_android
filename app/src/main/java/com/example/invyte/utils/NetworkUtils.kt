package com.example.invyte.utils


import com.example.invyte.data.network.ApiResponse
import retrofit2.Response

/**
 * Safe API call wrapper that handles errors and returns a Result<T>.
 */
suspend fun <T> safeApiCall(apiCall: suspend () -> Response<ApiResponse<T>>): Result<T> {
    return try {
        val response = apiCall()
        if (response.isSuccessful) {
            val body = response.body()
            if (body != null && body.success) {
                Result.success(body.data!!)
            } else {
                Result.failure(Exception(body?.message ?: "Unknown error"))
            }
        } else {
            Result.failure(Exception("HTTP ${response.code()}: ${response.message()}"))
        }
    } catch (e: Exception) {
        Result.failure(e)
    }
}