package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Message
import com.example.invyte.data.repository.MessageRepository
import com.example.invyte.utils.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlin.properties.Delegates


@HiltViewModel
class ChatDetailViewModel @Inject constructor(
    private val repo: MessageRepository,
    private val socketManager: SocketManager,
    private val tokenManager: TokenManager
) : ViewModel() {

    private val _messages = MutableStateFlow<List<Message>>(emptyList())
    val messages: StateFlow<List<Message>> = _messages.asStateFlow()

    private val _uiState = MutableStateFlow<ChatDetailUiState>(ChatDetailUiState.Idle)
    val uiState: StateFlow<ChatDetailUiState> = _uiState.asStateFlow()

    private var otherUserId: Int? = null

    // Expose currentUserId as a flow for the UI
    val currentUserIdFlow: Flow<Int?> = tokenManager.getUserIdFlow()

    fun loadConversation(userId: Int) {
        otherUserId = userId
        viewModelScope.launch {
            _uiState.value = ChatDetailUiState.Loading
            val result = repo.getConversation(userId)
            if (result.isSuccess) {
                _messages.value = result.getOrNull() ?: emptyList()
                _uiState.value = ChatDetailUiState.Idle
            } else {
                _uiState.value = ChatDetailUiState.Error(
                    result.exceptionOrNull()?.message ?: "Error loading messages"
                )
            }
        }
        // Listen for new private messages
        viewModelScope.launch {
            socketManager.newPrivateMessage.collect { msg ->
                if (msg.sender_id == userId || msg.receiver_id == userId) {
                    _messages.value = _messages.value + msg
                }
            }
        }
    }

    fun sendMessage(message: String) {
        val receiverId = otherUserId ?: return
        if (message.isBlank()) return
        viewModelScope.launch {
            val userId = tokenManager.getUserIdSync() ?: 0
            // Send via socket (server will save and broadcast)
            socketManager.sendPrivateMessage(receiverId, message)
            // Optimistic update
            val dummy = Message(
                id = 0,
                sender_id = userId,
                receiver_id = receiverId,
                message = message,
                is_read = false,
                read_at = null,
                created_at = ""
            )
            _messages.value = _messages.value + dummy
        }
    }

    fun resetState() {
        _uiState.value = ChatDetailUiState.Idle
    }
}

sealed class ChatDetailUiState {
    object Idle : ChatDetailUiState()
    object Loading : ChatDetailUiState()
    data class Error(val message: String) : ChatDetailUiState()
}

