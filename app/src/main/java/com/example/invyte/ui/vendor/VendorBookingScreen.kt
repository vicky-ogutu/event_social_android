package com.example.invyte.ui.vendor



import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Booking


import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.sp
import com.example.invyte.ui.theme.PrimaryPink
import java.time.LocalDate
import java.time.format.DateTimeFormatter

@RequiresApi(Build.VERSION_CODES.O)
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

    LaunchedEffect(uiState) {
        when (uiState) {
            is VendorBookingUiState.ActionSuccess -> {
                snackbarHostState.showSnackbar((uiState as VendorBookingUiState.ActionSuccess).message)
                viewModel.resetActionState()
                viewModel.loadBookings()
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
        topBar = {
            TopAppBar(
                title = { Text("Bookings", color = Color.White) },
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
            is VendorBookingUiState.Loading -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is VendorBookingUiState.BookingsLoaded -> {
                val bookings = (uiState as VendorBookingUiState.BookingsLoaded).bookings
                if (bookings.isEmpty()) {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No bookings yet", color = Color.Gray)
                    }
                } else {
                    // Group bookings by date
                    val grouped = bookings.groupBy { it.service_date }
                    LazyColumn(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(paddingValues)
                            .background(Color(0xFF121212)),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        grouped.keys.sorted().forEach { date ->
                            item {
                                // Date header
                                val formattedDate = try {
                                    val instant = java.time.Instant.parse(date) // parse ISO timestamp
                                    val localDate = instant.atZone(java.time.ZoneId.systemDefault()).toLocalDate()
                                    localDate.format(DateTimeFormatter.ofPattern("EEEE, MMM d, yyyy"))
                                } catch (e: Exception) {
                                    date // fallback
                                }
                                Text(
                                    text = formattedDate,
                                    color = Color.White,
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 16.sp,
                                    modifier = Modifier.padding(bottom = 8.dp)
                                )
                            }
                            items(grouped[date] ?: emptyList()) { booking ->
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
            }
            is VendorBookingUiState.Error -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${(uiState as VendorBookingUiState.Error).message}", color = Color.Red)
                }
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
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "#${booking.booking_reference}",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
                BookingStatusChip(status = booking.booking_status)
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column {
                    Text("Service", color = Color.Gray, fontSize = 12.sp)
                    Text(booking.service_name ?: "N/A", color = Color.White, fontWeight = FontWeight.Medium)
                }
                Column {
                    Text("Event", color = Color.Gray, fontSize = 12.sp)
                    Text(booking.event_name ?: "N/A", color = Color.White, fontWeight = FontWeight.Medium, maxLines = 1, overflow = TextOverflow.Ellipsis)
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Row(
                horizontalArrangement = Arrangement.SpaceBetween,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column {
                    Text("Quantity", color = Color.Gray, fontSize = 12.sp)
                    Text("${booking.quantity}", color = Color.White)
                }
                Column {
                    Text("Total", color = Color.Gray, fontSize = 12.sp)
                    Text("$${String.format("%.2f", booking.total_amount)}", color = PrimaryPink, fontWeight = FontWeight.Bold)
                }
                Column {
                    Text("Time", color = Color.Gray, fontSize = 12.sp)
                    Text("${booking.service_time}", color = Color.White)
                }
            }

            if (!booking.special_requests.isNullOrBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "📝 ${booking.special_requests}",
                    color = Color.Gray,
                    fontSize = 12.sp,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Action buttons
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                modifier = Modifier.fillMaxWidth()
            ) {
                when (booking.booking_status) {
                    "pending" -> {
                        Button(
                            onClick = onConfirm,
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFF4CAF50)),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Confirm")
                        }
                        Button(
                            onClick = onReject,
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE53935)),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Reject")
                        }
                    }
                    "confirmed" -> {
                        Button(
                            onClick = onComplete,
                            colors = ButtonDefaults.buttonColors(containerColor = PrimaryPink),
                            modifier = Modifier.fillMaxWidth()
                        ) {
                            Text("Complete Service")
                        }
                    }
                    else -> Unit
                }
            }
        }
    }
}

@Composable
fun BookingStatusChip(status: String) {
    val (color, label) = when (status) {
        "pending" -> Color(0xFFFFC107) to "Pending"
        "confirmed" -> Color(0xFF4CAF50) to "Confirmed"
        "completed" -> Color(0xFF2196F3) to "Completed"
        "cancelled" -> Color(0xFFE53935) to "Cancelled"
        else -> Color.Gray to status
    }
    Surface(
        shape = RoundedCornerShape(12.dp),
        color = color.copy(alpha = 0.2f),
        modifier = Modifier.padding(horizontal = 4.dp)
    ) {
        Text(
            text = label,
            color = color,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}