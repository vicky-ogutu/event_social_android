package com.example.invyte.data.model

data class SendChatMessageRequest(
    val event_id: Int,
    val message: String,
    val message_type: String = "text",
    val media_url: String? = null
)