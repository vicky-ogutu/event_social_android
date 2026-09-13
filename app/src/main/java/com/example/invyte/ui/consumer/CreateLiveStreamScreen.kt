package com.example.invyte.ui.consumer


import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.CreateLivestreamRequest
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.vendor.LivestreamUiState
import com.example.invyte.ui.vendor.LivestreamViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CreateLivestreamScreen(
    navController: NavController,
    eventId: Int,
    viewModel: LivestreamViewModel = hiltViewModel()
) {
    var price by remember { mutableStateOf("") }
    var schedule by remember { mutableStateOf("") }
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState) {
        if (uiState is LivestreamUiState.LivestreamLoaded) {
            // Created successfully – navigate to the stream player
            val livestream = (uiState as LivestreamUiState.LivestreamLoaded).livestream
            navController.navigate("livestream_player/${livestream.id}")
            viewModel.resetState()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Create Livestream", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            OutlinedTextField(
                value = price,
                onValueChange = { price = it },
                label = { Text("Pay‑per‑view price ($)") },
                modifier = Modifier.fillMaxWidth()
            )
            OutlinedTextField(
                value = schedule,
                onValueChange = { schedule = it },
                label = { Text("Scheduled start (optional)") },
                modifier = Modifier.fillMaxWidth()
            )
            Button(
                onClick = {
                    val request = CreateLivestreamRequest(
                        event_id = eventId,
                        pay_per_view_price = price.toDoubleOrNull() ?: 0.0,
                        scheduled_start = schedule.takeIf { it.isNotBlank() }
                    )
                    viewModel.createLivestream(request)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(containerColor = PrimaryPink)
            ) {
                if (uiState is LivestreamUiState.Loading) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp))
                } else {
                    Text("Create Stream")
                }
            }
            if (uiState is LivestreamUiState.Error) {
                Text((uiState as LivestreamUiState.Error).message, color = Color.Red)
            }
        }
    }
}