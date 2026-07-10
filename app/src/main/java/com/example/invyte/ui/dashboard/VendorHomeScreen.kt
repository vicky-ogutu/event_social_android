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

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorHomeScreen(
    navController: NavController,
    vendorViewModel: VendorViewModel = hiltViewModel(),
    eventViewModel: EventViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val coroutineScope = rememberCoroutineScope()

    // Get the stored user from AuthViewModel's repository
    val authRepository = authViewModel.repository
    val currentUser by authRepository.getUser().collectAsState(initial = null)

    // State for my events
    val myEventsState by eventViewModel.myEventsState.collectAsState()

    // Track if we've finished checking the profile
    var hasCheckedProfile by remember { mutableStateOf(false) }

    // Fetch events on load
    LaunchedEffect(Unit) {
        eventViewModel.getMyEvents()
    }

    // Wait for user data to be loaded
    LaunchedEffect(currentUser) {
        if (currentUser != null) {
            hasCheckedProfile = true
        }
    }

    // Show loading indicator while checking
    if (!hasCheckedProfile || currentUser == null) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    // Determine if vendor profile exists (based on stored user data)
    val hasVendorProfile = currentUser!!.vendor != null &&
            !currentUser!!.vendor!!.businessName.isNullOrBlank()

    // If no vendor profile, show a prompt to create one + logout button
    if (!hasVendorProfile) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = "Please set up your vendor profile first.",
                    color = Color.White,
                    style = MaterialTheme.typography.titleMedium
                )
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { navController.navigate("vendor_profile") },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Text("Create Profile", color = Color.White)
                }
                Spacer(modifier = Modifier.height(12.dp))
                // ✅ NEW: Logout button
                Button(
                    onClick = {
                        coroutineScope.launch {
                            authViewModel.clearSession()
                            navController.navigate("login") {
                                popUpTo(0) { inclusive = true }
                            }
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = Color.Red),
                    shape = RoundedCornerShape(16.dp)
                ) {
                    Icon(Icons.Default.Logout, contentDescription = null, tint = Color.White)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Logout", color = Color.White)
                }
            }
        }
        return
    }

    // ---------- Vendor Dashboard with Tabs ----------
    val tabs = listOf("Dashboard", "My Events", "Services", "Portfolio")
    var selectedTab by remember { mutableStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = Color(0xFF1A1A1A),
                contentColor = Color.White
            ) {
                tabs.forEachIndexed { index, title ->
                    NavigationBarItem(
                        icon = {
                            when (index) {
                                0 -> Icon(Icons.Default.Home, contentDescription = title)
                                1 -> Icon(Icons.Default.Event, contentDescription = title)
                                2 -> Icon(Icons.Default.List, contentDescription = title)
                                3 -> Icon(Icons.Default.Image, contentDescription = title)
                            }
                        },
                        label = { Text(title) },
                        selected = selectedTab == index,
                        onClick = { selectedTab = index },
                        colors = NavigationBarItemDefaults.colors(
                            selectedIconColor = Color(0xFFE91E63),
                            unselectedIconColor = Color.Gray
                        )
                    )
                }
            }
        },
        topBar = {
            TopAppBar(
                title = { Text("Vendor Dashboard", color = Color.White) },
                actions = {
                    // Profile
                    IconButton(onClick = { navController.navigate("profile") }) {
                        Icon(Icons.Default.Person, contentDescription = "Profile", tint = Color.White)
                    }
                    // Create Event
                    IconButton(onClick = { navController.navigate("create_event") }) {
                        Icon(Icons.Default.Add, contentDescription = "Create Event", tint = Color.White)
                    }
                    // Logout
                    IconButton(
                        onClick = {
                            coroutineScope.launch {
                                authViewModel.clearSession()
                                navController.navigate("login") {
                                    popUpTo(0) { inclusive = true }
                                }
                            }
                        }
                    ) {
                        Icon(Icons.Default.Logout, contentDescription = "Logout", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        when (selectedTab) {
            0 -> VendorDashboardContent(paddingValues, navController)
            1 -> MyEventsContent(paddingValues, navController, myEventsState)
            2 -> ServicesScreen(navController, paddingValues)   // ← add paddingValues
            3 -> PortfolioScreen(navController, paddingValues) // ← add paddingValues
        }
    }
}

// ---------- Dashboard Tab ----------
@Composable
fun VendorDashboardContent(
    paddingValues: PaddingValues,
    navController: NavController
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
            .padding(paddingValues)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text(
                text = "Welcome to your Vendor Dashboard",
                style = MaterialTheme.typography.titleLarge,
                color = Color.White
            )
        }
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(16.dp),
                colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
            ) {
                Column(modifier = Modifier.padding(16.dp)) {
                    Text("Quick Actions", color = Color.White, style = MaterialTheme.typography.titleMedium)
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        Button(
                            onClick = { navController.navigate("create_event") },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                            modifier = Modifier.weight(1f)
                        ) {
                            Icon(Icons.Default.Add, contentDescription = null)
                            Spacer(modifier = Modifier.width(4.dp))
                            Text("Create Event")
                        }
                        Button(
                            onClick = { navController.navigate("services") },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Services")
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(
                        onClick = { navController.navigate("portfolio") },
                        colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Text("Portfolio")
                    }
                }
            }
        }
        // Add more stats (total events, revenue, etc.)
    }
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


// ---------- Reusable Event Card (same as Consumer) ----------
