package com.example.invyte.ui.vendor


import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Booking
import com.example.invyte.data.model.CreateBookingRequest
import com.example.invyte.data.model.Event
import com.example.invyte.data.model.Service
import com.example.invyte.data.repository.BookingRepository
import com.example.invyte.data.repository.EventRepository
import com.example.invyte.data.repository.VendorRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import com.example.invyte.ui.BookingUiState

@HiltViewModel
class BookingViewModel @Inject constructor(
    private val bookingRepo: BookingRepository,
    private val vendorRepo: VendorRepository,
    private val eventRepo: EventRepository
) : ViewModel() {

    // Existing states...
    private val _bookingUiState = MutableStateFlow<BookingUiState>(BookingUiState.Idle)
    val bookingUiState: StateFlow<BookingUiState> = _bookingUiState.asStateFlow()

    private val _userEvents = MutableStateFlow<List<Event>>(emptyList())
    val userEvents: StateFlow<List<Event>> = _userEvents.asStateFlow()

    private val _selectedService = MutableStateFlow<Service?>(null)
    val selectedService: StateFlow<Service?> = _selectedService.asStateFlow()

    private val _vendorName = MutableStateFlow<String?>(null)
    val vendorName: StateFlow<String?> = _vendorName.asStateFlow()

    private val _selectedEvent = MutableStateFlow<Event?>(null)
    val selectedEvent: StateFlow<Event?> = _selectedEvent.asStateFlow()

    private val _serviceDate = MutableStateFlow("")
    val serviceDate: StateFlow<String> = _serviceDate.asStateFlow()

    private val _serviceTime = MutableStateFlow("")
    val serviceTime: StateFlow<String> = _serviceTime.asStateFlow()

    private val _quantity = MutableStateFlow(1)
    val quantity: StateFlow<Int> = _quantity.asStateFlow()

    private val _specialRequests = MutableStateFlow("")
    val specialRequests: StateFlow<String> = _specialRequests.asStateFlow()

    private val _isSubmitting = MutableStateFlow(false)
    val isSubmitting: StateFlow<Boolean> = _isSubmitting.asStateFlow()

    fun loadVendorAndService(vendorId: Int, serviceId: Int) {
        viewModelScope.launch {
            _bookingUiState.value = BookingUiState.Loading
            val result = vendorRepo.getVendorDetails(vendorId)
            if (result.isSuccess) {
                val vendor = result.getOrNull()!!
                _vendorName.value = vendor.business_name
                // Find the specific service by ID
                val service = vendor.services?.find { it.id == serviceId }
                if (service != null) {
                    _selectedService.value = service
                    _bookingUiState.value = BookingUiState.Idle
                } else {
                    _bookingUiState.value = BookingUiState.Error("Service not found for this vendor")
                }
            } else {
                _bookingUiState.value = BookingUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load vendor")
            }
        }
    }

    fun loadUserEvents() {
        viewModelScope.launch {
            val result = eventRepo.getMyEvents() // you need to implement this in EventRepository
            if (result.isSuccess) {
                _userEvents.value = result.getOrNull() ?: emptyList()
            }
        }
    }

    fun selectEvent(event: Event) {
        _selectedEvent.value = event
    }

    fun updateDate(date: String) {
        _serviceDate.value = date
    }

    fun updateTime(time: String) {
        _serviceTime.value = time
    }

    fun updateQuantity(qty: Int) {
        _quantity.value = qty
    }

    fun updateSpecialRequests(requests: String) {
        _specialRequests.value = requests
    }

    fun createBooking(request: CreateBookingRequest) {
        viewModelScope.launch {
            _isSubmitting.value = true
            _bookingUiState.value = BookingUiState.Loading
            val result = bookingRepo.createBooking(request)
            _isSubmitting.value = false
            _bookingUiState.value = if (result.isSuccess) {
                BookingUiState.BookingSuccess(result.getOrNull()!!)  // 👈 changed
            } else {
                BookingUiState.Error(result.exceptionOrNull()?.message ?: "Booking failed")
            }
        }
    }

    fun resetBookingState() {
        _bookingUiState.value = BookingUiState.Idle
    }
}