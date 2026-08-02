package com.example.invyte.ui.vendor

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.CreateBookingRequest
import com.example.invyte.data.model.Event
import com.example.invyte.data.model.Service
import kotlinx.coroutines.launch
import com.example.invyte.ui.BookingUiState
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.graphics.Color
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.TimePicker
import androidx.compose.material3.TimePickerDialog
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.wear.compose.material3.TextButton
import androidx.wear.compose.material3.TextButtonDefaults
import com.example.invyte.ui.theme.PrimaryPink
import java.time.LocalDate
import java.time.LocalTime
import java.time.format.DateTimeFormatter

@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingScreen(
    navController: NavController,
    vendorId: Int,
    serviceId: Int,
    viewModel: BookingViewModel = hiltViewModel()
) {
    val uiState: BookingUiState by viewModel.bookingUiState.collectAsState()
    val events by viewModel.userEvents.collectAsState()
    val selectedService by viewModel.selectedService.collectAsState()
    val selectedEvent by viewModel.selectedEvent.collectAsState()
    val serviceDate by viewModel.serviceDate.collectAsState()
    val serviceTime by viewModel.serviceTime.collectAsState()
    val quantity by viewModel.quantity.collectAsState()
    val specialRequests by viewModel.specialRequests.collectAsState()
    val isSubmitting by viewModel.isSubmitting.collectAsState()

    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    var showDatePicker by remember { mutableStateOf(false) }
    var showTimePicker by remember { mutableStateOf(false) }

    val datePickerState = rememberDatePickerState(
        initialSelectedDateMillis = System.currentTimeMillis()
    )
    val timePickerState = rememberTimePickerState(
        initialHour = LocalTime.now().hour,
        initialMinute = LocalTime.now().minute,
        is24Hour = true
    )

    val displayDate = remember(serviceDate) {
        if (serviceDate.isNotBlank()) {
            try {
                LocalDate.parse(serviceDate).format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
            } catch (e: Exception) { serviceDate }
        } else ""
    }

    val displayTime = remember(serviceTime) {
        if (serviceTime.isNotBlank()) {
            try {
                LocalTime.parse(serviceTime).format(DateTimeFormatter.ofPattern("HH:mm"))
            } catch (e: Exception) { serviceTime }
        } else ""
    }

    LaunchedEffect(Unit) {
        viewModel.loadVendorAndService(vendorId, serviceId)
        viewModel.loadUserEvents()
    }

    LaunchedEffect(uiState) {
        when (uiState) {
            is BookingUiState.BookingSuccess -> {
                snackbarHostState.showSnackbar("Booking created successfully!")
                navController.popBackStack()
            }
            is BookingUiState.Error -> {
                snackbarHostState.showSnackbar((uiState as BookingUiState.Error).message)
                viewModel.resetBookingState()
            }
            else -> Unit
        }
    }

    // Date picker
    if (showDatePicker) {
        AlertDialog(
            onDismissRequest = { showDatePicker = false },
            title = { Text("Select Date") },
            text = { DatePicker(state = datePickerState) },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let { millis ->
                            val date = LocalDate.ofEpochDay(millis / 86400000)
                            viewModel.updateDate(date.format(DateTimeFormatter.ISO_LOCAL_DATE))
                        }
                        showDatePicker = false
                    }
                ) { Text("OK", color = PrimaryPink) }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancel", color = Color.Gray)
                }
            }
        )
    }

    // Time picker
    if (showTimePicker) {
        AlertDialog(
            onDismissRequest = { showTimePicker = false },
            title = { Text("Select Time") },
            text = { TimePicker(state = timePickerState) },
            confirmButton = {
                TextButton(
                    onClick = {
                        val hour = timePickerState.hour
                        val minute = timePickerState.minute
                        val time = LocalTime.of(hour, minute)
                        viewModel.updateTime(time.format(DateTimeFormatter.ofPattern("HH:mm")))
                        showTimePicker = false
                    }
                ) { Text("OK", color = PrimaryPink) }
            },
            dismissButton = {
                TextButton(onClick = { showTimePicker = false }) {
                    Text("Cancel", color = Color.Gray)
                }
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("Book Service", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        },
        floatingActionButton = {
            val isEnabled = !isSubmitting && selectedService != null && selectedEvent != null
            FloatingActionButton(
                onClick = {
                    if (!isEnabled) return@FloatingActionButton
                    if (serviceDate.isBlank() || serviceTime.isBlank()) {
                        scope.launch { snackbarHostState.showSnackbar("Please select date and time") }
                        return@FloatingActionButton
                    }
                    viewModel.createBooking(
                        CreateBookingRequest(
                            event_id = selectedEvent!!.id,
                            vendor_service_id = serviceId,
                            service_date = serviceDate,
                            service_time = serviceTime,
                            quantity = quantity,
                            special_requests = specialRequests.takeIf { it.isNotBlank() }
                        )
                    )
                },
                containerColor = if (isEnabled) PrimaryPink else Color.Gray
            ) {
                if (isSubmitting) {
                    CircularProgressIndicator(modifier = Modifier.size(24.dp), color = Color.White)
                } else {
                    Text("Book Now", color = Color.White)
                }
            }
        }
    ) { paddingValues ->
        when {
            uiState is BookingUiState.Loading -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
            }
            uiState is BookingUiState.Error && selectedService == null -> {
                Text("Error: ${(uiState as BookingUiState.Error).message}", color = Color.Red, modifier = Modifier.padding(16.dp))
            }
            else -> {
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(paddingValues).padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    contentPadding = PaddingValues(bottom = 100.dp)
                ) {
                    item {
                        selectedService?.let { service ->
                            ServiceDetailCard(service = service, vendorName = viewModel.vendorName.collectAsState().value)
                        }
                    }
                    item {
                        EventSelector(
                            events = events,
                            selectedEvent = selectedEvent,
                            onEventSelected = { viewModel.selectEvent(it) }
                        )
                    }
                    item {
                        Column {
                            // Date – clickable Box with disabled TextField
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { showDatePicker = true }
                            ) {
                                OutlinedTextField(
                                    value = displayDate,
                                    onValueChange = {},
                                    label = { Text("Service Date") },
                                    enabled = false,
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = PrimaryPink,
                                        unfocusedBorderColor = Color.Gray,
                                        focusedLabelColor = PrimaryPink,
                                        unfocusedLabelColor = Color.Gray,
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        disabledTextColor = Color.White,
                                        disabledBorderColor = Color.Gray,
                                        disabledLabelColor = Color.Gray
                                    )
                                )
                            }
                            Spacer(modifier = Modifier.height(8.dp))
                            // Time – clickable Box
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { showTimePicker = true }
                            ) {
                                OutlinedTextField(
                                    value = displayTime,
                                    onValueChange = {},
                                    label = { Text("Service Time") },
                                    enabled = false,
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = PrimaryPink,
                                        unfocusedBorderColor = Color.Gray,
                                        focusedLabelColor = PrimaryPink,
                                        unfocusedLabelColor = Color.Gray,
                                        focusedTextColor = Color.White,
                                        unfocusedTextColor = Color.White,
                                        disabledTextColor = Color.White,
                                        disabledBorderColor = Color.Gray,
                                        disabledLabelColor = Color.Gray
                                    )
                                )
                            }
                        }
                    }
                    item {
                        OutlinedTextField(
                            value = quantity.toString(),
                            onValueChange = {
                                val newQty = it.toIntOrNull() ?: 1
                                if (newQty >= 1) viewModel.updateQuantity(newQty)
                            },
                            label = { Text("Quantity") },
                            modifier = Modifier.fillMaxWidth(),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = PrimaryPink,
                                unfocusedBorderColor = Color.Gray,
                                focusedLabelColor = PrimaryPink,
                                unfocusedLabelColor = Color.Gray,
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White
                            )
                        )
                    }
                    item {
                        OutlinedTextField(
                            value = specialRequests,
                            onValueChange = { viewModel.updateSpecialRequests(it) },
                            label = { Text("Special Requests (optional)") },
                            modifier = Modifier.fillMaxWidth(),
                            maxLines = 3,
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = PrimaryPink,
                                unfocusedBorderColor = Color.Gray,
                                focusedLabelColor = PrimaryPink,
                                unfocusedLabelColor = Color.Gray,
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White
                            )
                        )
                    }
                }
            }
        }
    }
}

