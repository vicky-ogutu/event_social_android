package com.example.invyte.ui.vendor



import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.VendorListResponse
import com.example.invyte.data.repository.VendorRepository

import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

sealed class VendorListUiState {
    object Loading : VendorListUiState()
    data class Success(val data: VendorListResponse) : VendorListUiState()
    data class Error(val message: String) : VendorListUiState()
}

@HiltViewModel
class VendorListViewModel @Inject constructor(
    private val vendorRepo: VendorRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<VendorListUiState>(VendorListUiState.Loading)
    val uiState: StateFlow<VendorListUiState> = _uiState.asStateFlow()

    fun loadVendors(category: String? = null, minRating: Double? = null, search: String? = null) {
        viewModelScope.launch {
            _uiState.value = VendorListUiState.Loading
            val result = vendorRepo.listVendors(category, minRating, search, 1, 20)
            _uiState.value = if (result.isSuccess) {
                VendorListUiState.Success(result.getOrNull()!!)
            } else {
                VendorListUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load vendors")
            }
        }
    }
}

