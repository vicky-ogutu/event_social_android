package com.example.invyte.ui.dashboard
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.Event
import com.example.invyte.ui.auth.AuthViewModel
import com.example.invyte.ui.event.EventViewModel
import com.example.invyte.ui.event.EventsUiState
import com.example.invyte.ui.vendor.ServicesScreen
import com.example.invyte.ui.vendor.PortfolioScreen
import com.example.invyte.ui.vendor.VendorViewModel
import com.example.invyte.ui.vendor.VendorProfileUiState
import kotlinx.coroutines.launch
import com.example.invyte.ui.common.EventCard
import com.example.invyte.ui.vendor.ConversationListScreen
import com.example.invyte.ui.vendor.VendorBookingCard
import com.example.invyte.ui.vendor.VendorBookingUiState
import com.example.invyte.ui.vendor.VendorBookingViewModel

// Tab enum
enum class VendorTab(val title: String) {
    EVENTS("Events"),
    SERVICES("Services"),
    PORTFOLIO("Portfolio"),
    BOOKINGS("Bookings"),
    MESSAGES("Messages")
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorHomeScreen(
    navController: NavController,
    eventViewModel: EventViewModel = hiltViewModel(),
    bookingViewModel: VendorBookingViewModel = hiltViewModel()
) {
    val myEventsState by eventViewModel.eventsState.collectAsState()
    var selectedTab by remember { mutableStateOf(VendorTab.EVENTS) }
    val tabs = VendorTab.values()

    // Load events for the vendor when the Events tab is selected
    LaunchedEffect(Unit) {
        //eventViewModel.listMyEvents()
        eventViewModel.getMyEvents()
        // you need to implement this in EventViewModel
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Vendor Dashboard") },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFF1A1A1A),
                    titleContentColor = Color.White
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
                .padding(paddingValues)
        ) {
            // Tab Row
            TabRow(
                selectedTabIndex = selectedTab.ordinal,
                containerColor = Color(0xFF1A1A1A),
                contentColor = Color.White
            ) {
                tabs.forEachIndexed { index, tab ->
                    Tab(
                        selected = selectedTab.ordinal == index,
                        onClick = { selectedTab = tab },
                        text = { Text(tab.title, color = Color.White) },
                        selectedContentColor = Color(0xFFE91E63),
                        unselectedContentColor = Color.Gray
                    )
                }
            }

            // Content based on selected tab
            when (selectedTab) {
                VendorTab.EVENTS -> MyEventsContent(
                    paddingValues = PaddingValues(0.dp),
                    navController = navController,
                    myEventsState = myEventsState
                )
                VendorTab.SERVICES -> ServicesContent(
                    navController = navController
                )
                VendorTab.PORTFOLIO -> PortfolioContent(
                    navController = navController
                )
                VendorTab.MESSAGES -> MessagesContent(navController)
                VendorTab.BOOKINGS -> VendorBookingScreen(
                    navController = navController,
                    viewModel = bookingViewModel
                )
            }
        }
    }
}

@Composable
fun MessagesContent(navController: NavController) {
    ConversationListScreen(navController)
}

// ---------- My Events Tab ----------
@Composable
fun MyEventsContent(
    paddingValues: PaddingValues,
    navController: NavController,
    myEventsState: EventsUiState
) {
    when (myEventsState) {
        is EventsUiState.Loading -> {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator()
            }
        }
        is EventsUiState.Success -> {
            val events = myEventsState.events
            LazyColumn(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color(0xFF121212))
                    .padding(paddingValues)
                    .padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                if (events.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier.fillMaxWidth(),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "You haven't created any events yet.",
                                color = Color.Gray
                            )
                        }
                    }
                } else {
                    items(events) { event ->
                        EventCard(
                            event = event,
                            onClick = { navController.navigate("event_detail/${event.id}") }
                        )
                    }
                }
            }
        }
        is EventsUiState.Error -> {
            Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                Text("Error: ${myEventsState.message}", color = Color.Red)
            }
        }
        else -> Unit
    }
}

// ---------- Services Tab ----------
@Composable
fun ServicesContent(navController: NavController) {
    // You already have ServicesScreen, so we just use it
    // Or you can embed it directly
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Button(onClick = { navController.navigate("services") }) {
            Text("Manage Services")
        }
    }
}

// ---------- Portfolio Tab ----------
@Composable
fun PortfolioContent(navController: NavController) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Button(onClick = { navController.navigate("portfolio") }) {
            Text("Manage Portfolio")
        }
    }
}

// ---------- Bookings Tab ----------
@Composable
fun VendorBookingScreen(
    navController: NavController,
    viewModel: VendorBookingViewModel = hiltViewModel()
) {
    // This is the screen we created earlier – you can use the full implementation.
    // For brevity, I'll show a simplified version that loads bookings and displays them.
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
        snackbarHost = { SnackbarHost(snackbarHostState) }
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
//            else -> Unit
            else -> {}
        }
    }
}



// ---------- Reusable Event Card (same as Consumer) ----------
