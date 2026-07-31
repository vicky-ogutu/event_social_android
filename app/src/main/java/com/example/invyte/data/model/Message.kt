package com.example.invyte.data.model

data class Message(
    val id: Int,
    val sender_id: Int,
    val receiver_id: Int,
    val message: String,
    val is_read: Boolean,
    val read_at: String?,
    val created_at: String
)
