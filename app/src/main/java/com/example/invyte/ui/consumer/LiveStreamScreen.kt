package com.example.invyte.ui.consumer

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.vendor.LivestreamUiState
import com.example.invyte.ui.vendor.LivestreamViewModel
import com.example.invyte.utils.WebRTCManager
import org.webrtc.IceCandidate
import org.webrtc.SessionDescription
import org.webrtc.SurfaceViewRenderer
import org.webrtc.VideoTrack

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LivestreamScreen(
    navController: NavController,
    livestreamId: Int,
    viewModel: LivestreamViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    var surfaceViewRenderer by remember { mutableStateOf<SurfaceViewRenderer?>(null) }
    var isBroadcasting by remember { mutableStateOf(false) }
    var isStreamActive by remember { mutableStateOf(false) }

    // Permission launcher
    val permissionLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.RequestMultiplePermissions()
    ) { permissions ->
        if (!permissions.values.all { it }) {
            // Show permission required message
        }
    }

    // WebRTC Manager
    val webRTCManager = remember {
        WebRTCManager(context).apply {
            init(object : WebRTCManager.WebRTCEventListener {
                override fun onIceCandidate(candidate: IceCandidate, role: String) {
                    viewModel.sendIceCandidate(livestreamId, candidate)
                }
                override fun onOfferCreated(offer: SessionDescription) {
                    viewModel.sendOffer(livestreamId, offer.description)
                    viewModel.publishStream(livestreamId, offer.description)
                }
                override fun onAnswerCreated(answer: SessionDescription) {
                    viewModel.sendAnswer(livestreamId, answer.description)
                }
                override fun onRemoteVideoTrack(track: VideoTrack) {
                    surfaceViewRenderer?.let {
                        viewModel.attachRemoteVideo(it, track)
                    }
                }
            })
        }
    }

    // Load livestream details
    LaunchedEffect(Unit) {
        permissionLauncher.launch(
            arrayOf(
                Manifest.permission.CAMERA,
                Manifest.permission.RECORD_AUDIO
            )
        )
        viewModel.loadLivestream(livestreamId)
    }

    // Determine role and start/join when livestream loaded
    LaunchedEffect(uiState) {
        val state = uiState
        if (state is LivestreamUiState.LivestreamLoaded) {
            val livestream = state.livestream
            val currentUserId = viewModel.getCurrentUserId()
            isBroadcasting = livestream.organizer_id == currentUserId

            if (isBroadcasting) {
                viewModel.startBroadcast(livestreamId)
            } else {
                viewModel.joinBroadcast(livestreamId)
            }
        }
    }

    // When transport is ready, create peer connection
    LaunchedEffect(uiState) {
        if (uiState is LivestreamUiState.TransportReady) {
            webRTCManager.createPeerConnection(if (isBroadcasting) "broadcaster" else "viewer")
            if (isBroadcasting) {
                webRTCManager.createLocalVideoTrack()
                webRTCManager.createLocalAudioTrack()
                webRTCManager.addLocalTracks()
                surfaceViewRenderer?.let {
                    webRTCManager.attachLocalVideo(it)
                }
                webRTCManager.createOffer()
            }
        }
    }

    // Handle signaling messages
    LaunchedEffect(Unit) {
        viewModel.signalingMessages.collect { msg ->
            when (msg.type) {
                "offer" -> {
                    val sdp = SessionDescription(SessionDescription.Type.OFFER, msg.sdp!!)
                    webRTCManager.createAnswer(sdp)
                }
                "answer" -> {
                    val sdp = SessionDescription(SessionDescription.Type.ANSWER, msg.sdp!!)
                    webRTCManager.setRemoteDescription(sdp)
                }
                "ice-candidate" -> {
                    val candidate = IceCandidate(msg.sdpMid!!, msg.sdpMLineIndex!!, msg.candidate!!)
                    webRTCManager.addIceCandidate(candidate)
                }
            }
        }
    }

    // Cleanup
    DisposableEffect(Unit) {
        onDispose {
            webRTCManager.dispose()
            viewModel.leaveLivestream()
            surfaceViewRenderer?.release()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Live Stream", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            AndroidView(
                factory = { ctx ->
                    SurfaceViewRenderer(ctx).apply {
                        surfaceViewRenderer = this
                    }
                },
                modifier = Modifier.fillMaxSize()
            )

            when {
                uiState is LivestreamUiState.Loading -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                uiState is LivestreamUiState.Error -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("Error: ${(uiState as LivestreamUiState.Error).message}", color = MaterialTheme.colorScheme.error)
                    }
                }
                uiState is LivestreamUiState.LivestreamLoaded -> {
                    val livestream = (uiState as LivestreamUiState.LivestreamLoaded).livestream
                    Text(
                        text = "Status: ${livestream.stream_status}",
                        color = Color.White,
                        modifier = Modifier.align(Alignment.TopStart).padding(16.dp)
                    )
                    if (livestream.pay_per_view_price > 0 && !isBroadcasting) {
                        Button(
                            onClick = { viewModel.purchaseLivestream(livestream.id) },
                            modifier = Modifier.align(Alignment.BottomCenter).padding(16.dp),
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryPink)
                        ) {
                            Text("Purchase Access $${livestream.pay_per_view_price}")
                        }
                    }
                }
                else -> Unit
            }

            if (isBroadcasting && (uiState is LivestreamUiState.LivestreamLoaded)) {
                Row(
                    modifier = Modifier.align(Alignment.BottomEnd).padding(16.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Button(
                        onClick = {
                            if (isStreamActive) {
                                viewModel.endLivestream(livestreamId)
                                isStreamActive = false
                            } else {
                                viewModel.startLivestream(livestreamId)
                                isStreamActive = true
                            }
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (isStreamActive) Color.Red else Color(0xFF4CAF50)
                        )
                    ) {
                        Text(if (isStreamActive) "Stop" else "Start")
                    }
                }
            }
        }
    }
}