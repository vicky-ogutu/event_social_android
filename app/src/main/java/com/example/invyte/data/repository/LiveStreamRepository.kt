package com.example.invyte.data.repository

import com.example.invyte.data.model.CreateLivestreamRequest
import com.example.invyte.data.model.Livestream
import com.example.invyte.data.model.LivestreamAccessResponse
import com.example.invyte.data.model.LivestreamPurchaseRequest
import com.example.invyte.data.model.PaymentIntentResponse
import com.example.invyte.data.network.ApiService
import com.example.invyte.utils.safeApiCall
import jakarta.inject.Inject
import jakarta.inject.Singleton

@Singleton
class LivestreamRepository @Inject constructor(
    private val api: ApiService
) {
    suspend fun createLivestream(request: CreateLivestreamRequest): Result<Livestream> =
        safeApiCall { api.createLivestream(request) }

    suspend fun startLivestream(id: Int): Result<Unit> =
        safeApiCall { api.startLivestream(id) }

    suspend fun endLivestream(id: Int): Result<Unit> =
        safeApiCall { api.endLivestream(id) }

    suspend fun getLivestream(id: Int): Result<Livestream> =
        safeApiCall { api.getLivestream(id) }

    suspend fun purchaseLivestream(id: Int): Result<PaymentIntentResponse> =
        safeApiCall { api.purchaseLivestream(id) }

    suspend fun confirmPurchase(livestreamId: Int, paymentIntentId: String): Result<LivestreamAccessResponse> =
        safeApiCall { api.confirmLivestreamPurchase(
            LivestreamPurchaseRequest(
                livestreamId,
                paymentIntentId
            )
        ) }
}