package com.example.invyte.ui.vendor

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.NavigationBarItemDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorHomeScreen(
    navController: NavController,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val profileState by viewModel.vendorProfileState.collectAsState()
    var hasCheckedProfile by remember { mutableStateOf(false) }
    var showCreateProfile by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        viewModel.getVendorProfile()
    }

    LaunchedEffect(profileState) {
        if (profileState is VendorProfileUiState.Success || profileState is VendorProfileUiState.Error) {
            hasCheckedProfile = true
            if (profileState is VendorProfileUiState.Error) {
                showCreateProfile = true
            } else {
                showCreateProfile = false
            }
        }
    }

    if (!hasCheckedProfile) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            CircularProgressIndicator()
        }
        return
    }

    if (showCreateProfile) {
        Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text("Please complete your vendor profile.", color = Color.White)
                Spacer(modifier = Modifier.height(16.dp))
                Button(
                    onClick = { navController.navigate("vendor_profile") },
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
                ) {
                    Text("Set Up Profile")
                }
            }
        }
        return
    }

    // Normal vendor home with tabs
    val tabs = listOf("Dashboard", "Services", "Portfolio")
    var selectedTab by remember { mutableStateOf(0) }

    Scaffold(
        bottomBar = {
            NavigationBar(
                containerColor = Color(0xFF1A1A1A),
                contentColor = Color.White
            ) {
                tabs.forEachIndexed { index, title ->
                    NavigationBarItem(
                        icon = { Icon(Icons.Default.Home, contentDescription = title) },
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
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        }
    ) { paddingValues ->
        when (selectedTab) {
            0 -> VendorDashboardContent(paddingValues, navController)
            1 -> ServicesScreen(navController) // but we need to embed it without Scaffold
            2 -> PortfolioScreen(navController)
        }
    }
}

@Composable
fun VendorDashboardContent(paddingValues: PaddingValues, navController: NavController) {
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
                            onClick = { navController.navigate("services") },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Manage Services")
                        }
                        Button(
                            onClick = { navController.navigate("portfolio") },
                            colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63)),
                            modifier = Modifier.weight(1f)
                        ) {
                            Text("Portfolio")
                        }
                    }
                }
            }
        }
        // More stats, etc.
    }
}