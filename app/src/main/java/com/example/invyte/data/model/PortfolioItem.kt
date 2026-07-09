package com.example.invyte.data.model

import com.google.gson.annotations.SerializedName

data class PortfolioItem(
    val id: Int,
    @SerializedName("vendor_id") val vendorId: Int,
    @SerializedName("media_url") val mediaUrl: String,
    @SerializedName("media_type") val mediaType: String, // "image" or "video"
    val caption: String?,
    @SerializedName("created_at") val createdAt: String?
)

data class PortfolioResponse(
    val success: Boolean,
    val message: String,
    val data: List<PortfolioItem>
)