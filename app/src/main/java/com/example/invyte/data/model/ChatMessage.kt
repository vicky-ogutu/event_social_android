package com.example.invyte.data.model


data class ChatMessage(
    val id: Int,
    val event_id: Int,
    val user_id: Int,
    val message: String,
    val message_type: String,          // "text", "image", "video", "gif"
    val media_url: String?,
    val is_read: Boolean,
    val created_at: String,
    val full_name: String,
    val profile_picture: String?
)