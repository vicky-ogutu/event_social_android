package com.example.invyte.ui.dashboard

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.material3.TextFieldDefaults.colors
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.ui.auth.AuthViewModel
import com.example.invyte.ui.event.EventViewModel
import com.example.invyte.ui.event.EventsUiState
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import com.example.invyte.ui.common.EventCard
import com.example.invyte.ui.consumer.LivestreamListScreen
import com.example.invyte.ui.event.MyEventsScreen
import com.example.invyte.ui.vendor.ConversationListScreen
import com.example.invyte.ui.consumer.VendorListScreen


@RequiresApi(Build.VERSION_CODES.O)
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConsumerHomeScreen(
    navController: NavController,
    viewModel: EventViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val eventsState by viewModel.eventsState.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    val coroutineScope = rememberCoroutineScope()

    // Selected tab index (0=Home, 1=Events, 2=My Events, 3=Messages)
    var selectedTab by remember { mutableStateOf(0) }

    // Load events when the Events tab is selected
    LaunchedEffect(selectedTab) {
        if (selectedTab == 1) {
            viewModel.listEvents(search = searchQuery.takeIf { it.isNotBlank() })
        }
    }

    Scaffold(
//        topBar = {
//            TopAppBar(
//                title = {
//                    Text(
//                        when (selectedTab) {
//                            0 -> "Vendors"
//                            1 -> "Events"
//                            2 -> "My Events"
//                            else -> "Messages"
//                        },
//                        color = Color.White
//                    )
//                },
//                actions = {
//                    IconButton(onClick = { navController.navigate("profile") }) {
//                        Icon(Icons.Default.Person, contentDescription = "Profile", tint = Color.White)
//                    }
//                    IconButton(onClick = {
//                        coroutineScope.launch {
//                            authViewModel.logout()
//                            navController.navigate("login") {
//                                popUpTo(0) { inclusive = true }
//                            }
//                        }
//                    }) {
//                        Icon(Icons.Default.Logout, contentDescription = "Logout", tint = Color.White)
//                    }
//                },
//                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
//            )
//        },
        bottomBar = {
            NavigationBar(
                containerColor = Color(0xFF1A1A1A),
                contentColor = Color.White
            ) {
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Home, contentDescription = "Home") },
                    label = { Text("Home") },
                    selected = selectedTab == 0,
                    onClick = { selectedTab = 0 },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFFE91E63),
                        unselectedIconColor = Color.Gray
                    )
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Search, contentDescription = "Events") },
                    label = { Text("Events") },
                    selected = selectedTab == 1,
                    onClick = { selectedTab = 1 },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFFE91E63),
                        unselectedIconColor = Color.Gray
                    )
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Event, contentDescription = "My Events") },
                    label = { Text("My Events") },
                    selected = selectedTab == 2,
                    onClick = { selectedTab = 2 },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFFE91E63),
                        unselectedIconColor = Color.Gray
                    )
                )
                NavigationBarItem(
                    icon = { Icon(Icons.Default.Message, contentDescription = "Messages") },
                    label = { Text("Messages") },
                    selected = selectedTab == 3,
                    onClick = { selectedTab = 3 },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFFE91E63),
                        unselectedIconColor = Color.Gray
                    )
                )

                NavigationBarItem(
                    icon = { Icon(Icons.Default.LiveTv, contentDescription = "Live") },
                    label = { Text("Live") },
                    selected = selectedTab == 4,
                    onClick = { selectedTab = 4 },
                    colors = NavigationBarItemDefaults.colors(
                        selectedIconColor = Color(0xFFE91E63),
                        unselectedIconColor = Color.Gray
                    )
                )
            }
        },
        floatingActionButton = {
            // Show FAB on Events (1) and My Events (2) tabs
            if (selectedTab == 1 || selectedTab == 2) {
                FloatingActionButton(
                    onClick = { navController.navigate("create_event") },
                    containerColor = PrimaryPink
                ) {
                    Icon(Icons.Default.Add, contentDescription = "Create Event")
                }
            }
        }
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
                .padding(paddingValues)
        ) {
            when (selectedTab) {
                0 -> VendorListScreen(navController)  // Home → Vendors
                1 -> EventsListContent(
                    searchQuery = searchQuery,
                    onSearchQueryChange = { query ->
                        searchQuery = query
                        viewModel.listEvents(search = query.takeIf { it.isNotBlank() })
                    },
                    eventsState = eventsState,
                    navController = navController
                )
                2 -> MyEventsScreen(navController)    // Reuse existing MyEventsScreen
                3 -> ConversationListScreen(navController) // Messages
                4 -> LivestreamListScreen(navController)
            }
        }
    }
}

// Extracted Events list content with search bar
@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun EventsListContent(
    searchQuery: String,
    onSearchQueryChange: (String) -> Unit,
    eventsState: EventsUiState,
    navController: NavController
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
    ) {
        OutlinedTextField(
            value = searchQuery,
            onValueChange = onSearchQueryChange,
            label = { Text("Search events", color = Color.Gray) },
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray) },
            colors = colors(
                focusedIndicatorColor = PrimaryPink,
                unfocusedIndicatorColor = FieldBorder,
                focusedLabelColor = TextWhite,
                unfocusedLabelColor = FieldBorder,
                focusedTextColor = TextWhite,
                unfocusedTextColor = TextWhite
            ),
            shape = RoundedCornerShape(16.dp)
        )

        when (eventsState) {
            is EventsUiState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is EventsUiState.Success -> {
                val events = eventsState.events
                if (events.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No events found", color = Color.Gray)
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
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
                    Text("Error: ${eventsState.message}", color = Color.Red)
                }
            }
            else -> Unit
        }
    }
}
