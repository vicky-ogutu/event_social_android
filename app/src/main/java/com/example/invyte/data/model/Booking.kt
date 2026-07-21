package com.example.invyte.data.model

data class Booking(
    val id: Int,
    val booking_reference: String,
    val event_id: Int,
    val vendor_service_id: Int,
    val vendor_id: Int,
    val consumer_id: Int,
    val booking_date: String,
    val service_date: String,
    val service_time: String,
    val quantity: Int,
    val agreed_price: Double,
    val service_fee: Double,
    val tax_amount: Double,
    val total_amount: Double,
    val amount_paid: Double,
    val payment_status: String,
    val vendor_payment_status: String,
    val booking_status: String,
    val special_requests: String?,
    val event_name: String?,
    val vendor_name: String?,
    val service_name: String?
)

data class CreateBookingRequest(
    val event_id: Int,
    val vendor_service_id: Int,
    val service_date: String,
    val service_time: String,
    val quantity: Int,
    val special_requests: String?
)

data class PaymentIntentResponse(
    val client_secret: String,
    val payment_intent_id: String
)
