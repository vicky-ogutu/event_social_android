package com.example.invyte.ui.vendor

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.ServiceCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorDetailScreen(
    navController: NavController,
    vendorId: Int,
    viewModel: VendorDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.loadVendorDetail(vendorId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Vendor Details", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        when (uiState) {
            is VendorDetailUiState.Loading -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator()
                }
            }
            is VendorDetailUiState.Success -> {
                val vendor = (uiState as VendorDetailUiState.Success).vendor
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .background(Color(0xFF121212))
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Vendor info
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            shape = RoundedCornerShape(16.dp),
                            colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                        ) {
                            Column(modifier = Modifier.padding(16.dp)) {
                                Text(
                                    text = vendor.business_name,
                                    style = MaterialTheme.typography.headlineSmall,
                                    color = Color.White
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "⭐ ${vendor.rating} (${vendor.review_count} reviews)",
                                    color = Color.Gray
                                )
                                vendor.service_category?.let {
                                    Text(
                                        text = "Category: $it",
                                        color = Color.Gray,
                                        fontSize = 14.sp
                                    )
                                }
                                vendor.business_address?.let {
                                    Text(
                                        text = "📍 $it",
                                        color = Color.Gray,
                                        fontSize = 14.sp
                                    )
                                }
                                Button(
                                    onClick = { navController.navigate("chat/${vendor.id}") },
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    Text("Message Vendor")
                                }
                            }
                        }
                    }

                    // Services section
                    if (!vendor.services.isNullOrEmpty()) {
                        item {
                            Text(
                                text = "Services",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White,
                                modifier = Modifier.padding(top = 8.dp)
                            )
                        }
                        items(vendor.services) { service ->
                            ServiceCard(
                                service = service,
                                onBook = { navController.navigate("booking/${vendor.id}/${service.id}") }
                                // onEdit and onDelete not needed for consumer
                            )
                        }
                    }

                    // Portfolio section
                    if (!vendor.portfolio.isNullOrEmpty()) {
                        item {
                            Text(
                                text = "Portfolio",
                                style = MaterialTheme.typography.titleMedium,
                                color = Color.White,
                                modifier = Modifier.padding(top = 8.dp)
                            )
                        }
                        items(vendor.portfolio) { item ->
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
                    }

                    // If no services or portfolio
                    if (vendor.services.isNullOrEmpty() && vendor.portfolio.isNullOrEmpty()) {
                        item {
                            Text(
                                text = "This vendor hasn't added any services or portfolio items yet.",
                                color = Color.Gray,
                                modifier = Modifier.padding(vertical = 16.dp)
                            )
                        }
                    }
                }
            }
            is VendorDetailUiState.Error -> {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "Error: ${(uiState as VendorDetailUiState.Error).message}",
                        color = Color.Red
                    )
                }
            }
        }
    }
}