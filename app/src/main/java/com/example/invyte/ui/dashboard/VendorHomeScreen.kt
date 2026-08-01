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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
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
import kotlinx.coroutines.coroutineScope

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
    bookingViewModel: VendorBookingViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val myEventsState by eventViewModel.eventsState.collectAsState()
    val coroutineScope = rememberCoroutineScope()

    // Load events for the vendor
    LaunchedEffect(Unit) {
        eventViewModel.getMyEvents()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Vendor Dashboard", color = Color.White) },
                actions = {
                    IconButton(onClick = { navController.navigate("profile") }) {
                        Icon(Icons.Default.Person, contentDescription = "Profile", tint = Color.White)
                    }
                    // 👇 NEW: Logout button
                    IconButton(onClick = {
                        coroutineScope.launch {
                            authViewModel.logout()
                            navController.navigate("login") {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    }) {
                        Icon(Icons.Default.Logout, contentDescription = "Logout", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
                .padding(paddingValues)
        ) {
            // Dashboard Cards
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Grid of 5 cards (2 columns + 1 full-width)
                item {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        DashboardCard(
                            icon = Icons.Default.Event,
                            title = "Events",
                            description = "Manage your events",
                            onClick = { navController.navigate("my_events") },
                            modifier = Modifier.weight(1f)
                        )
                        DashboardCard(
                            icon = Icons.Default.Build,
                            title = "Services",
                            description = "Add / edit services",
                            onClick = { navController.navigate("services") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                item {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        DashboardCard(
                            icon = Icons.Default.PhotoLibrary,
                            title = "Portfolio",
                            description = "Showcase your work",
                            onClick = { navController.navigate("portfolio") },
                            modifier = Modifier.weight(1f)
                        )
                        DashboardCard(
                            icon = Icons.Default.Bookmark,
                            title = "Bookings",
                            description = "View and manage bookings",
                            onClick = { navController.navigate("vendor_bookings") },
                            modifier = Modifier.weight(1f)
                        )
                    }
                }
                item {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        DashboardCard(
                            icon = Icons.Default.Chat,
                            title = "Messages",
                            description = "Chat with clients",
                            onClick = { navController.navigate("messages") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun DashboardCard(
    icon: ImageVector,
    title: String,
    description: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .height(120.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color(0xFF2A2A2A)
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                tint = Color(0xFFE91E63),
                modifier = Modifier.size(48.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = title,
                color = Color.White,
                fontWeight = FontWeight.Bold,
                fontSize = 16.sp
            )
            Text(
                text = description,
                color = Color.Gray,
                fontSize = 12.sp,
                textAlign = TextAlign.Center,
                maxLines = 1
            )
        }
    }
}



// ---------- Reusable Event Card (same as Consumer) ----------
