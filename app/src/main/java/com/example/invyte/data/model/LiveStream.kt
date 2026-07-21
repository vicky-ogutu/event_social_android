package com.example.invyte.data.model

data class Livestream(
    val id: Int,
    val event_id: Int,
    val stream_key: String,
    val stream_url: String,
    val stream_status: String,
    val view_count: Int,
    val pay_per_view_price: Double,
    val scheduled_start: String?,
    val actual_start: String?,
    val actual_end: String?,
    val recording_url: String?,
    val total_revenue: Double,
    val event_name: String?
)

data class CreateLivestreamRequest(
    val event_id: Int,
    val pay_per_view_price: Double = 0.0,
    val scheduled_start: String? = null
)

data class LivestreamPurchaseRequest(
    val livestream_id: Int,
    val payment_intent_id: String
)

data class LivestreamAccessResponse(
    val access_token: String
)
