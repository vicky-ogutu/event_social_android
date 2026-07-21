package com.example.invyte.ui.vendor



import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Booking

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorBookingScreen(
    navController: NavController,
    viewModel: VendorBookingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
        viewModel.loadBookings()
    }

    // Show snackbar on action results
    LaunchedEffect(uiState) {
        when (uiState) {
            is VendorBookingUiState.ActionSuccess -> {
                snackbarHostState.showSnackbar((uiState as VendorBookingUiState.ActionSuccess).message)
                viewModel.resetActionState()
                viewModel.loadBookings() // refresh
            }
            is VendorBookingUiState.Error -> {
                snackbarHostState.showSnackbar((uiState as VendorBookingUiState.Error).message)
                viewModel.resetActionState()
            }
            else -> Unit
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = { TopAppBar(title = { Text("My Bookings") }) }
    ) { paddingValues ->
        when (uiState) {
            is VendorBookingUiState.Loading -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is VendorBookingUiState.BookingsLoaded -> {
                val bookings = (uiState as VendorBookingUiState.BookingsLoaded).bookings
                if (bookings.isEmpty()) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No bookings yet")
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.padding(paddingValues),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(bookings) { booking ->
                            VendorBookingCard(
                                booking = booking,
                                onConfirm = { viewModel.confirmBooking(booking.id) },
                                onComplete = { viewModel.completeBooking(booking.id) },
                                onReject = { viewModel.rejectBooking(booking.id) }
                            )
                        }
                    }
                }
            }
            is VendorBookingUiState.Error -> {
                Text("Error: ${(uiState as VendorBookingUiState.Error).message}", modifier = Modifier.padding(16.dp))
            }
            else -> Unit
        }
    }
}

@Composable
fun VendorBookingCard(
    booking: Booking,
    onConfirm: () -> Unit,
    onComplete: () -> Unit,
    onReject: () -> Unit
) {
    Card(modifier = Modifier.fillMaxWidth()) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text("Booking #${booking.booking_reference}", style = MaterialTheme.typography.titleMedium)
            Text("Service: ${booking.service_name ?: "N/A"}")
            Text("Event: ${booking.event_name ?: "N/A"}")
            Text("Date: ${booking.service_date} at ${booking.service_time}")
            Text("Quantity: ${booking.quantity}")
            Text("Total: $${booking.total_amount}")
            Text("Status: ${booking.booking_status}", color = when (booking.booking_status) {
                "pending" -> MaterialTheme.colorScheme.scrim //warning
                "confirmed" -> MaterialTheme.colorScheme.primary
                "completed" -> MaterialTheme.colorScheme.tertiary
                "cancelled" -> MaterialTheme.colorScheme.error
                else -> MaterialTheme.colorScheme.onSurface
            })
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                if (booking.booking_status == "pending") {
                    Button(onClick = onConfirm) { Text("Confirm") }
                    Button(onClick = onReject, colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)) {
                        Text("Reject")
                    }
                }
                if (booking.booking_status == "confirmed") {
                    Button(onClick = onComplete) { Text("Complete") }
                }
            }
        }
    }
}