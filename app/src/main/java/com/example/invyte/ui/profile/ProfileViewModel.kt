package com.example.invyte.ui.profile

import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.AuthResponse
import com.example.invyte.data.model.User
import com.example.invyte.data.repository.AuthRepository
import com.example.invyte.data.repository.ProfileRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import okhttp3.MultipartBody
import javax.inject.Inject

/**
 * ViewModel for managing user profile operations.
 * Handles profile updates, password changes, and avatar uploads.
 */
@HiltViewModel
class ProfileViewModel @Inject constructor(
    private val profileRepository: ProfileRepository,
    private val authRepository: AuthRepository
) : ViewModel() {

    // UI state for feedback (loading, success, error)
    private val _uiState = MutableStateFlow<ProfileUiState>(ProfileUiState.Idle)
    val uiState: StateFlow<ProfileUiState> = _uiState.asStateFlow()

    // Current logged-in user data
    private val _currentUser = MutableStateFlow<User?>(null)
    val currentUser: StateFlow<User?> = _currentUser.asStateFlow()

    init {
        // Load the current user from the repository (DataStore)
        viewModelScope.launch {
            authRepository.getUser().collect { user ->
                _currentUser.value = user
            }
        }
    }

    /**
     * Update the user's profile (full name and bio).
     * On success, updates the stored user data.
     */
    fun updateProfile(fullName: String, bio: String?) {
        viewModelScope.launch {
            _uiState.value = ProfileUiState.Loading
            try {
                val response = profileRepository.updateProfile(fullName, bio)
                if (response.success && response.data?.user != null) {
                    val updatedUser = response.data.user
                    // Persist the updated user in DataStore
                    authRepository.saveUser(updatedUser)
                    _currentUser.value = updatedUser
                    _uiState.value = ProfileUiState.Success("Profile updated successfully")
                } else {
                    _uiState.value = ProfileUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _uiState.value = ProfileUiState.Error(e.localizedMessage ?: "Update failed")
            }
        }
    }

    /**
     * Change the user's password.
     * Requires old and new passwords.
     */
    fun changePassword(oldPassword: String, newPassword: String) {
        viewModelScope.launch {
            _uiState.value = ProfileUiState.Loading
            try {
                val response = profileRepository.changePassword(oldPassword, newPassword)
                if (response.success) {
                    _uiState.value = ProfileUiState.Success("Password changed successfully")
                } else {
                    _uiState.value = ProfileUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _uiState.value = ProfileUiState.Error(e.localizedMessage ?: "Change password failed")
            }
        }
    }

    /**
     * Upload a new avatar image.
     * On success, updates the stored user data with the new profile picture URL.
     */
    fun uploadAvatar(filePart: MultipartBody.Part) {
        viewModelScope.launch {
            _uiState.value = ProfileUiState.Loading
            try {
                val response = profileRepository.uploadAvatar(filePart)
                if (response.success && response.data?.user != null) {
                    val updatedUser = response.data.user
                    authRepository.saveUser(updatedUser)
                    _currentUser.value = updatedUser
                    _uiState.value = ProfileUiState.Success("Avatar uploaded successfully")
                } else {
                    _uiState.value = ProfileUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _uiState.value = ProfileUiState.Error(e.localizedMessage ?: "Upload failed")
            }
        }
    }

    /**
     * Reset the UI state to Idle (dismisses success/error messages).
     */
    fun resetState() {
        _uiState.value = ProfileUiState.Idle
    }
}

/**
 * Sealed class representing the UI state for profile operations.
 */
sealed class ProfileUiState {
    object Idle : ProfileUiState()
    object Loading : ProfileUiState()
    data class Success(val message: String) : ProfileUiState()
    data class Error(val message: String) : ProfileUiState()
}