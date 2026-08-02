package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Conversation
import com.example.invyte.data.repository.MessageRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class ConversationListViewModel @Inject constructor(
    private val repo: MessageRepository,
    private val socketManager: SocketManager
) : ViewModel() {
    private val _uiState = MutableStateFlow<ConversationListUiState>(ConversationListUiState.Loading)
    val uiState: StateFlow<ConversationListUiState> = _uiState.asStateFlow()

    init {
        loadConversations()
        // Listen for new private messages
        viewModelScope.launch {
            socketManager.newPrivateMessage.collect { message ->
                // Refresh list when a new message arrives
                loadConversations()
            }
        }
    }

    fun loadConversations() {
        viewModelScope.launch {
            _uiState.value = ConversationListUiState.Loading
            val result = repo.getConversations()
            _uiState.value = if (result.isSuccess) {
                ConversationListUiState.Success((result.getOrNull() ?: emptyList()) as List<Conversation>)
            } else {
                ConversationListUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
    }
}

sealed class ConversationListUiState {
    object Loading : ConversationListUiState()
    data class Success(val conversations: List<Conversation>) : ConversationListUiState()
    data class Error(val message: String) : ConversationListUiState()
}