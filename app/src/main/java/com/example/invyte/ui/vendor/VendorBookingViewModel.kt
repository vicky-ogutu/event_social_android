package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Booking
import com.example.invyte.data.repository.BookingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import jakarta.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class VendorBookingViewModel @Inject constructor(
    private val bookingRepo: BookingRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<VendorBookingUiState>(VendorBookingUiState.Loading)
    val uiState: StateFlow<VendorBookingUiState> = _uiState.asStateFlow()

    fun loadBookings() {
        viewModelScope.launch {
            _uiState.value = VendorBookingUiState.Loading
            val result = bookingRepo.getVendorBookings() // new endpoint: GET /api/bookings/vendor
            if (result.isSuccess) {
                _uiState.value = VendorBookingUiState.BookingsLoaded((result.getOrNull() ?: emptyList()) as List<Booking>)
            } else {
                _uiState.value = VendorBookingUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load")
            }
        }
    }

    fun confirmBooking(bookingId: Int) {
        viewModelScope.launch {
            val result = bookingRepo.confirmService(bookingId)
            handleAction(result, "Booking confirmed")
        }
    }

    fun completeBooking(bookingId: Int) {
        viewModelScope.launch {
            val result = bookingRepo.completeBooking(bookingId)
            handleAction(result, "Booking completed")
        }
    }

    fun rejectBooking(bookingId: Int) {
        viewModelScope.launch {
            val result = bookingRepo.rejectBooking(bookingId) // new endpoint
            handleAction(result, "Booking rejected")
        }
    }

    private fun handleAction(result: Result<Unit>, successMessage: String) {
        if (result.isSuccess) {
            _uiState.value = VendorBookingUiState.ActionSuccess(successMessage)
        } else {
            _uiState.value = VendorBookingUiState.Error(result.exceptionOrNull()?.message ?: "Action failed")
        }
    }

    fun resetActionState() {
        if (_uiState.value is VendorBookingUiState.ActionSuccess ||
            _uiState.value is VendorBookingUiState.Error) {
            // Keep current state but allow refresh; we'll reload on next load
        }
    }
}

sealed class VendorBookingUiState {
    object Loading : VendorBookingUiState()
    data class BookingsLoaded(val bookings: List<Booking>) : VendorBookingUiState()
    data class ActionSuccess(val message: String) : VendorBookingUiState()
    data class Error(val message: String) : VendorBookingUiState()
}