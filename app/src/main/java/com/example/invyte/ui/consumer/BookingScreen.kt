package com.example.invyte.ui.consumer

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Build
import androidx.compose.material.icons.filled.CalendarToday
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.RadioButtonUnchecked
import androidx.compose.material.icons.filled.Remove
import androidx.compose.material.icons.filled.Schedule
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
import androidx.compose.material3.TimePicker
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.material3.rememberTimePickerState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.sp
//import androidx.tv.material3.OutlinedButtonDefaults
//import androidx.wear.compose.material3.TextButton
//import androidx.wear.compose.material3.TextButtonDefaults
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.consumer.BookingViewModel
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
                LocalDate.parse(serviceDate).format(DateTimeFormatter.ofPattern("EEEE, MMM d, yyyy"))
            } catch (e: Exception) { serviceDate }
        } else "Tap to select"
    }

    val displayTime = remember(serviceTime) {
        if (serviceTime.isNotBlank()) {
            try {
                LocalTime.parse(serviceTime).format(DateTimeFormatter.ofPattern("h:mm a"))
            } catch (e: Exception) { serviceTime }
        } else "Tap to select"
    }

    // Compute total estimate
    val totalEstimate = remember(selectedService, quantity) {
        if (selectedService != null) {
            selectedService!!.basePrice * quantity
        } else 0.0
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

    // Date picker dialog
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

    // Time picker dialog
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
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            uiState is BookingUiState.Error && selectedService == null -> {
                Text("Error: ${(uiState as BookingUiState.Error).message}", color = Color.Red, modifier = Modifier.padding(16.dp))
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(horizontal = 16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp),
                    contentPadding = PaddingValues(start = 16.dp, top = 16.dp, end = 16.dp, bottom = 100.dp)
                ) {
                    // ---- Service Summary Card ----
                    item {
                        selectedService?.let { service ->
                            ServiceSummaryCard(
                                service = service,
                                vendorName = viewModel.vendorName.collectAsState().value,
                                quantity = quantity,
                                totalEstimate = totalEstimate
                            )
                        }
                    }

                    // ---- Event Selection Card ----
                    item {
                        EventSelectionCard(
                            events = events,
                            selectedEvent = selectedEvent,
                            onEventSelected = { viewModel.selectEvent(it) }
                        )
                    }

                    // ---- Date & Time Card ----
                    item {
                        DateTimeCard(
                            displayDate = displayDate,
                            displayTime = displayTime,
                            onDateClick = { showDatePicker = true },
                            onTimeClick = { showTimePicker = true }
                        )
                    }

                    // ---- Quantity & Special Requests Card ----
                    item {
                        DetailsCard(
                            quantity = quantity,
                            onQuantityChange = { viewModel.updateQuantity(it) },
                            specialRequests = specialRequests,
                            onSpecialRequestsChange = { viewModel.updateSpecialRequests(it) }
                        )
                    }

                    // ---- Price Breakdown (optional) ----
                    item {
                        if (selectedService != null) {
                            PriceBreakdownCard(
                                service = selectedService!!,
                                quantity = quantity,
                                totalEstimate = totalEstimate
                            )
                        }
                    }
                }
            }
        }
    }
}

// -------- Service Summary Card --------
@Composable
fun ServiceSummaryCard(service: Service, vendorName: String?, quantity: Int, totalEstimate: Double) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(PrimaryPink.copy(alpha = 0.2f)),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.Build, contentDescription = null, tint = PrimaryPink)
            }
            Spacer(modifier = Modifier.width(12.dp))
            Column(modifier = Modifier.weight(1f)) {
                Text(service.serviceName, style = MaterialTheme.typography.titleMedium, color = Color.White)
                Text("by ${vendorName ?: "Vendor"}", color = Color.Gray, fontSize = 14.sp)
                Text(
                    text = "$${service.basePrice} × $quantity = $${String.format("%.2f", totalEstimate)}",
                    color = PrimaryPink,
                    fontWeight = FontWeight.Bold,
                    fontSize = 16.sp
                )
            }
        }
    }
}

