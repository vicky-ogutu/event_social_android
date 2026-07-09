package com.example.invyte.ui.event

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.material3.TextFieldDefaults.colors
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.EventRequest
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EventCreateScreen(
    navController: NavController,
    eventId: Int? = null, // for editing
    viewModel: EventViewModel = hiltViewModel()
) {
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
    var coverImage by remember { mutableStateOf("") }
    var accessCode by remember { mutableStateOf("") }

    val actionState by viewModel.actionState.collectAsState()

    // If editing, fetch event details (not implemented here for brevity, but you can add)

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
            verticalArrangement = Arrangement.spacedBy(8.dp),
            contentPadding = PaddingValues(vertical = 16.dp)
        ) {
            item {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ){
            OutlinedTextField(
                value = eventName,
                onValueChange = { eventName = it },
                label = { Text("Event Name *", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = eventDescription,
                onValueChange = { eventDescription = it },
                label = { Text("Description", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            Row {
                FilterChip(
                    selected = eventType == "public",
                    onClick = { eventType = "public" },
                    label = { Text("Public", color = Color.White) },
                    modifier = Modifier.weight(1f),
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = Color(0xFFE91E63),
                        disabledSelectedContainerColor = Color.Gray,
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
                        selectedContainerColor = Color(0xFFE91E63),
                        disabledSelectedContainerColor = Color.Gray,
                        selectedLabelColor = Color.White
                    )
                )
            }
            if (eventType == "private") {
                OutlinedTextField(
                    value = accessCode,
                    onValueChange = { accessCode = it },
                    label = { Text("Access Code (optional, auto-generate if empty)", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = eventDate,
                onValueChange = { eventDate = it },
                label = { Text("Event Date (YYYY-MM-DD) *", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = startTime,
                    onValueChange = { startTime = it },
                    label = { Text("Start Time *", color = Color.Gray) },
                    modifier = Modifier.weight(1f),
                    colors = colors(
                        focusedIndicatorColor = PrimaryPink,
                        unfocusedIndicatorColor = FieldBorder,
                        focusedLabelColor = TextWhite,
                        unfocusedLabelColor = FieldBorder,
                        focusedTextColor = TextWhite,
                        unfocusedTextColor = TextWhite
                    )
                )
                OutlinedTextField(
                    value = endTime,
                    onValueChange = { endTime = it },
                    label = { Text("End Time", color = Color.Gray) },
                    modifier = Modifier.weight(1f),
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
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = venueAddress,
                onValueChange = { venueAddress = it },
                label = { Text("Venue Address", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                OutlinedTextField(
                    value = latitude,
                    onValueChange = { latitude = it },
                    label = { Text("Latitude", color = Color.Gray) },
                    modifier = Modifier.weight(1f),
                    colors = colors(
                        focusedIndicatorColor = PrimaryPink,
                        unfocusedIndicatorColor = FieldBorder,
                        focusedLabelColor = TextWhite,
                        unfocusedLabelColor = FieldBorder,
                        focusedTextColor = TextWhite,
                        unfocusedTextColor = TextWhite
                    )
                )
                OutlinedTextField(
                    value = longitude,
                    onValueChange = { longitude = it },
                    label = { Text("Longitude", color = Color.Gray) },
                    modifier = Modifier.weight(1f),
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
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = expectedAttendees,
                onValueChange = { expectedAttendees = it },
                label = { Text("Expected Attendees", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = budget,
                onValueChange = { budget = it },
                label = { Text("Budget", color = Color.Gray) },
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
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = coverImage,
                onValueChange = { coverImage = it },
                label = { Text("Cover Image URL", color = Color.Gray) },
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

            Spacer(modifier = Modifier.height(24.dp))

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
                        coverImage = coverImage.takeIf { it.isNotBlank() },
                        budget = budget.toDoubleOrNull()
                    )
                    viewModel.createEvent(request)
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                enabled = eventName.isNotBlank() && eventDate.isNotBlank() && startTime.isNotBlank()
            ) {
                if (actionState is EventActionUiState.Loading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text(if (eventId == null) "Create Event" else "Update Event", fontSize = 18.sp)
                }
            }

            if (actionState is EventActionUiState.Error) {
                Text(
                    text = (actionState as EventActionUiState.Error).message,
                    color = Color.Red,
                    modifier = Modifier.padding(top = 16.dp)
                )
            }
        }
    }
}}}