package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Message
import com.example.invyte.data.repository.MessageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import jakarta.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class ChatDetailViewModel @Inject constructor(
    private val repo: MessageRepository,
    private val socketManager: SocketManager
) : ViewModel() {
    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()

    private val _uiState = MutableStateFlow<ChatDetailUiState>(ChatDetailUiState.Idle)
    val uiState: StateFlow<ChatDetailUiState> = _uiState.asStateFlow()

    private lateinit var otherUserId: Int

    fun loadConversation(userId: Int) {
        otherUserId = userId
        viewModelScope.launch {
            _uiState.value = ChatDetailUiState.Loading
            val result = repo.getConversation(userId)
            if (result.isSuccess) {
                _messages.value = result.getOrNull() ?: emptyList()
                _uiState.value = ChatDetailUiState.Idle
            } else {
                _uiState.value = ChatDetailUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
        // Listen for new private messages from this user
        viewModelScope.launch {
            socketManager.newPrivateMessage.collect { msg ->
                if (msg.sender_id == userId || msg.receiver_id == userId) {
                    _messages.value = _messages.value + msg
                }
            }
        }
    }

    fun sendMessage(message: String) {
        if (message.isBlank()) return
        viewModelScope.launch {
            val result = repo.sendMessage(otherUserId, message)
            if (result.isSuccess) {
                // The socket will broadcast, but we can also add optimistically
                val sent = result.getOrNull()
                if (sent != null) {
                    _messages.value = _messages.value + sent
                }
            }
        }
    }
}

sealed class ChatDetailUiState {
    object Idle : ChatDetailUiState()
    object Loading : ChatDetailUiState()
    data class Error(val message: String) : ChatDetailUiState()
}