// -------- Event Selection Card --------
@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun EventSelectionCard(
    events: List<Event>,
    selectedEvent: Event?,
    onEventSelected: (Event) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Select Event", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
            Spacer(modifier = Modifier.height(8.dp))
            if (events.isEmpty()) {
                Text("No events available. Please create an event first.", color = Color.Gray)
            } else {
                events.forEach { event ->
                    val isSelected = selectedEvent?.id == event.id
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(12.dp))
                            .background(if (isSelected) PrimaryPink.copy(alpha = 0.2f) else Color.Transparent)
                            .clickable { onEventSelected(event) }
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            if (isSelected) Icons.Default.CheckCircle else Icons.Default.RadioButtonUnchecked,
                            contentDescription = null,
                            tint = if (isSelected) PrimaryPink else Color.Gray
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Column {
                            Text(event.eventName, color = if (isSelected) Color.White else Color.Gray)
                            val formattedDate = remember(event.eventDate) {
                                try {
                                    LocalDate.parse(event.eventDate).format(DateTimeFormatter.ofPattern("MMM d, yyyy"))
                                } catch (e: Exception) { event.eventDate }
                            }
                            Text("$formattedDate at ${event.startTime}", color = Color.Gray, fontSize = 12.sp)
                        }
                    }
                }
            }
        }
    }
}

// -------- Date & Time Card --------
@Composable
fun DateTimeCard(
    displayDate: String,
    displayTime: String,
    onDateClick: () -> Unit,
    onTimeClick: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(6.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Date & Time", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                OutlinedButton(
                    onClick = onDateClick,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = if (displayDate != "Tap to select") Color.White else Color.Gray
                    )
                ) {
                    Icon(Icons.Default.CalendarToday, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(displayDate, maxLines = 4)
                }
                OutlinedButton(
                    onClick = onTimeClick,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = if (displayTime != "Tap to select") Color.White else Color.Gray
                    )
                ) {
                    Icon(Icons.Default.Schedule, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(displayTime, maxLines = 4)
                }
            }
        }
    }
}

// -------- Details Card (Quantity & Special Requests) --------
@Composable
fun DetailsCard(
    quantity: Int,
    onQuantityChange: (Int) -> Unit,
    specialRequests: String,
    onSpecialRequestsChange: (String) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Additional Details", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
            Spacer(modifier = Modifier.height(8.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                IconButton(
                    onClick = { if (quantity > 1) onQuantityChange(quantity - 1) },
                    enabled = quantity > 1
                ) {
                    Icon(Icons.Default.Remove, contentDescription = null, tint = Color.White)
                }
                Text(text = "$quantity", color = Color.White, fontSize = 18.sp, modifier = Modifier.width(40.dp), textAlign = TextAlign.Center)
                IconButton(
                    onClick = { onQuantityChange(quantity + 1) }
                ) {
                    Icon(Icons.Default.Add, contentDescription = null, tint = Color.White)
                }
                Spacer(modifier = Modifier.width(8.dp))
                Text("Qty", color = Color.Gray, fontSize = 14.sp)
            }
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = specialRequests,
                onValueChange = onSpecialRequestsChange,
                label = { Text("Special Requests (optional)", color = Color.Gray) },
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

// -------- Price Breakdown Card --------
@Composable
fun PriceBreakdownCard(service: Service, quantity: Int, totalEstimate: Double) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Price Breakdown", style = MaterialTheme.typography.titleSmall, color = PrimaryPink)
            Spacer(modifier = Modifier.height(8.dp))
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text("Service fee", color = Color.Gray)
                Text("$${String.format("%.2f", service.basePrice * 0.1)}", color = Color.White)
            }
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text("Tax (est.)", color = Color.Gray)
                Text("$${String.format("%.2f", totalEstimate * 0.08)}", color = Color.White)
            }
            Divider(modifier = Modifier.padding(vertical = 8.dp), color = Color.Gray.copy(alpha = 0.3f))
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                Text("Total", color = Color.White, fontWeight = FontWeight.Bold)
                Text("$${String.format("%.2f", totalEstimate * 1.18)}", color = PrimaryPink, fontWeight = FontWeight.Bold)
            }
        }
    }
}