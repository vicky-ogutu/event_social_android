package com.example.invyte.ui.event

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Event
import com.example.invyte.data.model.EventRequest
import com.example.invyte.data.repository.EventRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class EventsUiState {
    object Idle : EventsUiState()
    object Loading : EventsUiState()
    data class Success(val events: List<Event>, val total: Int, val page: Int, val pages: Int) : EventsUiState()
    data class Error(val message: String) : EventsUiState()
}


sealed class EventDetailUiState {
    object Idle : EventDetailUiState()
    object Loading : EventDetailUiState()
    data class Success(val event: Event) : EventDetailUiState()
    data class Error(val message: String) : EventDetailUiState()
}

sealed class EventActionUiState {
    object Idle : EventActionUiState()
    object Loading : EventActionUiState()
    data class Success(val message: String) : EventActionUiState()
    data class Error(val message: String) : EventActionUiState()
}

@HiltViewModel
class EventViewModel @Inject constructor(
    private val eventRepository: EventRepository
) : ViewModel() {

    // For listing events (public)
    private val _eventsState = MutableStateFlow<EventsUiState>(EventsUiState.Idle)
    val eventsState: StateFlow<EventsUiState> = _eventsState.asStateFlow()

    // For user's own events (my-events)
    private val _myEventsState = MutableStateFlow<EventsUiState>(EventsUiState.Idle)
    val myEventsState: StateFlow<EventsUiState> = _myEventsState.asStateFlow()

    // For event detail
    private val _detailState = MutableStateFlow<EventDetailUiState>(EventDetailUiState.Idle)
    val detailState: StateFlow<EventDetailUiState> = _detailState.asStateFlow()

    // For actions (create, update, delete, join, like)
    private val _actionState = MutableStateFlow<EventActionUiState>(EventActionUiState.Idle)
    val actionState: StateFlow<EventActionUiState> = _actionState.asStateFlow()

    // ----- List events -----
    fun listEvents(
        eventType: String? = null,
        dateFrom: String? = null,
        dateTo: String? = null,
        search: String? = null,
        page: Int = 1,
        limit: Int = 20
    ) {
        viewModelScope.launch {
            _eventsState.value = EventsUiState.Loading
            try {
                val response = eventRepository.listEvents(eventType, dateFrom, dateTo, search, page, limit)
                if (response.success && response.data != null) {
                    _eventsState.value = EventsUiState.Success(
                        events = response.data.data,
                        total = response.data.total,
                        page = response.data.page,
                        pages = response.data.pages
                    )
                } else {
                    _eventsState.value = EventsUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _eventsState.value = EventsUiState.Error(e.localizedMessage ?: "Failed to load events")
            }
        }
    }


    fun getMyEvents() {
        viewModelScope.launch {
            _myEventsState.value = EventsUiState.Loading
            val result = eventRepository.getMyEvents()
            _myEventsState.value = if (result.isSuccess) {
                val listResponse = result.getOrNull()!!
                EventsUiState.Success(
                    events = listResponse.data,
                    total = listResponse.total,
                    page = listResponse.page,
                    pages = listResponse.pages
                )
            } else {
                EventsUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load my events")
            }
        }
    }

    // ----- Get event detail -----
    fun getEvent(id: Int) {
        viewModelScope.launch {
            _detailState.value = EventDetailUiState.Loading
            try {
                val response = eventRepository.getEvent(id)
                if (response.success && response.data != null) {
                    _detailState.value = EventDetailUiState.Success(response.data)
                } else {
                    _detailState.value = EventDetailUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _detailState.value = EventDetailUiState.Error(e.localizedMessage ?: "Failed to load event details")
            }
        }
    }

    // ----- Create event -----
    fun createEvent(request: EventRequest) {
        viewModelScope.launch {
            _actionState.value = EventActionUiState.Loading
            try {
                val response = eventRepository.createEvent(request)
                if (response.success && response.data != null) {
                    _actionState.value = EventActionUiState.Success("Event created successfully")
                } else {
                    _actionState.value = EventActionUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _actionState.value = EventActionUiState.Error(e.localizedMessage ?: "Failed to create event")
            }
        }
    }

    // ----- Update event -----
    fun updateEvent(id: Int, request: EventRequest) {
        viewModelScope.launch {
            _actionState.value = EventActionUiState.Loading
            try {
                val response = eventRepository.updateEvent(id, request)
                if (response.success && response.data != null) {
                    _actionState.value = EventActionUiState.Success("Event updated successfully")
                } else {
                    _actionState.value = EventActionUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _actionState.value = EventActionUiState.Error(e.localizedMessage ?: "Failed to update event")
            }
        }
    }

    // ----- Delete event -----
    fun deleteEvent(id: Int) {
        viewModelScope.launch {
            _actionState.value = EventActionUiState.Loading
            try {
                val response = eventRepository.deleteEvent(id)
                if (response.success) {
                    _actionState.value = EventActionUiState.Success("Event deleted")
                } else {
                    _actionState.value = EventActionUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _actionState.value = EventActionUiState.Error(e.localizedMessage ?: "Failed to delete event")
            }
        }
    }

    // ----- Join event -----
    fun joinEvent(id: Int, accessCode: String) {
        viewModelScope.launch {
            _actionState.value = EventActionUiState.Loading
            try {
                val response = eventRepository.joinEvent(id, accessCode)
                if (response.success) {
                    _actionState.value = EventActionUiState.Success(response.message)
                } else {
                    _actionState.value = EventActionUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _actionState.value = EventActionUiState.Error(e.localizedMessage ?: "Failed to join event")
            }
        }
    }

    // ----- Toggle like -----
    fun toggleLike(id: Int) {
        viewModelScope.launch {
            // We don't need separate loading for like, just call and refresh if needed
            try {
                val response = eventRepository.toggleLike(id)
                if (response.success && response.data != null) {
                    // Update the current detail state if we are on detail screen
                    val currentDetail = _detailState.value
                    if (currentDetail is EventDetailUiState.Success) {
                        val updatedEvent = currentDetail.event.copy(
                            likeCount = (currentDetail.event.likeCount ?: 0) + if (response.data.liked) 1 else -1
                        )
                        _detailState.value = EventDetailUiState.Success(updatedEvent)
                    }
                    // Optionally refresh list if needed
                } else {
                    // Show error?
                }
            } catch (e: Exception) {
                // handle
            }
        }
    }

    // Reset action state after a while
    fun resetActionState() {
        _actionState.value = EventActionUiState.Idle
    }

    fun resetDetailState() {
        _detailState.value = EventDetailUiState.Idle
    }
}