package com.example.invyte.ui.event
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.TextFieldDefaults.colors
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.Event
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import com.example.invyte.ui.vendor.SocketManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventDetailScreen(
    navController: NavController,
    eventId: Int,
    viewModel: EventViewModel = hiltViewModel(),
    socketManager: SocketManager = hiltViewModel()
) {
    val detailState by viewModel.detailState.collectAsState()
    val actionState by viewModel.actionState.collectAsState()
    var showJoinDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.getEvent(eventId)
        //viewModel.joinEvent(eventId)
        socketManager.connect()
        socketManager.joinEvent(eventId)
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Event Details", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        when (detailState) {
            is EventDetailUiState.Loading -> {
                Box(modifier = Modifier.fillMaxSize().padding(paddingValues), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is EventDetailUiState.Success -> {
                val event = (detailState as EventDetailUiState.Success).event
                EventDetailContent(
                    event = event,
                    onLike = { viewModel.toggleLike(event.id) },
                    onJoin = { showJoinDialog = true },
                    isLiked = false // we don't have liked state from API; could be extended
                )
            }
            is EventDetailUiState.Error -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${(detailState as EventDetailUiState.Error).message}", color = Color.Red)
                }
            }
            else -> Unit
        }
    }

    if (showJoinDialog && detailState is EventDetailUiState.Success) {
        val event = (detailState as EventDetailUiState.Success).event
        JoinEventDialog(
            event = event,
            onDismiss = { showJoinDialog = false },
            onJoin = { code ->
                viewModel.joinEvent(event.id, code)
                showJoinDialog = false
            }
        )
    }

    // Handle action state (join success/error)
    LaunchedEffect(actionState) {
        if (actionState is EventActionUiState.Success) {
            // Refresh event detail to update access
            viewModel.getEvent(eventId)
            viewModel.resetActionState()
        }
    }
}

@Composable
fun EventDetailContent(
    event: Event,
    onLike: () -> Unit,
    onJoin: () -> Unit,
    isLiked: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
            .padding(16.dp)
    ) {
        // Cover image
        AsyncImage(
            model = event.coverImage ?: "https://via.placeholder.com/400x200?text=Event",
            contentDescription = "Cover",
            modifier = Modifier
                .fillMaxWidth()
                .height(200.dp)
                .clip(RoundedCornerShape(16.dp)),
            contentScale = ContentScale.Crop
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = event.eventName,
            style = MaterialTheme.typography.headlineMedium,
            color = Color.White,
            fontWeight = FontWeight.Bold
        )

        Text(
            text = "Organized by ${event.organizerName ?: "Unknown"}",
            color = Color.Gray,
            fontSize = 14.sp,
            modifier = Modifier.padding(top = 4.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.CalendarToday, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(text = event.eventDate, color = Color.White, fontSize = 14.sp)
            }
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Default.Schedule, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(text = "${event.startTime} - ${event.endTime ?: "TBD"}", color = Color.White, fontSize = 14.sp)
            }
        }

        if (event.venueAddress != null) {
            Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.padding(top = 8.dp)) {
                Icon(Icons.Default.LocationOn, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(4.dp))
                Text(text = event.venueAddress, color = Color.White, fontSize = 14.sp)
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "About this event",
            style = MaterialTheme.typography.titleMedium,
            color = Color.White,
            fontWeight = FontWeight.SemiBold
        )
        Text(
            text = event.eventDescription ?: "No description provided.",
            color = Color.Gray,
            modifier = Modifier.padding(top = 8.dp)
        )

        Spacer(modifier = Modifier.height(24.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(16.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Button(
                onClick = onLike,
                colors = ButtonDefaults.buttonColors(containerColor = if (isLiked) Color(0xFFE91E63) else Color(0xFF2A2A2A)),
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier.weight(1f)
            ) {
                Icon(Icons.Default.Favorite, contentDescription = null, tint = Color.White)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Like (${event.likeCount ?: 0})", color = Color.White)
            }

            if (event.eventType == "private") {
                Button(
                    onClick = onJoin,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Icon(Icons.Default.Lock, contentDescription = null, tint = Color.White)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Join Private", color = Color.White)
                }
            } else {
                Button(
                    onClick = { /* maybe join public? */ },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                    shape = RoundedCornerShape(16.dp),
                    modifier = Modifier.weight(1f),
                    enabled = false
                ) {
                    Text("Public Event", color = Color.White)
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Stats
        Row(
            horizontalArrangement = Arrangement.spacedBy(24.dp),
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("👁️ ${event.viewCount ?: 0} views", color = Color.Gray)
            Text("⭐ ${event.likeCount ?: 0} likes", color = Color.Gray)
            if (event.expectedAttendees != null) {
                Text("👥 ${event.expectedAttendees} expected", color = Color.Gray)
            }
        }
    }
}

@Composable
fun JoinEventDialog(
    event: Event,
    onDismiss: () -> Unit,
    onJoin: (String) -> Unit
) {
    var code by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Join Private Event", color = Color.White) },
        text = {
            Column {
                Text("This event is private. Please enter the access code.", color = Color.White)
                Spacer(modifier = Modifier.height(8.dp))
                OutlinedTextField(
                    value = code,
                    onValueChange = { code = it },
                    label = { Text("Access Code", color = Color.Gray) },
                    colors = colors(
                        focusedIndicatorColor = PrimaryPink,
                        unfocusedIndicatorColor = FieldBorder,
                        focusedLabelColor = TextWhite,
                        unfocusedLabelColor = FieldBorder,
                        focusedTextColor = TextWhite,
                        unfocusedTextColor = TextWhite
                    ),
                    singleLine = true
                )
            }
        },
        confirmButton = {
            Button(
                onClick = { onJoin(code) },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
            ) {
                Text("Join")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = Color.White)
            }
        },
        containerColor = Color(0xFF1A1A1A)
    )
}