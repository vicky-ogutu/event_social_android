package com.example.invyte.ui.auth


import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.LoginRequest
import com.example.invyte.data.model.RegisterRequest
import com.example.invyte.data.repository.AuthRepository
import com.example.invyte.utils.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class AuthUiState {
    object Idle : AuthUiState()
    object Loading : AuthUiState()
    data class Success(val dashboard: String, val userType: String) : AuthUiState()
    data class Error(val message: String) : AuthUiState()
    object RegisterSuccess : AuthUiState()
}

@HiltViewModel
class AuthViewModel @Inject constructor(
     val repository: AuthRepository,
     val tokenManager: TokenManager

) : ViewModel() {

    private val _uiState = MutableStateFlow<AuthUiState>(AuthUiState.Idle)
    val uiState: StateFlow<AuthUiState> = _uiState.asStateFlow()

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            try {
                val response = repository.login(LoginRequest(email, password))
                if (response.success && response.data != null) {
                    val token = response.data.token ?: throw Exception("Token missing")
                    val user = response.data.user ?: throw Exception("User data missing")
                    repository.saveAuthData(
                        token, user.userType,
                        user = user
                    )
                    _uiState.value = AuthUiState.Success(
                        dashboard = response.data.dashboard ?: "${user.userType}_home",
                        userType = user.userType
                    )
                } else {
                    _uiState.value = AuthUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _uiState.value = AuthUiState.Error(e.localizedMessage ?: "Login failed")
            }
        }
    }

    fun register(fullName: String, email: String, password: String, userType: String) {
        viewModelScope.launch {
            _uiState.value = AuthUiState.Loading
            try {
                val response = repository.register(RegisterRequest(email, password, fullName, userType))
                if (response.success) {
                    _uiState.value = AuthUiState.RegisterSuccess
                } else {
                    _uiState.value = AuthUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _uiState.value = AuthUiState.Error(e.localizedMessage ?: "Registration failed")
            }
        }
    }
    suspend fun logout() {
        tokenManager.clear()
        // optionally clear any user data stored in repository
    }
    fun resetState() {
        _uiState.value = AuthUiState.Idle
    }

    suspend fun clearSession() {
        repository.clear()
    }
}