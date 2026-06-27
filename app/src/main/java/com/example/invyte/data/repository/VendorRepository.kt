package com.example.invyte.data.repository


import com.example.invyte.data.model.*
import com.example.invyte.data.network.ApiService
import okhttp3.MultipartBody
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class VendorRepository @Inject constructor(
    private val api: ApiService
) {

    suspend fun createVendorProfile(request: VendorProfileRequest): VendorProfileResponse {
        val response = api.createVendorProfile(request)
        return if (response.isSuccessful) {
            response.body() ?: VendorProfileResponse(false, "Unknown error", null)
        } else {
            VendorProfileResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun getVendorProfile(): VendorProfileResponse {
        val response = api.getVendorProfile()
        return if (response.isSuccessful) {
            response.body() ?: VendorProfileResponse(false, "Unknown error", null)
        } else {
            VendorProfileResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun updateVendorProfile(request: VendorProfileRequest): VendorProfileResponse {
        val response = api.updateVendorProfile(request)
        return if (response.isSuccessful) {
            response.body() ?: VendorProfileResponse(false, "Unknown error", null)
        } else {
            VendorProfileResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun createService(request: ServiceRequest): ServiceResponse {
        val response = api.createService(request)
        return if (response.isSuccessful) {
            response.body() ?: ServiceResponse(false, "Unknown error", null)
        } else {
            ServiceResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun getServices(): ServicesResponse {
        val response = api.getServices()
        return if (response.isSuccessful) {
            response.body() ?: ServicesResponse(false, "Unknown error", emptyList())
        } else {
            ServicesResponse(false, "Server error: ${response.code()}", emptyList())
        }
    }

    suspend fun updateService(serviceId: Int, request: ServiceRequest): ServiceResponse {
        val response = api.updateService(serviceId, request)
        return if (response.isSuccessful) {
            response.body() ?: ServiceResponse(false, "Unknown error", null)
        } else {
            ServiceResponse(false, "Server error: ${response.code()}", null)
        }
    }

    suspend fun deleteService(serviceId: Int): GenericResponse {
        val response = api.deleteService(serviceId)
        return if (response.isSuccessful) {
            response.body() ?: GenericResponse(false, "Unknown error")
        } else {
            GenericResponse(false, "Server error: ${response.code()}")
        }
    }

    suspend fun uploadPortfolio(filePart: MultipartBody.Part, caption: String?): PortfolioResponse {
        val response = api.uploadPortfolio(filePart, caption)
        return if (response.isSuccessful) {
            response.body() ?: PortfolioResponse(false, "Unknown error", emptyList())
        } else {
            PortfolioResponse(false, "Server error: ${response.code()}", emptyList())
        }
    }

    suspend fun getPortfolio(): PortfolioResponse {
        val response = api.getPortfolio()
        return if (response.isSuccessful) {
            response.body() ?: PortfolioResponse(false, "Unknown error", emptyList())
        } else {
            PortfolioResponse(false, "Server error: ${response.code()}", emptyList())
        }
    }
}