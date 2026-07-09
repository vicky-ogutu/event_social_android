package com.example.invyte.data.model

import com.google.gson.annotations.SerializedName

data class User(
    val id: Int,
    val uuid: String,
    val email: String,
    val phone: String?,
    @SerializedName("full_name")
    val fullName: String,
    @SerializedName("profile_picture")
    val profilePicture: String?,
    val bio: String?,
    @SerializedName("user_type")
    val userType: String, // "vendor" or "consumer"
    @SerializedName("is_verified")
    val isVerified: Int,
    val rating: String,
    @SerializedName("review_count")
    val reviewCount: Int,
    @SerializedName("wallet_balance")
    val walletBalance: String,
    @SerializedName("total_spent")
    val totalSpent: String,

    val vendor: VendorInfo? = null
)

data class VendorInfo(
    @SerializedName("business_name") val businessName: String?,
    @SerializedName("is_approved") val isApproved: Int?,
    @SerializedName("stripe_onboarding_complete") val stripeOnboardingComplete: Int?,
    @SerializedName("total_earnings") val totalEarnings: String?,
    @SerializedName("completed_jobs") val completedJobs: Int?
)