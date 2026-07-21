package com.example.invyte.data.model

import com.google.gson.annotations.SerializedName

data class PortfolioItem(
    val id: Int,
    @SerializedName("vendor_id") val vendorId: Int,
    @SerializedName("media_url") val mediaUrl: String,
    @SerializedName("media_type") val mediaType: String, // "image" or "video"

    val title: String?,
    val description: String?,
    val event_date: String?,
    val likes_count: Int,
    val is_cover: Boolean,
    val caption: String?,
    @SerializedName("created_at") val createdAt: String?


)

data class PortfolioResponse(
    val success: Boolean,
    val message: String,
    val data: List<PortfolioItem>
)



//data class PortfolioItem(
//    val id: Int,
//    val media_url: String,
//    val media_type: String,
//    val title: String?,
//    val description: String?,
//    val event_date: String?,
//    val likes_count: Int,
//    val is_cover: Boolean
//)