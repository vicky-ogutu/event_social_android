package com.example.invyte.data.model
import com.google.gson.annotations.SerializedName

data class VendorProfile(
    val id: Int,
    @SerializedName("user_id") val userId: Int,
    @SerializedName("business_name") val businessName: String,
    val address: String,
    val phone: String,
    val description: String?,
    @SerializedName("is_approved") val isApproved: Boolean = false,
    val rating: String?,
    @SerializedName("review_count") val reviewCount: Int?,
    @SerializedName("created_at") val createdAt: String?,
    @SerializedName("updated_at") val updatedAt: String?
)

// Request/Response wrappers
data class VendorProfileResponse(
    val success: Boolean,
    val message: String,
    val data: VendorProfile?
)

data class VendorProfileRequest(
    @SerializedName("business_name")
    val businessName: String,
    val address: String,
    val phone: String,
    val description: String?
)