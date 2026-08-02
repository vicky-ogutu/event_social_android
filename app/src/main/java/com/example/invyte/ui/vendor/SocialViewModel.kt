package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.SocialPost
import com.example.invyte.data.repository.SocialRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch


@HiltViewModel
class SocialFeedViewModel @Inject constructor(
    private val socialRepo: SocialRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<SocialFeedUiState>(SocialFeedUiState.Loading)
    val uiState: StateFlow<SocialFeedUiState> = _uiState.asStateFlow()

    fun loadFeed(eventId: Int? = null) {
        viewModelScope.launch {
            _uiState.value = SocialFeedUiState.Loading
            val result = socialRepo.getFeed(eventId, 1, 20)
            _uiState.value = if (result.isSuccess) {
                SocialFeedUiState.Success(result.getOrNull()!!)
            } else {
                SocialFeedUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
    }

    fun toggleLike(postId: Int) {
        viewModelScope.launch {
            socialRepo.toggleLike(postId)
            // optionally reload feed
        }
    }
}

sealed class SocialFeedUiState {
    object Loading : SocialFeedUiState()
    data class Success(val posts: List<SocialPost>) : SocialFeedUiState()
    data class Error(val message: String) : SocialFeedUiState()
}