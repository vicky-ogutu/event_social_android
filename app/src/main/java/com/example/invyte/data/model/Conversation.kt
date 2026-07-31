package com.example.invyte.data.model

data class Conversation(
    val user_id: Int,
    val full_name: String,
    val profile_picture: String?,
    val user_type: String,
    val last_message: String?,
    val last_message_time: String?,
    val unread_count: Int
)