package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.CreateLivestreamRequest
import com.example.invyte.data.model.Livestream
import com.example.invyte.data.model.PaymentIntentResponse
import com.example.invyte.data.repository.LivestreamRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import jakarta.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class LivestreamViewModel @Inject constructor(
    private val livestreamRepo: LivestreamRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<LivestreamUiState>(LivestreamUiState.Idle)
    val uiState: StateFlow<LivestreamUiState> = _uiState.asStateFlow()

    fun createLivestream(request: CreateLivestreamRequest) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.createLivestream(request)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.LivestreamLoaded(result.getOrNull()!!)
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
    }

    fun purchaseLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.purchaseLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.PaymentIntent(result.getOrNull()!!)
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
    }

    fun startLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.startLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.ActionSuccess("Livestream started")
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
    }

    fun endLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.endLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.ActionSuccess("Livestream ended")
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Error")
            }
        }
    }
}

sealed class LivestreamUiState {
    object Idle : LivestreamUiState()
    object Loading : LivestreamUiState()
    data class LivestreamLoaded(val livestream: Livestream) : LivestreamUiState()
    data class PaymentIntent(val data: PaymentIntentResponse) : LivestreamUiState()
    data class ActionSuccess(val message: String = "Operation successful") : LivestreamUiState()
    data class Error(val message: String) : LivestreamUiState()
}