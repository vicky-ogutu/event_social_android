package com.example.invyte.data.model

data class Vendor(
    val id: Int,
    val user_id: Int,
    val business_name: String,
    val business_address: String?,
    val business_phone: String?,
    val business_email: String?,
    val service_category: String?,
    val is_approved: Int,
    val total_earnings: Double,
    val completed_jobs: Int,
    val rating: Double,
    val review_count: Int,
    val full_name: String?,
    val profile_picture: String?,
    val services: List<Service>? = null,
    val portfolio: List<PortfolioItem>? = null
)


data class VendorListResponse(
    val data: List<Vendor>,
    val total: Int,
    val page: Int,
    val limit: Int,
    val pages: Int
)
