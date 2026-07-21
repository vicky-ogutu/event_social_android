package com.example.invyte.ui

import com.example.invyte.data.model.Booking

sealed class BookingUiState {
    object Idle : BookingUiState()
    object Loading : BookingUiState()
    data class Success(val booking: Booking) : BookingUiState()
    data class BookingsLoaded(val bookings: List<Booking>) : BookingUiState()
    data class BookingSuccess(val booking: Booking) : BookingUiState()  // 👈 add this
    data class ConfirmSuccess(val message: String = "Service confirmed successfully") : BookingUiState()
    data class CompleteSuccess(val message: String = "Booking completed successfully") : BookingUiState()
    data class Error(val message: String) : BookingUiState()
}