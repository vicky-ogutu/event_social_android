package com.example.invyte.ui.vendor

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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingScreen(
    navController: NavController,
    vendorId: Int,
    serviceId: Int,
    viewModel: BookingViewModel = hiltViewModel()
) {
    // Explicit type to fix inference
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

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(title = { Text("Book Service") },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },

                )
        },
        floatingActionButton = {
            if (selectedService != null && selectedEvent != null) {
                FloatingActionButton(
                    onClick = {
                        if (isSubmitting) return@FloatingActionButton
                        if (serviceDate.isBlank() || serviceTime.isBlank()) {
                            scope.launch {
                                snackbarHostState.showSnackbar("Please select date and time")
                            }
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
                    modifier = Modifier
                ) {
                    if (isSubmitting) {
                        CircularProgressIndicator(modifier = Modifier.size(24.dp))
                    } else {
                        Text("Book Now")
                    }
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
                Text("Error: ${(uiState as BookingUiState.Error).message}")
            }
            else -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(paddingValues)
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Service details
                    item {
                        selectedService?.let { service ->
                            ServiceDetailCard(service = service, vendorName = viewModel.vendorName.collectAsState().value)
                        }
                    }

                    // Event selection
                    item {
                        EventSelector(
                            events = events,
                            selectedEvent = selectedEvent,
                            onEventSelected = { viewModel.selectEvent(it) }
                        )
                    }

                    // Date and Time pickers
                    item {
                        Column {
                            OutlinedTextField(
                                value = serviceDate,
                                onValueChange = {},
                                label = { Text("Service Date") },
                                readOnly = true,
                                trailingIcon = {
                                    TextButton(onClick = {
                                        // Show date picker dialog
                                    }) {
                                        Text("Pick Date")
                                    }
                                },
                                modifier = Modifier.fillMaxWidth()
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            OutlinedTextField(
                                value = serviceTime,
                                onValueChange = {},
                                label = { Text("Service Time") },
                                readOnly = true,
                                trailingIcon = {
                                    TextButton(onClick = {
                                        // Show time picker dialog
                                    }) {
                                        Text("Pick Time")
                                    }
                                },
                                modifier = Modifier.fillMaxWidth()
                            )
                        }
                    }

                    // Quantity
                    item {
                        OutlinedTextField(
                            value = quantity.toString(),
                            onValueChange = {
                                val newQty = it.toIntOrNull() ?: 1
                                if (newQty >= 1) viewModel.updateQuantity(newQty)
                            },
                            label = { Text("Quantity") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }

                    // Special requests
                    item {
                        OutlinedTextField(
                            value = specialRequests,
                            onValueChange = { viewModel.updateSpecialRequests(it) },
                            label = { Text("Special Requests (optional)") },
                            modifier = Modifier.fillMaxWidth(),
                            maxLines = 3
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun ServiceDetailCard(service: Service, vendorName: String?) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(service.serviceName, style = MaterialTheme.typography.titleLarge)
            Text("Vendor: ${vendorName ?: "Unknown"}")
            service.description?.let { Text(it) }
            Text("Price: $${service.basePrice} per ${service.priceUnit}")
            Text("Min duration: ${service.minDurationHours} hours")
            service.maxCapacity?.let {
                Text("Max capacity: $it")
            }
        }
    }
}

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
                    Text(
                        text = "${event.eventName} (${event.eventDate})",
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }
    }
}