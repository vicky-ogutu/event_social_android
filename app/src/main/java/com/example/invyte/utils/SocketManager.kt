package com.example.invyte.utils

import com.example.invyte.Constants
import com.example.invyte.data.model.ChatMessage
import com.example.invyte.data.model.Message

import io.socket.client.IO
import io.socket.client.Socket
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.launch
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.collections.get


@Singleton
class SocketManager @Inject constructor(
    private val tokenManager: TokenManager
) {
    private var socket: Socket? = null

    // Event chat messages
    private val _newMessage = MutableSharedFlow<ChatMessage>()
    val newMessage: SharedFlow<ChatMessage> = _newMessage

    // Private messages (consumer <-> vendor)
    private val _newPrivateMessage = MutableSharedFlow<Message>()
    val newPrivateMessage: SharedFlow<Message> = _newPrivateMessage

    // Livestream signaling events
    private val _livestreamEvents = MutableSharedFlow<LivestreamEvent>()
    val livestreamEvents: SharedFlow<LivestreamEvent> = _livestreamEvents.asSharedFlow()

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
            on(Socket.EVENT_CONNECT_ERROR) { args -> println("Socket error: ${args.joinToString()}") }

            // ---- Event chat ----
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
                    CoroutineScope(Dispatchers.IO).launch { _newMessage.emit(message) }
                } catch (e: Exception) { e.printStackTrace() }
            }

            // ---- Private messages ----
            on("new-private-message") { args ->
                try {
                    val data = args[0] as Map<*, *>
                    val msg = Message(
                        id = (data["id"] as? Number)?.toInt() ?: 0,
                        sender_id = (data["sender_id"] as? Number)?.toInt() ?: 0,
                        receiver_id = (data["receiver_id"] as? Number)?.toInt() ?: 0,
                        message = data["message"] as? String ?: "",
                        is_read = data["is_read"] as? Boolean ?: false,
                        read_at = data["read_at"] as? String,
                        created_at = data["created_at"] as? String ?: ""
                    )
                    CoroutineScope(Dispatchers.IO).launch { _newPrivateMessage.emit(msg) }
                } catch (e: Exception) { e.printStackTrace() }
            }

            // ---- Livestream signaling ----
            on("transport-created") { args ->
                val data = args[0] as Map<*, *>
                CoroutineScope(Dispatchers.IO).launch {
                    _livestreamEvents.emit(LivestreamEvent("transport-created", data))
                }
            }
            on("offer") { args ->
                val data = args[0] as Map<*, *>
                CoroutineScope(Dispatchers.IO).launch {
                    _livestreamEvents.emit(LivestreamEvent("offer", data))
                }
            }
            on("answer") { args ->
                val data = args[0] as Map<*, *>
                CoroutineScope(Dispatchers.IO).launch {
                    _livestreamEvents.emit(LivestreamEvent("answer", data))
                }
            }
            on("ice-candidate") { args ->
                val data = args[0] as Map<*, *>
                CoroutineScope(Dispatchers.IO).launch {
                    _livestreamEvents.emit(LivestreamEvent("ice-candidate", data))
                }
            }
            on("stream-available") { args ->
                val data = args[0] as Map<*, *>
                CoroutineScope(Dispatchers.IO).launch {
                    _livestreamEvents.emit(LivestreamEvent("stream-available", data))
                }
            }
            on("broadcaster-left") { args ->
                val data = args[0] as Map<*, *>
                CoroutineScope(Dispatchers.IO).launch {
                    _livestreamEvents.emit(LivestreamEvent("broadcaster-left", data))
                }
            }

            connect()
        }
    }

    // ---- Utility emit method ----
    fun emit(event: String, data: Any?) {
        socket?.emit(event, data)
    }

    // ---- Event joining / leaving ----
    fun joinEvent(eventId: Int) { socket?.emit("join-event", eventId) }
    fun leaveEvent(eventId: Int) { socket?.emit("leave-event", eventId) }
    fun joinPrivate(userId: Int) { socket?.emit("join-private", userId) }

    // ---- Sending messages ----
    fun sendMessage(eventId: Int, message: String, messageType: String = "text", mediaUrl: String? = null) {
        val data = mapOf(
            "eventId" to eventId,
            "message" to message,
            "messageType" to messageType,
            "mediaUrl" to mediaUrl
        )
        socket?.emit("send-message", data)
    }

    fun sendPrivateMessage(receiverId: Int, message: String) {
        socket?.emit("private-message", mapOf("receiverId" to receiverId, "message" to message))
    }

    fun disconnect() { socket?.disconnect(); socket = null }
    fun isConnected(): Boolean = socket?.connected() == true
}

data class LivestreamEvent(val type: String, val data: Map<*, *>)