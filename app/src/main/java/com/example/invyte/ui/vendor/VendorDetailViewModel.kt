package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.Vendor
import com.example.invyte.data.repository.VendorRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import jakarta.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

@HiltViewModel
class VendorDetailViewModel @Inject constructor(
    private val vendorRepo: VendorRepository
) : ViewModel() {
    private val _uiState = MutableStateFlow<VendorDetailUiState>(VendorDetailUiState.Loading)
    val uiState: StateFlow<VendorDetailUiState> = _uiState.asStateFlow()

    fun loadVendorDetail(id: Int) {
        viewModelScope.launch {
            _uiState.value = VendorDetailUiState.Loading
            val result = vendorRepo.getVendorDetails(id)
            _uiState.value = (if (result.isSuccess) {
                VendorDetailUiState.Success(result.getOrNull()!!)}else{
                 VendorDetailUiState.Error(result.exceptionOrNull()?.message ?: "Error")}) as VendorDetailUiState
            }
        }
    }


sealed class VendorDetailUiState {
    object Loading : VendorDetailUiState()
    data class Success(val vendor: Vendor) : VendorDetailUiState()
    data class Error(val message: String) : VendorDetailUiState()
}