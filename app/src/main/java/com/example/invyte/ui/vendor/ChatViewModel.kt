package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.ChatMessage
import com.example.invyte.data.repository.SocialRepository
import com.example.invyte.utils.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class ChatViewModel @Inject constructor(
    private val socialRepo: SocialRepository,
    private val socketManager: SocketManager,
    private val tokenManager: TokenManager
) : ViewModel() {

    private val _messages = MutableStateFlow<List<ChatMessage>>(emptyList())
    val messages: StateFlow<List<ChatMessage>> = _messages.asStateFlow()

    private val _uiState = MutableStateFlow<ChatUiState>(ChatUiState.Idle)
    val uiState: StateFlow<ChatUiState> = _uiState.asStateFlow()

    private var currentEventId: Int? = null

    fun joinEventChat(eventId: Int) {
        currentEventId = eventId
        viewModelScope.launch {
            socketManager.connect()
            socketManager.joinEvent(eventId)
            loadHistoricalMessages(eventId)
            // Collect new messages
            socketManager.newMessage.collect { message ->
                if (message.event_id == eventId) {
                    _messages.value = _messages.value + message
                }
            }
        }
    }

    fun loadHistoricalMessages(eventId: Int) {
        viewModelScope.launch {
            _uiState.value = ChatUiState.Loading
            val result = socialRepo.getChatMessages(eventId, 1, 50)
            if (result.isSuccess) {
                _messages.value = result.getOrNull() ?: emptyList()
                _uiState.value = ChatUiState.Idle
            } else {
                _uiState.value = ChatUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load messages")
            }
        }
    }

    fun sendMessage(eventId1: Int, message: String) {
        val eventId = currentEventId ?: return
        if (message.isBlank()) return
        viewModelScope.launch {
            val userId = tokenManager.getUserIdSync() ?: 0
            socketManager.sendMessage(eventId, message, userId)
            // Optimistic update (optional)
            val dummy = ChatMessage(
                id = 0,
                event_id = eventId,
                user_id = userId,
                message = message,
                message_type = "text",
                media_url = null,
                is_read = false,
                created_at = "",
                full_name = "Me",
                profile_picture = null
            )
            _messages.value = _messages.value + dummy
        }
    }

    fun leaveChat() {
        currentEventId?.let { socketManager.leaveEvent(it) }
        socketManager.disconnect()
    }

    override fun onCleared() {
        super.onCleared()
        socketManager.disconnect()
    }
}

sealed class ChatUiState {
    object Idle : ChatUiState()
    object Loading : ChatUiState()
    data class Error(val message: String) : ChatUiState()
}