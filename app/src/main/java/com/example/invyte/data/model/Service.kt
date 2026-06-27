package com.example.invyte.data.model

import com.google.gson.annotations.SerializedName

data class Service(
    val id: Int,
    @SerializedName("vendor_id") val vendorId: Int,
    val category: String,
    val price: Double,
    val description: String?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("updated_at") val updatedAt: String?
)

data class ServiceRequest(
    val category: String,
    val price: Double,
    val description: String?
)

data class ServiceResponse(
    val success: Boolean,
    val message: String,
    val data: Service?
)

data class ServicesResponse(
    val success: Boolean,
    val message: String,
    val data: List<Service>
)