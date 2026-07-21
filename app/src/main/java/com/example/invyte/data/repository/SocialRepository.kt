package com.example.invyte.data.repository

import com.example.invyte.data.model.ChatMessage
import com.example.invyte.data.model.Comment
import com.example.invyte.data.model.CreateCommentRequest
import com.example.invyte.data.model.CreatePostRequest
import com.example.invyte.data.model.SendChatMessageRequest
import com.example.invyte.data.model.SocialPost
import com.example.invyte.data.network.ApiService
import com.example.invyte.utils.safeApiCall
import jakarta.inject.Inject
import jakarta.inject.Singleton

@Singleton
class SocialRepository @Inject constructor(
    private val api: ApiService
) {
    suspend fun createPost(request: CreatePostRequest): Result<SocialPost> =
        safeApiCall { api.createPost(request) }

    suspend fun getFeed(eventId: Int?, page: Int, limit: Int): Result<List<SocialPost>> =
        safeApiCall { api.getSocialFeed(eventId, page, limit) }

    suspend fun toggleLike(postId: Int): Result<Unit> =
        safeApiCall { api.togglePostLike(postId) }

    suspend fun addComment(postId: Int, request: CreateCommentRequest): Result<Comment> =
        safeApiCall { api.addComment(postId, request) }

    suspend fun getComments(postId: Int): Result<List<Comment>> =
        safeApiCall { api.getPostComments(postId) }

    suspend fun getChatMessages(eventId: Int, page: Int, limit: Int): Result<List<ChatMessage>> =
        safeApiCall { api.getChatMessages(eventId, page, limit) }

    suspend fun sendChatMessage(request: SendChatMessageRequest): Result<ChatMessage> =
        safeApiCall { api.sendChatMessage(request) }
}