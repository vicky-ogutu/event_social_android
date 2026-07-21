package com.example.invyte.data.model

data class SocialPost(
    val id: Int,
    val event_id: Int,
    val user_id: Int,
    val content: String,
    val media_urls: List<String>,
    val media_type: String,
    val like_count: Int,
    val comment_count: Int,
    val share_count: Int,
    val is_pinned: Boolean,
    val created_at: String,
    val full_name: String,
    val profile_picture: String?,
    val is_liked: Boolean = false
)

data class CreatePostRequest(
    val event_id: Int,
    val content: String,
    val media_urls: List<String>? = null,
    val media_type: String = "image"
)

data class Comment(
    val id: Int,
    val post_id: Int,
    val user_id: Int,
    val content: String,
    val parent_comment_id: Int?,
    val created_at: String,
    val full_name: String,
    val profile_picture: String?
)

data class CreateCommentRequest(
    val post_id: Int,
    val content: String,
    val parent_comment_id: Int? = null
)