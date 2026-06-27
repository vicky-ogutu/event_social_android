package com.example.invyte.ui.vendor

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.*
import com.example.invyte.data.repository.VendorRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import okhttp3.MultipartBody
import javax.inject.Inject

@HiltViewModel
class VendorViewModel @Inject constructor(
    private val vendorRepository: VendorRepository
) : ViewModel() {

    // Vendor profile state
    private val _vendorProfileState = MutableStateFlow<VendorProfileUiState>(VendorProfileUiState.Idle)
    val vendorProfileState: StateFlow<VendorProfileUiState> = _vendorProfileState.asStateFlow()

    // Services list
    private val _servicesState = MutableStateFlow<ServicesUiState>(ServicesUiState.Idle)
    val servicesState: StateFlow<ServicesUiState> = _servicesState.asStateFlow()

    // Portfolio list
    private val _portfolioState = MutableStateFlow<PortfolioUiState>(PortfolioUiState.Idle)
    val portfolioState: StateFlow<PortfolioUiState> = _portfolioState.asStateFlow()

    // ----- Vendor Profile -----
    fun createVendorProfile(request: VendorProfileRequest) {
        viewModelScope.launch {
            _vendorProfileState.value = VendorProfileUiState.Loading
            try {
                val response = vendorRepository.createVendorProfile(request)
                if (response.success && response.data != null) {
                    _vendorProfileState.value = VendorProfileUiState.Success(response.data)
                } else {
                    _vendorProfileState.value = VendorProfileUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _vendorProfileState.value = VendorProfileUiState.Error(e.localizedMessage ?: "Create failed")
            }
        }
    }

    fun getVendorProfile() {
        viewModelScope.launch {
            _vendorProfileState.value = VendorProfileUiState.Loading
            try {
                val response = vendorRepository.getVendorProfile()
                if (response.success && response.data != null) {
                    _vendorProfileState.value = VendorProfileUiState.Success(response.data)
                } else {
                    _vendorProfileState.value = VendorProfileUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _vendorProfileState.value = VendorProfileUiState.Error(e.localizedMessage ?: "Fetch failed")
            }
        }
    }

    fun updateVendorProfile(request: VendorProfileRequest) {
        viewModelScope.launch {
            _vendorProfileState.value = VendorProfileUiState.Loading
            try {
                val response = vendorRepository.updateVendorProfile(request)
                if (response.success && response.data != null) {
                    _vendorProfileState.value = VendorProfileUiState.Success(response.data)
                } else {
                    _vendorProfileState.value = VendorProfileUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _vendorProfileState.value = VendorProfileUiState.Error(e.localizedMessage ?: "Update failed")
            }
        }
    }

    // ----- Services -----
    fun createService(request: ServiceRequest) {
        viewModelScope.launch {
            _servicesState.value = ServicesUiState.Loading
            try {
                val response = vendorRepository.createService(request)
                if (response.success && response.data != null) {
                    // Refresh list after creation
                    getServices()
                    _servicesState.value = ServicesUiState.Success("Service added")
                } else {
                    _servicesState.value = ServicesUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _servicesState.value = ServicesUiState.Error(e.localizedMessage ?: "Add failed")
            }
        }
    }

    fun getServices() {
        viewModelScope.launch {
            _servicesState.value = ServicesUiState.Loading
            try {
                val response = vendorRepository.getServices()
                if (response.success) {
                    _servicesState.value = ServicesUiState.ServicesLoaded(response.data)
                } else {
                    _servicesState.value = ServicesUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _servicesState.value = ServicesUiState.Error(e.localizedMessage ?: "Fetch failed")
            }
        }
    }

    fun updateService(serviceId: Int, request: ServiceRequest) {
        viewModelScope.launch {
            _servicesState.value = ServicesUiState.Loading
            try {
                val response = vendorRepository.updateService(serviceId, request)
                if (response.success && response.data != null) {
                    getServices()
                    _servicesState.value = ServicesUiState.Success("Service updated")
                } else {
                    _servicesState.value = ServicesUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _servicesState.value = ServicesUiState.Error(e.localizedMessage ?: "Update failed")
            }
        }
    }

    fun deleteService(serviceId: Int) {
        viewModelScope.launch {
            _servicesState.value = ServicesUiState.Loading
            try {
                val response = vendorRepository.deleteService(serviceId)
                if (response.success) {
                    getServices()
                    _servicesState.value = ServicesUiState.Success("Service deleted")
                } else {
                    _servicesState.value = ServicesUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _servicesState.value = ServicesUiState.Error(e.localizedMessage ?: "Delete failed")
            }
        }
    }

    // ----- Portfolio -----
    fun uploadPortfolio(filePart: MultipartBody.Part, caption: String?) {
        viewModelScope.launch {
            _portfolioState.value = PortfolioUiState.Loading
            try {
                val response = vendorRepository.uploadPortfolio(filePart, caption)
                if (response.success) {
                    getPortfolio()
                    _portfolioState.value = PortfolioUiState.Success("Portfolio item uploaded")
                } else {
                    _portfolioState.value = PortfolioUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _portfolioState.value = PortfolioUiState.Error(e.localizedMessage ?: "Upload failed")
            }
        }
    }

    fun getPortfolio() {
        viewModelScope.launch {
            _portfolioState.value = PortfolioUiState.Loading
            try {
                val response = vendorRepository.getPortfolio()
                if (response.success) {
                    _portfolioState.value = PortfolioUiState.PortfolioLoaded(response.data)
                } else {
                    _portfolioState.value = PortfolioUiState.Error(response.message)
                }
            } catch (e: Exception) {
                _portfolioState.value = PortfolioUiState.Error(e.localizedMessage ?: "Fetch failed")
            }
        }
    }

    // Reset states
    fun resetStates() {
        _vendorProfileState.value = VendorProfileUiState.Idle
        _servicesState.value = ServicesUiState.Idle
        _portfolioState.value = PortfolioUiState.Idle
    }
}

sealed class VendorProfileUiState {
    object Idle : VendorProfileUiState()
    object Loading : VendorProfileUiState()
    data class Success(val profile: VendorProfile) : VendorProfileUiState()
    data class Error(val message: String) : VendorProfileUiState()
}

sealed class ServicesUiState {
    object Idle : ServicesUiState()
    object Loading : ServicesUiState()
    data class ServicesLoaded(val services: List<Service>) : ServicesUiState()
    data class Success(val message: String) : ServicesUiState()
    data class Error(val message: String) : ServicesUiState()
}

sealed class PortfolioUiState {
    object Idle : PortfolioUiState()
    object Loading : PortfolioUiState()
    data class PortfolioLoaded(val items: List<PortfolioItem>) : PortfolioUiState()
    data class Success(val message: String) : PortfolioUiState()
    data class Error(val message: String) : PortfolioUiState()
}