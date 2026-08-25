package com.example.invyte.ui.consumer



import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.ServiceCategory
import com.example.invyte.data.model.VendorListResponse
import com.example.invyte.data.repository.VendorRepository

import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class VendorListViewModel @Inject constructor(
    private val vendorRepo: VendorRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow<VendorListUiState>(VendorListUiState.Loading)
    val uiState: StateFlow<VendorListUiState> = _uiState.asStateFlow()

    // 👇 categories state
    private val _categoriesState = MutableStateFlow<CategoriesUiState>(CategoriesUiState.Loading)
    val categoriesState: StateFlow<CategoriesUiState> = _categoriesState.asStateFlow()

    init {
        loadCategories()
        loadVendors()
    }

    fun loadCategories() {
        viewModelScope.launch {
            _categoriesState.value = CategoriesUiState.Loading
            val result = vendorRepo.getCategories()
            _categoriesState.value = if (result.isSuccess) {
                CategoriesUiState.Success(result.getOrNull() ?: emptyList())
            } else {
                CategoriesUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load categories")
            }
        }
    }

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

sealed class VendorListUiState {
    object Loading : VendorListUiState()
    data class Success(val data: VendorListResponse) : VendorListUiState()
    data class Error(val message: String) : VendorListUiState()
}

sealed class CategoriesUiState {
    object Loading : CategoriesUiState()
    data class Success(val categories: List<ServiceCategory>) : CategoriesUiState()
    data class Error(val message: String) : CategoriesUiState()
}

