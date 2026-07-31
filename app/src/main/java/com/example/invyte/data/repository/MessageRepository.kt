package com.example.invyte.data.repository

import com.example.invyte.data.model.Conversation
import com.example.invyte.data.model.Message
import com.example.invyte.data.network.ApiService
import com.example.invyte.ui.vendor.SocketManager
import com.example.invyte.utils.safeApiCall
import jakarta.inject.Inject
import jakarta.inject.Singleton

@Singleton
class MessageRepository @Inject constructor(
    private val api: ApiService,
    private val socketManager: SocketManager
) {
    suspend fun sendMessage(receiverId: Int, message: String): Result<Message> =
        safeApiCall { api.sendMessage(ApiService.SendMessageRequest(receiverId, message)) }

    suspend fun getConversations(): Result<List<Conversation>> =
        safeApiCall { api.getConversations() }

    suspend fun getConversation(userId: Int, limit: Int = 50, offset: Int = 0): Result<List<Message>> =
        safeApiCall { api.getConversation(userId, limit, offset) }
}