// ---------- Service Detail Card ----------
@Composable
fun ServiceDetailCard(service: Service, vendorName: String?) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(service.serviceName, style = MaterialTheme.typography.titleLarge)
            Text("Vendor: ${vendorName ?: "Unknown"}")
            service.description?.let { Text(it) }
            Text("Price: $${service.basePrice} per ${service.priceUnit}")
            Text("Min duration: ${service.minDurationHours} hours")
            service.maxCapacity?.let { Text("Max capacity: $it") }
        }
    }
}

// ---------- Event Selector (date + time formatted) ----------
@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun EventSelector(
    events: List<Event>,
    selectedEvent: Event?,
    onEventSelected: (Event) -> Unit
) {
    Column {
        Text("Select Event", style = MaterialTheme.typography.titleMedium)
        if (events.isEmpty()) {
            Text("No events available. Please create an event first.")
        } else {
            events.forEach { event ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                        .clickable { onEventSelected(event) },
                    colors = CardDefaults.cardColors(
                        containerColor = if (selectedEvent?.id == event.id)
                            MaterialTheme.colorScheme.primaryContainer
                        else
                            MaterialTheme.colorScheme.surface
                    )
                ) {
                    // Format both date and time for display
                    val formattedDate = remember(event.eventDate) {
                        try {
                            LocalDate.parse(event.eventDate).format(DateTimeFormatter.ofPattern("dd/MM/yyyy"))
                        } catch (e: Exception) { event.eventDate }
                    }
                    val formattedTime = remember(event.startTime) {
                        try {
                            LocalTime.parse(event.startTime).format(DateTimeFormatter.ofPattern("HH:mm"))
                        } catch (e: Exception) { event.startTime }
                    }
                    Text(
                        text = "${event.eventName} ($formattedDate $formattedTime)",
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }
    }
}