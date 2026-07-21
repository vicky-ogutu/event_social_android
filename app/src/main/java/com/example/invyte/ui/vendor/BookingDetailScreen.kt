package com.example.invyte.ui.vendor

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Booking


import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import com.example.invyte.ui.BookingUiState

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookingDetailScreen(
    navController: NavController,
    bookingId: Int,
    viewModel: BookingViewModel = hiltViewModel()
) {
   // val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(Unit) {
       // viewModel.loadBookingDetails(bookingId)
    }

    // Show snackbar on success states
//    LaunchedEffect(uiState) {
//        when (uiState) {
//            is BookingUiState.ConfirmSuccess -> {
//                snackbarHostState.showSnackbar(
//                    (uiState as BookingUiState.ConfirmSuccess).message
//                )
//                viewModel.resetState()
//            }
//            is BookingUiState.CompleteSuccess -> {
//                snackbarHostState.showSnackbar(
//                    (uiState as BookingUiState.CompleteSuccess).message
//                )
//                viewModel.resetState()
//            }
//            else -> Unit
//        }
//    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
//            when (uiState) {
//                is BookingUiState.Loading -> {
//                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
//                        CircularProgressIndicator()
//                    }
//                }
//                is BookingUiState.Success -> {
//                    val booking = (uiState as BookingUiState.Success).booking
//                    BookingDetailContent(
//                        booking = booking,
//                        onConfirm = { viewModel.confirmService(booking.id) },
//                        onComplete = { viewModel.completeBooking(booking.id) }
//                    )
//                }
//                is BookingUiState.Error -> {
//                    Text("Error: ${(uiState as BookingUiState.Error).message}")
//                }
//                else -> Unit
//            }
        }
    }
}

@Composable
fun BookingDetailContent(
    booking: Booking,
    onConfirm: () -> Unit,
    onComplete: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        Text("Booking Reference: ${booking.booking_reference}")
        Text("Status: ${booking.booking_status}")
        Text("Vendor: ${booking.vendor_name ?: "N/A"}")
        // ... more fields

        Button(
            onClick = onConfirm,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Confirm Service")
        }
        Button(
            onClick = onComplete,
            modifier = Modifier.fillMaxWidth()
        ) {
            Text("Complete Booking")
        }
    }
}