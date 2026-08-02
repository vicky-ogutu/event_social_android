package com.example.invyte.utils


import com.example.invyte.data.network.ApiResponse
import retrofit2.Response

/**
 * Safe API call wrapper that handles errors and returns a Result<T>.
 */
//suspend fun <T> safeApiCall(apiCall: suspend () -> Response<ApiResponse<T>>): Result<T> {
//    return try {
//        val response = apiCall()
//        if (response.isSuccessful) {
//            val body = response.body()
//            if (body != null && body.success) {
//                Result.success(body.data!!)
//            } else {
//                Result.failure(Exception(body?.message ?: "Unknown error"))
//            }
//        } else {
//            Result.failure(Exception("HTTP ${response.code()}: ${response.message()}"))
//        }
//    } catch (e: Exception) {
//        Result.failure(e)
//    }
//}



/**
 * Safely execute an API call and return a Result wrapper.
 * For endpoints returning Unit, null data is acceptable and treated as success.
 */
inline suspend fun <reified T> safeApiCall(
    crossinline apiCall: suspend () -> Response<ApiResponse<T>>
): Result<T> {
    return try {
        val response = apiCall()
        if (response.isSuccessful) {
            val body = response.body()
            if (body != null && body.success) {
                val data = body.data
                if (data != null) {
                    Result.success(data)
                } else {
                    // If T is Unit, null is acceptable – treat as success with Unit
                    if (Unit::class.java == T::class.java) {
                        @Suppress("UNCHECKED_CAST")
                        Result.success(Unit as T)
                    } else {
                        Result.failure(Exception("Data is null, but expected non-null type"))
                    }
                }
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