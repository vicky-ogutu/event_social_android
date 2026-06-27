package com.example.invyte.ui.dashboard

import androidx.compose.foundation.background
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Event
import com.example.invyte.ui.auth.AuthViewModel
import com.example.invyte.ui.event.EventViewModel
import com.example.invyte.ui.event.EventsUiState
import com.example.invyte.ui.vendor.VendorProfileUiState
import com.example.invyte.ui.vendor.VendorViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorHomeScreen(
    navController: NavController,
    vendorViewModel: VendorViewModel = hiltViewModel(),
    eventViewModel: EventViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val profileState by vendorViewModel.vendorProfileState.collectAsState()
    val myEventsState by eventViewModel.myEventsState.collectAsState()
    var hasCheckedProfile by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        vendorViewModel.getVendorProfile()
        eventViewModel.getMyEvents()
    }

    LaunchedEffect(profileState) {
        if (profileState is VendorProfileUiState.Success || profileState is VendorProfileUiState.Error) {
            hasCheckedProfile = true
        }
    }

    if (!hasCheckedProfile) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    if (profileState is VendorProfileUiState.Error) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Please set up your vendor profile first.", color = Color.White)
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { navController.navigate("vendor_profile") },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
                ) {
                    Text("Create Profile")
                }
            }
        }
        return
    }

    // Tabs for Vendor
    val tabs = listOf("Dashboard", "My Events")
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
                    IconButton(onClick = { navController.navigate("profile") }) {
                        Icon(Icons.Default.Person, contentDescription = "Profile", tint = Color.White)
                    }
                    IconButton(onClick = { navController.navigate("create_event") }) {
                        Icon(Icons.Default.Add, contentDescription = "Create Event", tint = Color.White)
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
        when (selectedTab) {
            0 -> VendorDashboardContent(paddingValues, navController, vendorViewModel)
            1 -> {
                // My Events (vendor's own events)
                when (myEventsState) {
                    is EventsUiState.Loading -> {
                        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                            CircularProgressIndicator()
                        }
                    }
                    is EventsUiState.Success -> {
                        val events = (myEventsState as EventsUiState.Success).events
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
                                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                                        Text("You haven't created any events yet.", color = Color.Gray)
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
                            Text("Error: ${(myEventsState as EventsUiState.Error).message}", color = Color.Red)
                        }
                    }
                    else -> Unit
                }
            }
        }
    }
}

@Composable
fun VendorDashboardContent(
    paddingValues: PaddingValues,
    navController: NavController,
    viewModel: VendorViewModel
) {
    // Quick stats or actions
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
            .padding(paddingValues)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        item {
            Text("Welcome to your Vendor Dashboard", style = MaterialTheme.typography.titleLarge, color = Color.White)
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
                }
            }
        }
        // You can add more stats here
    }
}