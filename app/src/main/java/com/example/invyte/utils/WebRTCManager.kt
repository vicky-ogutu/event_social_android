package com.example.invyte.utils

import android.content.Context
import android.util.Log
import org.webrtc.AudioTrack
import org.webrtc.Camera1Enumerator
import org.webrtc.CameraVideoCapturer
import org.webrtc.DataChannel
import org.webrtc.EglBase
import org.webrtc.IceCandidate
import org.webrtc.MediaConstraints
import org.webrtc.MediaStream
import org.webrtc.PeerConnection
import org.webrtc.PeerConnection.IceServer
import org.webrtc.PeerConnection.RTCConfiguration
import org.webrtc.PeerConnectionFactory
import org.webrtc.RtpReceiver
import org.webrtc.RtpTransceiver
import org.webrtc.SdpObserver
import org.webrtc.SessionDescription
import org.webrtc.SurfaceViewRenderer
import org.webrtc.SurfaceTextureHelper
import org.webrtc.VideoCapturer
import org.webrtc.VideoSource
import org.webrtc.VideoTrack
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class WebRTCManager @Inject constructor(
    private val context: Context
) {

    companion object {
        private const val TAG = "WebRTC"
    }

    val eglBase: EglBase = EglBase.create()

    private var peerConnectionFactory: PeerConnectionFactory? = null
    private var peerConnection: PeerConnection? = null

    private var videoCapturer: VideoCapturer? = null
    private var surfaceTextureHelper: SurfaceTextureHelper? = null

    private var videoSource: VideoSource? = null
    private var audioSource: org.webrtc.AudioSource? = null

    private var localVideoTrack: VideoTrack? = null
    private var localAudioTrack: AudioTrack? = null

    private var remoteVideoTrack: VideoTrack? = null

    private lateinit var eventListener: WebRTCEventListener

    private val iceServers = listOf(
        IceServer
            .builder("stun:stun.l.google.com:19302")
            .createIceServer()
    )

    // ============================================================
    // INITIALIZE
    // ============================================================

    fun init(
        eventListener: WebRTCEventListener
    ) {

        this.eventListener = eventListener

        PeerConnectionFactory.initialize(
            PeerConnectionFactory.InitializationOptions
                .builder(context)
                .createInitializationOptions()
        )

        val encoderFactory =
            org.webrtc.DefaultVideoEncoderFactory(
                eglBase.eglBaseContext,
                true,
                true
            )

        val decoderFactory =
            org.webrtc.DefaultVideoDecoderFactory(
                eglBase.eglBaseContext
            )

        peerConnectionFactory =
            PeerConnectionFactory
                .builder()
                .setVideoEncoderFactory(encoderFactory)
                .setVideoDecoderFactory(decoderFactory)
                .createPeerConnectionFactory()

        Log.d(TAG, "PeerConnectionFactory initialized")
    }

    // ============================================================
    // CREATE PEER CONNECTION
    // ============================================================

    fun createPeerConnection(
        role: String
    ) {

        val rtcConfig =
            RTCConfiguration(iceServers).apply {

                iceTransportsType =
                    PeerConnection.IceTransportsType.ALL

                sdpSemantics =
                    PeerConnection.SdpSemantics.UNIFIED_PLAN
            }

        peerConnection =
            peerConnectionFactory?.createPeerConnection(
                rtcConfig,
                object : PeerConnection.Observer {

                    override fun onIceCandidate(
                        candidate: IceCandidate?
                    ) {

                        candidate ?: return

                        Log.d(
                            TAG,
                            "ICE candidate: ${candidate.sdp}"
                        )

                        eventListener.onIceCandidate(
                            candidate,
                            role
                        )
                    }

                    override fun onIceConnectionChange(
                        state: PeerConnection.IceConnectionState?
                    ) {

                        Log.d(
                            TAG,
                            "ICE state: $state"
                        )
                    }

                    override fun onSignalingChange(
                        state: PeerConnection.SignalingState?
                    ) {

                        Log.d(
                            TAG,
                            "Signaling state: $state"
                        )
                    }

                    override fun onIceGatheringChange(
                        state: PeerConnection.IceGatheringState?
                    ) {

                        Log.d(
                            TAG,
                            "ICE gathering state: $state"
                        )
                    }

                    override fun onConnectionChange(
                        state: PeerConnection.PeerConnectionState?
                    ) {

                        Log.d(
                            TAG,
                            "Connection state: $state"
                        )
                    }

                    override fun onTrack(
                        transceiver: RtpTransceiver?
                    ) {

                        val track =
                            transceiver
                                ?.receiver
                                ?.track()

                        if (track is VideoTrack) {

                            Log.d(
                                TAG,
                                "Remote video track received"
                            )

                            remoteVideoTrack = track

                            eventListener.onRemoteVideoTrack(
                                track
                            )
                        }
                    }

                    override fun onAddStream(
                        stream: MediaStream?
                    ) {
                    }

                    override fun onRemoveStream(
                        stream: MediaStream?
                    ) {
                    }

                    override fun onDataChannel(
                        dataChannel: DataChannel?
                    ) {
                    }

                    override fun onRenegotiationNeeded() {
                    }

                    override fun onIceConnectionReceivingChange(
                        receiving: Boolean
                    ) {
                    }

                    override fun onAddTrack(
                        receiver: RtpReceiver?,
                        mediaStreams: Array<out MediaStream>?
                    ) {
                    }

                    override fun onIceCandidatesRemoved(
                        candidates: Array<out IceCandidate>?
                    ) {
                    }

                    override fun onStandardizedIceConnectionChange(
                        newState: PeerConnection.IceConnectionState?
                    ) {
                    }
                }
            )

        Log.d(
            TAG,
            "PeerConnection created"
        )
    }

    // ============================================================
    // CREATE LOCAL VIDEO
    // ============================================================

    fun createLocalVideoTrack() {

        val factory =
            peerConnectionFactory
                ?: throw IllegalStateException(
                    "PeerConnectionFactory has not been initialized"
                )

        videoCapturer = getVideoCapturer()

        surfaceTextureHelper =
            SurfaceTextureHelper.create(
                "VideoCaptureThread",
                eglBase.eglBaseContext
            )

        videoSource =
            factory.createVideoSource(
                videoCapturer!!.isScreencast
            )

        videoCapturer!!.initialize(
            surfaceTextureHelper,
            context,
            videoSource!!.capturerObserver
        )

        localVideoTrack =
            factory.createVideoTrack(
                "video_track",
                videoSource
            )

        localVideoTrack!!.setEnabled(true)

        videoCapturer!!.startCapture(
            640,
            480,
            30
        )

        Log.d(
            TAG,
            "Local video track created"
        )
    }

    // ============================================================
    // CAMERA
    // ============================================================

    private fun getVideoCapturer(): CameraVideoCapturer {

        val enumerator =
            Camera1Enumerator(false)

        val frontCamera =
            enumerator.deviceNames
                .firstOrNull {
                    enumerator.isFrontFacing(it)
                }

        val cameraName =
            frontCamera
                ?: enumerator.deviceNames.firstOrNull()
                ?: throw IllegalStateException(
                    "No camera found"
                )

        return enumerator.createCapturer(
            cameraName,
            null
        )
            ?: throw IllegalStateException(
                "Could not create camera capturer"
            )
    }

    // ============================================================
    // CREATE LOCAL AUDIO
    // ============================================================

    fun createLocalAudioTrack() {

        val factory =
            peerConnectionFactory
                ?: throw IllegalStateException(
                    "PeerConnectionFactory has not been initialized"
                )

        audioSource =
            factory.createAudioSource(
                MediaConstraints()
            )

        localAudioTrack =
            factory.createAudioTrack(
                "audio_track",
                audioSource
            )

        localAudioTrack!!.setEnabled(true)

        Log.d(
            TAG,
            "Local audio track created"
        )
    }

    // ============================================================
    // ADD TRACKS
    // ============================================================

    fun addLocalTracks() {

        val pc =
            peerConnection
                ?: throw IllegalStateException(
                    "PeerConnection has not been created"
                )

        localVideoTrack?.let { video ->

            pc.addTrack(
                video,
                listOf("stream_id")
            )
        }

        localAudioTrack?.let { audio ->

            pc.addTrack(
                audio,
                listOf("stream_id")
            )
        }

        Log.d(
            TAG,
            "Local tracks added"
        )
    }

    // ============================================================
    // LOCAL VIDEO RENDERER
    // ============================================================

    fun attachLocalVideo(
        renderer: SurfaceViewRenderer
    ) {

        renderer.init(
            eglBase.eglBaseContext,
            null
        )

        renderer.setEnableHardwareScaler(true)
        renderer.setMirror(true)

        localVideoTrack?.addSink(renderer)

        Log.d(
            TAG,
            "Local video attached"
        )
    }

    // ============================================================
    // REMOTE VIDEO RENDERER
    // ============================================================

    fun attachRemoteVideo(
        renderer: SurfaceViewRenderer
    ) {

        renderer.init(
            eglBase.eglBaseContext,
            null
        )

        renderer.setEnableHardwareScaler(true)

        remoteVideoTrack?.addSink(renderer)

        Log.d(
            TAG,
            "Remote video attached"
        )
    }

    // ============================================================
    // CREATE OFFER
    // ============================================================

    fun createOffer() {

        val pc =
            peerConnection
                ?: throw IllegalStateException(
                    "PeerConnection has not been created"
                )

        val constraints =
            MediaConstraints()

        pc.createOffer(
            object : SdpObserver {

                override fun onCreateSuccess(
                    description: SessionDescription
                ) {

                    Log.d(
                        TAG,
                        "Offer created"
                    )

                    pc.setLocalDescription(
                        object : SdpObserver {

                            override fun onSetSuccess() {

                                Log.d(
                                    TAG,
                                    "Local offer set"
                                )

                                eventListener
                                    .onOfferCreated(
                                        description
                                    )
                            }

                            override fun onSetFailure(
                                error: String?
                            ) {

                                Log.e(
                                    TAG,
                                    "Failed to set local offer: $error"
                                )
                            }

                            override fun onCreateSuccess(
                                p0: SessionDescription?
                            ) {
                            }

                            override fun onCreateFailure(
                                p0: String?
                            ) {
                            }
                        },
                        description
                    )
                }

                override fun onCreateFailure(
                    error: String?
                ) {

                    Log.e(
                        TAG,
                        "Offer creation failed: $error"
                    )
                }

                override fun onSetSuccess() {
                }

                override fun onSetFailure(
                    error: String?
                ) {
                }
            },
            constraints
        )
    }

    // ============================================================
    // CREATE ANSWER
    // ============================================================

    fun createAnswer(
        offer: SessionDescription
    ) {

        val pc =
            peerConnection
                ?: throw IllegalStateException(
                    "PeerConnection has not been created"
                )

        pc.setRemoteDescription(
            object : SdpObserver {

                override fun onSetSuccess() {

                    Log.d(
                        TAG,
                        "Remote offer set"
                    )

                    pc.createAnswer(
                        object : SdpObserver {

                            override fun onCreateSuccess(
                                answer: SessionDescription
                            ) {

                                Log.d(
                                    TAG,
                                    "Answer created"
                                )

                                pc.setLocalDescription(
                                    object : SdpObserver {

                                        override fun onSetSuccess() {

                                            Log.d(
                                                TAG,
                                                "Local answer set"
                                            )

                                            eventListener
                                                .onAnswerCreated(
                                                    answer
                                                )
                                        }

                                        override fun onSetFailure(
                                            error: String?
                                        ) {

                                            Log.e(
                                                TAG,
                                                "Failed to set answer: $error"
                                            )
                                        }

                                        override fun onCreateSuccess(
                                            p0: SessionDescription?
                                        ) {
                                        }

                                        override fun onCreateFailure(
                                            p0: String?
                                        ) {
                                        }
                                    },
                                    answer
                                )
                            }

                            override fun onCreateFailure(
                                error: String?
                            ) {

                                Log.e(
                                    TAG,
                                    "Answer creation failed: $error"
                                )
                            }

                            override fun onSetSuccess() {
                            }

                            override fun onSetFailure(
                                error: String?
                            ) {
                            }
                        },
                        MediaConstraints()
                    )
                }

                override fun onSetFailure(
                    error: String?
                ) {

                    Log.e(
                        TAG,
                        "Failed to set remote offer: $error"
                    )
                }

                override fun onCreateSuccess(
                    p0: SessionDescription?
                ) {
                }

                override fun onCreateFailure(
                    p0: String?
                ) {
                }
            },
            offer
        )
    }

    // ============================================================
    // SET REMOTE DESCRIPTION
    // ============================================================

    fun setRemoteDescription(
        sdp: SessionDescription
    ) {

        val pc =
            peerConnection
                ?: return

        pc.setRemoteDescription(
            object : SdpObserver {

                override fun onSetSuccess() {

                    Log.d(
                        TAG,
                        "Remote SDP set successfully"
                    )
                }

                override fun onSetFailure(
                    error: String?
                ) {

                    Log.e(
                        TAG,
                        "Remote SDP failed: $error"
                    )
                }

                override fun onCreateSuccess(
                    p0: SessionDescription?
                ) {
                }

                override fun onCreateFailure(
                    p0: String?
                ) {
                }
            },
            sdp
        )
    }

    // ============================================================
    // ICE
    // ============================================================

    fun addIceCandidate(
        candidate: IceCandidate
    ) {

        val pc =
            peerConnection
                ?: return

        pc.addIceCandidate(candidate)

        Log.d(
            TAG,
            "ICE candidate added"
        )
    }

    // ============================================================
    // GET TRACKS
    // ============================================================

    fun getLocalVideoTrack(): VideoTrack? {
        return localVideoTrack
    }

    fun getRemoteVideoTrack(): VideoTrack? {
        return remoteVideoTrack
    }

    // ============================================================
    // DISPOSE
    // ============================================================

    fun dispose() {

        try {
            videoCapturer?.stopCapture()
        } catch (e: Exception) {
            Log.e(
                TAG,
                "Error stopping capture",
                e
            )
        }

        videoCapturer?.dispose()
        surfaceTextureHelper?.dispose()

        localVideoTrack?.dispose()
        localAudioTrack?.dispose()

        videoSource?.dispose()
        audioSource?.dispose()

        peerConnection?.dispose()
        peerConnectionFactory?.dispose()

        eglBase.release()

        videoCapturer = null
        surfaceTextureHelper = null
        videoSource = null
        audioSource = null
        localVideoTrack = null
        localAudioTrack = null
        remoteVideoTrack = null
        peerConnection = null
        peerConnectionFactory = null

        Log.d(
            TAG,
            "WebRTC disposed"
        )
    }

    // ============================================================
    // EVENTS
    // ============================================================

    interface WebRTCEventListener {

        fun onIceCandidate(
            candidate: IceCandidate,
            role: String
        )

        fun onOfferCreated(
            offer: SessionDescription
        )

        fun onAnswerCreated(
            answer: SessionDescription
        )

        fun onRemoteVideoTrack(
            track: VideoTrack
        )
    }
}