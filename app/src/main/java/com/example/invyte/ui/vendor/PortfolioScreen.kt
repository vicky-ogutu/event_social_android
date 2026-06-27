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
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
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
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.FileOutputStream

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PortfolioScreen(
    navController: NavController,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val portfolioState by viewModel.portfolioState.collectAsState()
    val context = LocalContext.current
    var showUploadDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.getPortfolio()
    }

    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            // Show a dialog to enter caption
            showUploadDialog = true
            // We'll handle upload in the dialog
            // Store the URI temporarily
            // Use a state to pass URI to dialog
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Portfolio", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    IconButton(onClick = { imagePickerLauncher.launch("image/*") }) {
                        Icon(Icons.Default.Add, contentDescription = "Add", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        when (portfolioState) {
            is PortfolioUiState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is PortfolioUiState.PortfolioLoaded -> {
                val items = (portfolioState as PortfolioUiState.PortfolioLoaded).items
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color(0xFF121212))
                        .padding(paddingValues)
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(items) { item ->
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
                                        modifier = Modifier.padding(8.dp)
                                    )
                                }
                            }
                        }
                    }
                }
            }
            is PortfolioUiState.Error -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${(portfolioState as PortfolioUiState.Error).message}", color = Color.Red)
                }
            }
            else -> Unit
        }
    }

    // Upload dialog
    if (showUploadDialog) {
        // We need to capture the URI from the launcher. Since launcher is async, we'll use a state.
        // Simpler: use a separate state for selectedUri.
        // We'll refactor: use a mutableStateOf<Uri?> and set it when image is picked.
    }
}