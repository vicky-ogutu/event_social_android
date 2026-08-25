package com.example.invyte.ui.event

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.repository.EventRepository
import com.example.invyte.ui.vendor.SocketManager
import dagger.hilt.android.lifecycle.HiltViewModel
import jakarta.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

//@HiltViewModel
//class EventDetailViewModel @Inject constructor(
//    private val eventRepo: EventRepository,
//    private val socketManager: SocketManager
//) : ViewModel() {
//    private val _eventState = MutableStateFlow<EventDetailUiState>(EventDetailUiState.Loading)
//    val eventState: StateFlow<EventDetailUiState> = _eventState.asStateFlow()
//
//    fun loadEvent(eventId: Int) {
//        viewModelScope.launch {
//            _eventState.value = EventDetailUiState.Loading
//            val result = eventRepo.getEvent(eventId)
//            _eventState.value = if (result.isSuccess) {
//                EventDetailUiState.Success(result.getOrNull()!!)
//            } else {
//                EventDetailUiState.Error(result.exceptionOrNull()?.message ?: "Error")
//            }
//        }
//    }
//
//    fun joinEventChat(eventId: Int) {
//        viewModelScope.launch {
//            socketManager.connect()
//            socketManager.joinEvent(eventId)
//        }
//    }
//}