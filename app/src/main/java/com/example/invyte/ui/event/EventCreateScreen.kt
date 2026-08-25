package com.example.invyte.ui.event

import android.net.Uri
import android.os.Build
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AddAPhoto
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.material3.TextFieldDefaults.colors
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.EventRequest
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import com.example.invyte.utils.ImagePickerHelper
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventCreateScreen(
    navController: NavController,
    eventId: Int? = null,
    viewModel: EventViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var eventName by remember { mutableStateOf("") }
    var eventDescription by remember { mutableStateOf("") }
    var eventType by remember { mutableStateOf("public") }
    var eventDate by remember { mutableStateOf(LocalDate.now().plusDays(7).format(DateTimeFormatter.ISO_LOCAL_DATE)) }
    var startTime by remember { mutableStateOf("19:00") }
    var endTime by remember { mutableStateOf("") }
    var venueAddress by remember { mutableStateOf("") }
    var latitude by remember { mutableStateOf("") }
    var longitude by remember { mutableStateOf("") }
    var expectedAttendees by remember { mutableStateOf("") }
    var budget by remember { mutableStateOf("") }
    var coverImageUrl by remember { mutableStateOf<String?>(null) }
    var accessCode by remember { mutableStateOf("") }
    var isUploading by remember { mutableStateOf(false) }

    val actionState by viewModel.actionState.collectAsState()
    val imagePicker = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            scope.launch {
                isUploading = true
                try {
                    val filePart = ImagePickerHelper.createMultipartBody(context, it)
                    filePart?.let { part ->
                        val result = viewModel.uploadCoverImage(part)
                        if (result.isSuccess) {
                            coverImageUrl = result.getOrNull()
                        }
                    }
                } finally {
                    isUploading = false
                }
            }
        }
    }

    LaunchedEffect(actionState) {
        if (actionState is EventActionUiState.Success) {
            navController.navigateUp()
            viewModel.resetActionState()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (eventId == null) "Create Event" else "Edit Event", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
                .padding(paddingValues)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
            contentPadding = PaddingValues(vertical = 16.dp)
        ) {
            // --- Cover Image ---
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                ) {
                    Column {
                        if (coverImageUrl != null) {
                            AsyncImage(
                                model = coverImageUrl,
                                contentDescription = "Cover",
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(180.dp)
                                    .clip(RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)),
                                contentScale = ContentScale.Crop
                            )
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                contentAlignment = Alignment.CenterEnd
                            ) {
                                TextButton(onClick = { coverImageUrl = null }) {
                                    Text("Remove", color = Color(0xFFE53935))
                                }
                            }
                        } else {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(120.dp)
                                    .clickable {
                                        imagePicker.launch("image/*")
                                    },
                                contentAlignment = Alignment.Center
                            ) {
                                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                                    Icon(Icons.Default.AddAPhoto, contentDescription = null, tint = Color.Gray, modifier = Modifier.size(48.dp))
                                    Text("Add Cover Image", color = Color.Gray, fontSize = 14.sp)
                                }
                            }
                        }
                    }
                }
            }

            // --- Basic Info ---
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Basic Information", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedTextField(
                            value = eventName,
                            onValueChange = { eventName = it },
                            label = { Text("Event Name *", color = Color.Gray) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = defaultTextFieldColors()
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedTextField(
                            value = eventDescription,
                            onValueChange = { eventDescription = it },
                            label = { Text("Description", color = Color.Gray) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = defaultTextFieldColors(),
                            maxLines = 3
                        )
                    }
                }
            }

            // --- Date & Time ---
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Date & Time", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedTextField(
                            value = eventDate,
                            onValueChange = { eventDate = it },
                            label = { Text("Event Date (YYYY-MM-DD) *", color = Color.Gray) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = defaultTextFieldColors()
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedTextField(
                                value = startTime,
                                onValueChange = { startTime = it },
                                label = { Text("Start Time *", color = Color.Gray) },
                                modifier = Modifier.weight(1f),
                                colors = defaultTextFieldColors()
                            )
                            OutlinedTextField(
                                value = endTime,
                                onValueChange = { endTime = it },
                                label = { Text("End Time", color = Color.Gray) },
                                modifier = Modifier.weight(1f),
                                colors = defaultTextFieldColors()
                            )
                        }
                    }
                }
            }

            // --- Venue & Location ---
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Venue & Location", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedTextField(
                            value = venueAddress,
                            onValueChange = { venueAddress = it },
                            label = { Text("Venue Address", color = Color.Gray) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = defaultTextFieldColors()
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            OutlinedTextField(
                                value = latitude,
                                onValueChange = { latitude = it },
                                label = { Text("Latitude", color = Color.Gray) },
                                modifier = Modifier.weight(1f),
                                colors = defaultTextFieldColors()
                            )
                            OutlinedTextField(
                                value = longitude,
                                onValueChange = { longitude = it },
                                label = { Text("Longitude", color = Color.Gray) },
                                modifier = Modifier.weight(1f),
                                colors = defaultTextFieldColors()
                            )
                        }
                    }
                }
            }

            // --- Additional Details ---
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Additional Details", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedTextField(
                            value = expectedAttendees,
                            onValueChange = { expectedAttendees = it },
                            label = { Text("Expected Attendees", color = Color.Gray) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = defaultTextFieldColors()
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        OutlinedTextField(
                            value = budget,
                            onValueChange = { budget = it },
                            label = { Text("Budget", color = Color.Gray) },
                            modifier = Modifier.fillMaxWidth(),
                            colors = defaultTextFieldColors()
                        )
                    }
                }
            }

            // --- Event Type & Access ---
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
                ) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Event Privacy", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
                        Spacer(modifier = Modifier.height(8.dp))
                        Row {
                            FilterChip(
                                selected = eventType == "public",
                                onClick = { eventType = "public" },
                                label = { Text("Public", color = Color.White) },
                                modifier = Modifier.weight(1f),
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = PrimaryPink,
                                    selectedLabelColor = Color.White
                                )
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            FilterChip(
                                selected = eventType == "private",
                                onClick = { eventType = "private" },
                                label = { Text("Private", color = Color.White) },
                                modifier = Modifier.weight(1f),
                                colors = FilterChipDefaults.filterChipColors(
                                    selectedContainerColor = PrimaryPink,
                                    selectedLabelColor = Color.White
                                )
                            )
                        }
                        if (eventType == "private") {
                            Spacer(modifier = Modifier.height(8.dp))
                            OutlinedTextField(
                                value = accessCode,
                                onValueChange = { accessCode = it },
                                label = { Text("Access Code (optional)", color = Color.Gray) },
                                modifier = Modifier.fillMaxWidth(),
                                colors = defaultTextFieldColors()
                            )
                        }
                    }
                }
            }

            // --- Submit Button ---
            item {
                Button(
                    onClick = {
                        val request = EventRequest(
                            eventName = eventName,
                            eventDescription = eventDescription.takeIf { it.isNotBlank() },
                            eventType = eventType,
                            accessCode = accessCode.takeIf { it.isNotBlank() },
                            eventDate = eventDate,
                            startTime = startTime,
                            endTime = endTime.takeIf { it.isNotBlank() },
                            venueAddress = venueAddress.takeIf { it.isNotBlank() },
                            latitude = latitude.toDoubleOrNull(),
                            longitude = longitude.toDoubleOrNull(),
                            expectedAttendees = expectedAttendees.toIntOrNull(),
                            coverImage = coverImageUrl,
                            budget = budget.toDoubleOrNull()
                        )
                        viewModel.createEvent(request)
                    },
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(56.dp),
                    shape = RoundedCornerShape(16.dp),
                    colors = ButtonDefaults.buttonColors(containerColor = PrimaryPink),
                    enabled = eventName.isNotBlank() && eventDate.isNotBlank() && startTime.isNotBlank() && !isUploading
                ) {
                    if (actionState is EventActionUiState.Loading || isUploading) {
                        CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                    } else {
                        Text(if (eventId == null) "Create Event" else "Update Event", fontSize = 18.sp)
                    }
                }
                if (actionState is EventActionUiState.Error) {
                    Text(
                        text = (actionState as EventActionUiState.Error).message,
                        color = Color.Red,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }
        }
    }
}

@Composable
fun defaultTextFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = PrimaryPink,
    unfocusedBorderColor = Color.Gray,
    focusedLabelColor = PrimaryPink,
    unfocusedLabelColor = Color.Gray,
    focusedTextColor = Color.White,
    unfocusedTextColor = Color.White
)