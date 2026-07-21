package com.example.invyte.data.network

import android.util.Log
import com.example.invyte.utils.TokenManager
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject

//class AuthInterceptor @Inject constructor(
//    private val tokenManager: TokenManager
//) : Interceptor {
//    override fun intercept(chain: Interceptor.Chain): Response {
//        var request = chain.request()
//        val token = runBlocking { tokenManager.getToken().firstOrNull() }
//        if (token != null) {
//            request = request.newBuilder()
//                .header("Authorization", "Bearer $token")
//                .build()
//        }
//        return chain.proceed(request)
//    }
//}


class AuthInterceptor @Inject constructor(
    private val tokenManager: TokenManager
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        Log.d("AuthInterceptor", ">>> intercept called")
        val originalRequest = chain.request()

        //  Block to get the actual token String from the Flow
        val token: String? = runBlocking {
            tokenManager.getTokenFlow().firstOrNull()
        }
        Log.d("AuthInterceptor", "Retrieved token: $token")   // Log full token

        val requestBuilder = originalRequest.newBuilder()

        if (!token.isNullOrBlank()) {
            // Ensure "Bearer " prefix is added
            requestBuilder.header("Authorization", "Bearer $token")
            Log.d("AuthInterceptor", " Token added: Bearer ${token.take(10)}...")
        } else {
            Log.w("AuthInterceptor", "⚠No token found in DataStore")
        }

        val request = requestBuilder.build()
        return chain.proceed(request)
    }
}