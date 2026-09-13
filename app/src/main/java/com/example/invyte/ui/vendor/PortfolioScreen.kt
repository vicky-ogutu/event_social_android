package com.example.invyte.ui.vendor

import android.net.Uri
import androidx.activity.compose.BackHandler
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
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

@OptIn(ExperimentalMaterial3Api::class)
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

    // 👇 Handle system back press
    BackHandler(enabled = true) {
        navController.navigateUp()
    }

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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Portfolio", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(
                            Icons.Default.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFF1A1A1A)
                )
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { filePickerLauncher.launch("*/*") },
                containerColor = PrimaryPink,
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Upload", tint = Color.White)
            }
        }
    ) { innerPadding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
                .padding(innerPadding)
                .padding(paddingValues)
        ) {
            when (val currentState = portfolioState) {
                is PortfolioUiState.Loading -> {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = PrimaryPink)
                    }
                }
                is PortfolioUiState.PortfolioLoaded -> {
                    val items = currentState.items
                    if (items.isEmpty()) {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                Text("No portfolio items yet.", color = Color.Gray, fontSize = 16.sp)
                                Spacer(modifier = Modifier.height(8.dp))
                                Text("Tap + to upload your first item", color = Color.Gray, fontSize = 12.sp)
                            }
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
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedBorderColor = PrimaryPink,
                            unfocusedBorderColor = FieldBorder,
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

                        // Create multipart body
                        val requestFile = file.asRequestBody(mimeType.toMediaTypeOrNull())
                        val body = MultipartBody.Part.createFormData("image", file.name, requestFile)

                        viewModel.uploadPortfolio(body, caption.takeIf { it.isNotBlank() })
                        showUploadDialog = false
                        selectedUri = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryPink)
                ) {
                    Text("Upload", color = Color.White)
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

// ---------- Portfolio Item Card ----------
@Composable
fun PortfolioItemCard(item: PortfolioItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column {
            val isVideo = item.mediaType?.startsWith("video") == true ||
                    item.mediaUrl?.contains(".mp4") == true ||
                    item.mediaUrl?.contains(".mov") == true ||
                    item.mediaUrl?.contains(".webm") == true

            if (isVideo) {
                VideoPlayer(url = item.mediaUrl)
            } else {
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

// ---------- Video Player ----------
@Composable
fun VideoPlayer(url: String?) {
    val context = LocalContext.current

    val player = remember(url) {
        url?.let {
            ExoPlayer.Builder(context).build().apply {
                setMediaItem(MediaItem.fromUri(Uri.parse(it)))
                prepare()
                playWhenReady = false
            }
        }
    }

    DisposableEffect(player) {
        onDispose {
            player?.release()
        }
    }

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