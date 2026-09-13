package com.example.invyte.ui.consumer

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Livestream
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.vendor.LivestreamListUiState
import com.example.invyte.ui.vendor.LivestreamViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun LivestreamListScreen(
    navController: NavController,
    viewModel: LivestreamViewModel = hiltViewModel()
) {
    val uiState by viewModel.livestreamsState.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.loadLivestreams("live")
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Live Streams", color = Color.White) },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { padding ->
        when (uiState) {
            is LivestreamListUiState.Loading -> {
                Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is LivestreamListUiState.Success -> {
                val data = (uiState as LivestreamListUiState.Success).data
                if (data.data.isEmpty()) {
                    Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                        Text("No live streams available", color = Color.Gray)
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize().padding(padding),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(data.data) { livestream ->
                            LivestreamCard(
                                livestream = livestream,
                                onClick = {
                                    navController.navigate("livestream_player/${livestream.id}")
                                }
                            )
                        }
                    }
                }
            }
            is LivestreamListUiState.Error -> {
                Box(Modifier.fillMaxSize().padding(padding), contentAlignment = Alignment.Center) {
                    Text("Error: ${(uiState as LivestreamListUiState.Error).message}", color = Color.Red)
                }
            }
        }
    }
}

@Composable
fun LivestreamCard(livestream: Livestream, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = MaterialTheme.shapes.medium,
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = livestream.event_name ?: "Live Stream",
                style = MaterialTheme.typography.titleMedium,
                color = Color.White,
                fontWeight = FontWeight.Bold
            )
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = "Status: ${livestream.stream_status.uppercase()}",
                    color = if (livestream.stream_status == "live") Color(0xFF4CAF50) else Color(0xFFFFC107),
                    fontSize = 14.sp
                )
                Text(
                    text = "👁️ ${livestream.view_count}",
                    color = Color.Gray,
                    fontSize = 12.sp
                )
            }
            if (livestream.pay_per_view_price > 0) {
                Text(
                    text = "💰 $${livestream.pay_per_view_price}",
                    color = PrimaryPink,
                    fontSize = 14.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}