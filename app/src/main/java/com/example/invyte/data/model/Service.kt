package com.example.invyte.data.model

import com.google.gson.annotations.SerializedName

data class Service(
    val id: Int,
    @SerializedName("vendor_id") val vendorId: Int,
    @SerializedName("category_id") val categoryId: Int,
    @SerializedName("service_name") val serviceName: String,
    val description: String?,
    @SerializedName("base_price") val basePrice: Double,
    @SerializedName("price_unit") val priceUnit: String? = null,
    @SerializedName("min_duration_hours") val minDurationHours: Int? = null,
    @SerializedName("max_capacity") val maxCapacity: Int? = null,
    @SerializedName("is_custom_price") val isCustomPrice: Int? = null,
    @SerializedName("is_active") val isActive: Int? = null,
    @SerializedName("featured_until") val featuredUntil: String? = null,
    @SerializedName("created_at") val createdAt: String? = null,
    @SerializedName("updated_at") val updatedAt: String? = null,
    @SerializedName("category_name") val categoryName: String? = null,
    val slug: String? = null
)




data class ServiceRequest(
    @SerializedName("category_id") val categoryId: Int,
    @SerializedName("service_name") val serviceName: String,
    val description: String? = null,
    @SerializedName("base_price") val basePrice: Double
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