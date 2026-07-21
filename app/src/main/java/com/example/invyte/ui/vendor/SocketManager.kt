package com.example.invyte.ui.vendor

import com.example.invyte.Constants
import com.example.invyte.data.model.ChatMessage
import com.example.invyte.utils.TokenManager

import io.socket.client.IO
import io.socket.client.Socket
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SocketManager @Inject constructor(
    private val tokenManager: TokenManager
) {
    private var socket: Socket? = null
    private val _newMessage = MutableSharedFlow<ChatMessage>()
    val newMessage: SharedFlow<ChatMessage> = _newMessage

    suspend fun connect() {
        if (socket?.connected() == true) return

        val token = tokenManager.getTokenSync()
        val opts = IO.Options().apply {
            if (!token.isNullOrEmpty()) {
                auth = mapOf("token" to token)
            }
            reconnection = true
            reconnectionAttempts = 5
            reconnectionDelay = 1000
        }

        socket = IO.socket(Constants.BASE_URL_SOCKET, opts)
        socket?.apply {
            on(Socket.EVENT_CONNECT) { println("Socket connected") }
            on(Socket.EVENT_DISCONNECT) { println("Socket disconnected") }
            on(Socket.EVENT_CONNECT_ERROR) { args ->
                println("Socket error: ${args.joinToString()}")
            }
            on("new-message") { args ->
                try {
                    val data = args[0] as Map<*, *>
                    val message = ChatMessage(
                        id = (data["id"] as? Number)?.toInt() ?: 0,
                        event_id = (data["event_id"] as? Number)?.toInt() ?: 0,
                        user_id = (data["user_id"] as? Number)?.toInt() ?: 0,
                        message = data["message"] as? String ?: "",
                        message_type = data["message_type"] as? String ?: "text",
                        media_url = data["media_url"] as? String,
                        is_read = data["is_read"] as? Boolean ?: false,
                        created_at = data["created_at"] as? String ?: "",
                        full_name = data["full_name"] as? String ?: "Unknown",
                        profile_picture = data["profile_picture"] as? String
                    )
                    CoroutineScope(Dispatchers.IO).launch {
                        _newMessage.emit(message)
                    }
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
            connect()
        }
    }

    fun joinEvent(eventId: Int) {
        socket?.emit("join-event", eventId)
    }

    fun leaveEvent(eventId: Int) {
        socket?.emit("leave-event", eventId)
    }

    fun sendMessage(eventId: Int, message: String, userId: Int) {
        val data = mapOf(
            "eventId" to eventId,
            "message" to message,
            "userId" to userId,
            "messageType" to "text"
        )
        socket?.emit("send-message", data)
    }

    fun disconnect() {
        socket?.disconnect()
        socket = null
    }

    fun isConnected(): Boolean = socket?.connected() == true
}