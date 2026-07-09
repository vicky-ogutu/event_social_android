package com.example.invyte.ui.vendor

import android.net.Uri
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
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.PortfolioItem
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.FileOutputStream

@Composable
fun PortfolioScreen(
    navController: NavController,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val portfolioState by viewModel.portfolioState.collectAsState()
    val context = LocalContext.current

    // Capture state for safe smart‑casting
    val currentState = portfolioState

    // State for image picking
    var selectedImageUri by remember { mutableStateOf<Uri?>(null) }
    var showUploadDialog by remember { mutableStateOf(false) }

    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            selectedImageUri = it
            showUploadDialog = true
        }
    }

    // Load portfolio on first composition
    LaunchedEffect(Unit) {
        viewModel.getPortfolio()
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
    ) {
        when (currentState) {
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
            else -> Unit // Idle state – do nothing
        }

        // FAB to upload new portfolio item
        FloatingActionButton(
            onClick = { imagePickerLauncher.launch("image/*") },
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
    if (showUploadDialog && selectedImageUri != null) {
        var caption by remember { mutableStateOf("") }
        AlertDialog(
            onDismissRequest = {
                showUploadDialog = false
                selectedImageUri = null
            },
            title = { Text("Upload Portfolio Item", color = Color.White) },
            text = {
                Column {
                    Text("Selected image", color = Color.White)
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
                        val uri = selectedImageUri!!
                        // Convert URI to file
                        val file = File(context.cacheDir, "portfolio_${System.currentTimeMillis()}.jpg")
                        context.contentResolver.openInputStream(uri)?.use { input ->
                            FileOutputStream(file).use { output ->
                                input.copyTo(output)
                            }
                        }
                        val requestFile = file.asRequestBody("image/jpeg".toMediaTypeOrNull())
                        val body = MultipartBody.Part.createFormData("image", file.name, requestFile)
                        viewModel.uploadPortfolio(body, caption.takeIf { it.isNotBlank() })
                        showUploadDialog = false
                        selectedImageUri = null
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
                ) {
                    Text("Upload")
                }
            },
            dismissButton = {
                TextButton(onClick = {
                    showUploadDialog = false
                    selectedImageUri = null
                }) {
                    Text("Cancel", color = Color.White)
                }
            },
            containerColor = Color(0xFF1A1A1A)
        )
    }
}

@Composable
fun PortfolioItemCard(item: PortfolioItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column {
            AsyncImage(
                model = item.mediaUrl,
                contentDescription = item.caption ?: "Portfolio",
                modifier = Modifier
                    .fillMaxWidth()
                    .height(200.dp),
                contentScale = ContentScale.Crop
            )
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