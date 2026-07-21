package com.example.invyte.data.repository

import com.example.invyte.data.model.Booking
import com.example.invyte.data.model.CreateBookingRequest
import com.example.invyte.data.model.CreatePaymentIntentRequest
import com.example.invyte.data.model.PaymentIntentResponse
import com.example.invyte.data.network.ApiService
import com.example.invyte.utils.safeApiCall
import jakarta.inject.Inject
import jakarta.inject.Singleton

@Singleton
class BookingRepository @Inject constructor(
    private val api: ApiService
) {
    suspend fun createBooking(request: CreateBookingRequest): Result<Booking> =
        safeApiCall { api.createBooking(request) }

    suspend fun getMyBookings(page: Int, limit: Int): Result<List<Booking>> =
        safeApiCall { api.getMyBookings(page, limit) }

    suspend fun getBookingDetails(id: Int): Result<Booking> =
        safeApiCall { api.getBookingDetails(id) }

    suspend fun confirmService(id: Int): Result<Unit> =
        safeApiCall { api.confirmService(id) }

    suspend fun completeBooking(id: Int): Result<Unit> =
        safeApiCall { api.completeBooking(id) }

    suspend fun createPaymentIntent(bookingId: Int): Result<PaymentIntentResponse> =
        safeApiCall { api.createPaymentIntent(CreatePaymentIntentRequest(bookingId)) }

    suspend fun getVendorBookings(): Result<List<Booking>> =
        safeApiCall { api.getVendorBookings() }

    suspend fun rejectBooking(bookingId: Int): Result<Unit> =
        safeApiCall { api.rejectBooking(bookingId) }
}