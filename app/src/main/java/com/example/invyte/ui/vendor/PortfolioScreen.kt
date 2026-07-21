package com.example.invyte.ui.vendor

import android.net.Uri
import android.widget.MediaController
import android.widget.VideoView
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material3.*
import androidx.compose.material3.TextFieldDefaults.colors
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.PortfolioItem
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import com.google.android.exoplayer2.ExoPlayer
import com.google.android.exoplayer2.MediaItem
import com.google.android.exoplayer2.ui.PlayerView
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.FileOutputStream

@Composable
fun PortfolioScreen(
    navController: NavController,
    paddingValues: PaddingValues = PaddingValues(0.dp),
    viewModel: VendorViewModel = hiltViewModel()
) {
    val portfolioState by viewModel.portfolioState.collectAsState()
    val context = LocalContext.current

    // State for file picking
    var selectedUri by remember { mutableStateOf<Uri?>(null) }
    var showUploadDialog by remember { mutableStateOf(false) }

    // File picker – allows both images and videos
    val filePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            selectedUri = it
            showUploadDialog = true
        }
    }

    LaunchedEffect(Unit) {
        viewModel.getPortfolio()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
            .padding(paddingValues)
    ) {
        when (val currentState = portfolioState) {
            is PortfolioUiState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is PortfolioUiState.PortfolioLoaded -> {
                val items = currentState.items
                if (items.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No portfolio items yet.", color = Color.Gray)
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        items(items) { item ->
                            PortfolioItemCard(item)
                        }
                    }
                }
            }
            is PortfolioUiState.Error -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${currentState.message}", color = Color.Red)
                }
            }
            else -> Unit
        }

        // FAB – now uses "*/*" to accept any media
        FloatingActionButton(
            onClick = { filePickerLauncher.launch("*/*") }, // allows images & videos
            containerColor = Color(0xFFE91E63),
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Upload", tint = Color.White)
        }
    }

    // Upload dialog
    if (showUploadDialog && selectedUri != null) {
        var caption by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = {
                showUploadDialog = false
                selectedUri = null
            },
            title = { Text("Upload Portfolio Item", color = Color.White) },
            text = {
                Column {
                    Text("Selected media", color = Color.White)
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = caption,
                        onValueChange = { caption = it },
                        label = { Text("Caption (optional)", color = Color.Gray) },
                        modifier = Modifier.fillMaxWidth(),
                        colors = colors(
                            focusedIndicatorColor = PrimaryPink,
                            unfocusedIndicatorColor = FieldBorder,
                            focusedLabelColor = TextWhite,
                            unfocusedLabelColor = FieldBorder,
                            focusedTextColor = TextWhite,
                            unfocusedTextColor = TextWhite
                        )
                    )
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        val uri = selectedUri!!
                        // Detect MIME type from URI
                        val mimeType = context.contentResolver.getType(uri) ?: "image/jpeg"
                        val fileExtension = when {
                            mimeType.startsWith("video/") -> "mp4"
                            else -> "jpg"
                        }
                        val fileName = "portfolio_${System.currentTimeMillis()}.$fileExtension"

                        // Copy file to cache
                        val file = File(context.cacheDir, fileName)
                        context.contentResolver.openInputStream(uri)?.use { input ->
                            FileOutputStream(file).use { output ->
                                input.copyTo(output)
                            }
                        }

                        // Create multipart body with correct MIME type
                        val requestFile = file.asRequestBody(mimeType.toMediaTypeOrNull())
                        val body = MultipartBody.Part.createFormData("image", file.name, requestFile)

                        // Upload
                        viewModel.uploadPortfolio(body, caption.takeIf { it.isNotBlank() })
                        showUploadDialog = false
                        selectedUri = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
                ) {
                    Text("Upload")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showUploadDialog = false
                    selectedUri = null
                }) {
                    Text("Cancel", color = Color.White)
                }
            },
            containerColor = Color(0xFF1A1A1A)
        )
    }
}

// ---------- Portfolio Item Card (supports both image and video) ----------
@Composable
fun PortfolioItemCard(item: PortfolioItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column {
            // Determine media type from URL or separate field
            val isVideo = item.mediaType?.startsWith("video") == true ||
                    item.mediaUrl?.contains(".mp4") == true ||
                    item.mediaUrl?.contains(".mov") == true ||
                    item.mediaUrl?.contains(".webm") == true

            if (isVideo) {
                // Video player (ExoPlayer)
                VideoPlayer(url = item.mediaUrl)
            } else {
                // Image
                AsyncImage(
                    model = item.mediaUrl,
                    contentDescription = item.caption ?: "Portfolio",
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(200.dp),
                    contentScale = ContentScale.Crop
                )
            }

            if (item.caption != null) {
                Text(
                    text = item.caption!!,
                    color = Color.White,
                    modifier = Modifier.padding(12.dp)
                )
            }
        }
    }
}

// ---------- Video Player using ExoPlayer ----------
@Composable
fun VideoPlayer(url: String?) {
    val context = LocalContext.current

    // Create player when URL changes
    val player = remember(url) {
        url?.let {
            ExoPlayer.Builder(context).build().apply {
                setMediaItem(MediaItem.fromUri(Uri.parse(it)))
                prepare()
                playWhenReady = false // start paused
            }
        }
    }

    // Release player on dispose
    DisposableEffect(player) {
        onDispose {
            player?.release()
        }
    }

    // Capture player in a local variable to avoid label issues
    val currentPlayer = player

    AndroidView(
        factory = { ctx ->
            PlayerView(ctx).apply {
                this.player = currentPlayer
                useController = true
                keepScreenOn = true
            }
        },
        update = { view ->
            view.player = currentPlayer
        },
        modifier = Modifier
            .fillMaxWidth()
            .height(200.dp)
    )
}