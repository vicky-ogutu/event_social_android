package com.example.invyte.ui.vendor


import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.invyte.data.model.*
import com.example.invyte.data.repository.LivestreamRepository
import com.example.invyte.utils.SocketManager
import com.example.invyte.utils.TokenManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import org.webrtc.IceCandidate
import org.webrtc.VideoTrack
import org.webrtc.SurfaceViewRenderer
import javax.inject.Inject


@HiltViewModel
class LivestreamViewModel @Inject constructor(
    private val livestreamRepo: LivestreamRepository,
    private val socketManager: SocketManager,
    private val tokenManager: TokenManager
) : ViewModel() {

    private val _uiState = MutableStateFlow<LivestreamUiState>(LivestreamUiState.Idle)
    val uiState: StateFlow<LivestreamUiState> = _uiState.asStateFlow()

    private val _livestreamsState = MutableStateFlow<LivestreamListUiState>(LivestreamListUiState.Loading)
    val livestreamsState: StateFlow<LivestreamListUiState> = _livestreamsState.asStateFlow()

    private val _tokenState = MutableStateFlow<LivestreamTokenResponse?>(null)
    val tokenState: StateFlow<LivestreamTokenResponse?> = _tokenState.asStateFlow()

    private val _signalingMessages = MutableSharedFlow<SignalingMessage>()
    val signalingMessages: SharedFlow<SignalingMessage> = _signalingMessages.asSharedFlow()

    private var currentRoomId: Int? = null
    private var isBroadcaster = false

    init {
        viewModelScope.launch {
            socketManager.livestreamEvents.collect { event ->
                when (event.type) {
                    "offer" -> {
                        val sdp = event.data["sdp"] as? String ?: return@collect
                        _signalingMessages.emit(SignalingMessage("offer", sdp = sdp))
                    }
                    "answer" -> {
                        val sdp = event.data["sdp"] as? String ?: return@collect
                        _signalingMessages.emit(SignalingMessage("answer", sdp = sdp))
                    }
                    "ice-candidate" -> {
                        val candidate = event.data["candidate"] as? String ?: return@collect
                        val sdpMid = event.data["sdpMid"] as? String ?: return@collect
                        val sdpMLineIndex = (event.data["sdpMLineIndex"] as? Number)?.toInt() ?: return@collect
                        _signalingMessages.emit(
                            SignalingMessage(
                                type = "ice-candidate",
                                candidate = candidate,
                                sdpMid = sdpMid,
                                sdpMLineIndex = sdpMLineIndex
                            )
                        )
                    }
                    "broadcaster-left" -> {
                        _uiState.value = LivestreamUiState.Error("Broadcaster left the stream")
                    }
                    "stream-available" -> {
                        if (!isBroadcaster && currentRoomId != null) {
                            socketManager.emit("consume", mapOf("roomId" to currentRoomId!!))
                        }
                    }
                    "transport-created" -> {
                        @Suppress("UNCHECKED_CAST")
                        val data = event.data as Map<String, Any>
                        _uiState.value = LivestreamUiState.TransportReady(data)
                    }
                    else -> Unit
                }
            }
        }
    }

    // ----- Create livestream -----
    fun createLivestream(request: CreateLivestreamRequest) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.createLivestream(request)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.LivestreamLoaded(result.getOrNull()!!)
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Failed to create livestream")
            }
        }
    }

    // ----- Start livestream -----
    fun startLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.startLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.ActionSuccess("Livestream started")
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Failed to start livestream")
            }
        }
    }

    // ----- End livestream -----
    fun endLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.endLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.ActionSuccess("Livestream ended")
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Failed to end livestream")
            }
        }
    }

    // ----- Purchase livestream (PPV) -----
    fun purchaseLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.purchaseLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.PaymentIntent(result.getOrNull()!!)
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Failed to initiate purchase")
            }
        }
    }

    // ----- Confirm purchase after Stripe success -----
    fun confirmPurchase(livestreamId: Int, paymentIntentId: String) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.confirmPurchase(livestreamId, paymentIntentId)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.ActionSuccess("Purchase confirmed")
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Purchase confirmation failed")
            }
        }
    }

    // ----- Load livestreams list -----
    fun loadLivestreams(status: String? = "live") {
        viewModelScope.launch {
            _livestreamsState.value = LivestreamListUiState.Loading
            val result = livestreamRepo.listLivestreams(null, status)
            _livestreamsState.value = if (result.isSuccess) {
                LivestreamListUiState.Success(result.getOrNull()!!)
            } else {
                LivestreamListUiState.Error(result.exceptionOrNull()?.message ?: "Error loading livestreams")
            }
        }
    }

    // ----- Load token -----
    fun loadToken(id: Int) {
        viewModelScope.launch {
            val result = livestreamRepo.getLivestreamToken(id)
            if (result.isSuccess) {
                _tokenState.value = result.getOrNull()
            }
        }
    }

    // ----- Load single livestream -----
    fun loadLivestream(id: Int) {
        viewModelScope.launch {
            _uiState.value = LivestreamUiState.Loading
            val result = livestreamRepo.getLivestream(id)
            _uiState.value = if (result.isSuccess) {
                LivestreamUiState.LivestreamLoaded(result.getOrNull()!!)
            } else {
                LivestreamUiState.Error(result.exceptionOrNull()?.message ?: "Failed to load livestream")
            }
        }
    }

    // ----- Get current user ID -----
    suspend fun getCurrentUserId(): Int = tokenManager.getUserIdSync() ?: 0

    // ----- Broadcast / Join (WebRTC signaling) -----
    fun startBroadcast(roomId: Int) {
        currentRoomId = roomId
        isBroadcaster = true
        socketManager.emit("create-livestream-room", mapOf("roomId" to roomId))
    }

    fun joinBroadcast(roomId: Int) {
        currentRoomId = roomId
        isBroadcaster = false
        socketManager.emit("join-livestream", mapOf("roomId" to roomId))
    }

    fun sendOffer(roomId: Int, sdp: String) {
        socketManager.emit("offer", mapOf("roomId" to roomId, "sdp" to sdp))
    }

    fun sendAnswer(roomId: Int, sdp: String) {
        socketManager.emit("answer", mapOf("roomId" to roomId, "sdp" to sdp))
    }

    fun sendIceCandidate(roomId: Int, candidate: IceCandidate) {
        socketManager.emit(
            "ice-candidate",
            mapOf(
                "roomId" to roomId,
                "candidate" to candidate.sdp,
                "sdpMid" to candidate.sdpMid,
                "sdpMLineIndex" to candidate.sdpMLineIndex
            )
        )
    }

    fun attachRemoteVideo(renderer: SurfaceViewRenderer, track: VideoTrack) {
        renderer.init(org.webrtc.EglBase.create().eglBaseContext, null)
        renderer.setEnableHardwareScaler(true)
        track.addSink(renderer)
    }

    fun publishStream(roomId: Int, kind: String, rtpParameters: Map<String, Any>) {
        socketManager.emit("publish", mapOf("roomId" to roomId, "kind" to kind, "rtpParameters" to rtpParameters))
        socketManager.emit("publish", mapOf("roomId" to roomId, "sdp" to sdp))
    }

    fun consumeStream(roomId: Int, rtpCapabilities: Map<String, Any>) {
        socketManager.emit("consume", mapOf("roomId" to roomId, "rtpCapabilities" to rtpCapabilities))
    }

    fun leaveLivestream() {
        currentRoomId?.let {
            socketManager.emit("livestream-disconnect", mapOf("roomId" to it))
        }
        currentRoomId = null
    }

    // ----- Reset UI state -----
    fun resetState() {
        _uiState.value = LivestreamUiState.Idle
    }
}

// ----- UI State sealed classes -----
sealed class LivestreamUiState {
    object Idle : LivestreamUiState()
    object Loading : LivestreamUiState()
    data class LivestreamLoaded(val livestream: Livestream) : LivestreamUiState()
    data class PaymentIntent(val data: PaymentIntentResponse) : LivestreamUiState()
    data class ActionSuccess(val message: String = "Operation successful") : LivestreamUiState()
    data class Error(val message: String) : LivestreamUiState()
    data class TransportReady(val data: Map<String, Any>) : LivestreamUiState()
}

sealed class LivestreamListUiState {
    object Loading : LivestreamListUiState()
    data class Success(val data: LivestreamListResponse) : LivestreamListUiState()
    data class Error(val message: String) : LivestreamListUiState()
}

// ----- Signaling message -----
data class SignalingMessage(
    val type: String, // "offer", "answer", "ice-candidate"
    val sdp: String? = null,
    val candidate: String? = null,
    val sdpMid: String? = null,
    val sdpMLineIndex: Int? = null
)
