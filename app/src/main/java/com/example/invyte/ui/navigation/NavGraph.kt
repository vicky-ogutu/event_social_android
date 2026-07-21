package com.example.invyte.ui.navigation

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.invyte.ui.auth.AuthViewModel
import com.example.invyte.ui.auth.LoginScreen
import com.example.invyte.ui.auth.RegisterScreen
import com.example.invyte.ui.dashboard.ConsumerHomeScreen
import com.example.invyte.ui.dashboard.VendorHomeScreen
import com.example.invyte.ui.event.EventCreateScreen
import com.example.invyte.ui.event.EventDetailScreen
import com.example.invyte.ui.event.MyEventsScreen
import com.example.invyte.ui.profile.ProfileScreen
import com.example.invyte.ui.vendor.BookingScreen
import com.example.invyte.ui.vendor.ChatScreen
import com.example.invyte.ui.vendor.PortfolioScreen
import com.example.invyte.ui.vendor.ServicesScreen
import com.example.invyte.ui.vendor.SocialFeedScreen
import com.example.invyte.ui.vendor.VendorBookingScreen
import com.example.invyte.ui.vendor.VendorDetailScreen
import com.example.invyte.ui.vendor.VendorListScreen
import com.example.invyte.ui.vendor.VendorProfileScreen
import kotlinx.coroutines.flow.firstOrNull

@RequiresApi(Build.VERSION_CODES.O)
@Composable
fun NavGraph(
    viewModel: AuthViewModel = hiltViewModel()
) {
    val navController = rememberNavController()
    var isLoading by remember { mutableStateOf(true) }
    var startDestination by remember { mutableStateOf<String?>(null) }

    // Check token once on first composition
    LaunchedEffect(Unit) {
        val token = viewModel.repository.getToken().firstOrNull()
        if (token != null) {
            val userType = viewModel.repository.getUserType().firstOrNull() ?: "consumer"
            val dashboard = when (userType) {
                "vendor" -> "vendor_home"
                else -> "consumer_home"
            }
            startDestination = "dashboard/$dashboard"
        } else {
            startDestination = "login"
        }
        isLoading = false
    }

    // Show loading indicator while checking token
    if (isLoading) {
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212)),
            contentAlignment = Alignment.Center
        ) {
            CircularProgressIndicator()
        }
        return
    }

    // Once we have a destination, render NavHost
    NavHost(
        navController = navController,
        startDestination = startDestination ?: "login"
    ) {
        composable("login") {
            LoginScreen(navController)
        }
        composable("register") {
            RegisterScreen(navController)
        }

        composable(
            route = "dashboard/{dashboardName}",
            arguments = listOf(navArgument("dashboardName") { type = NavType.StringType })
        ) { backStackEntry ->
            val dashboardName = backStackEntry.arguments?.getString("dashboardName") ?: "consumer_home"
            when {
                dashboardName.startsWith("vendor") -> VendorHomeScreen(navController)
                else -> ConsumerHomeScreen(navController)
            }
        }

        composable("profile") {
            ProfileScreen(navController)
        }
        composable("vendor_profile") {
            VendorProfileScreen(navController, isEdit = false)
        }
        composable("vendor_profile_edit") {
            VendorProfileScreen(navController, isEdit = true)
        }
        composable("services") {
            ServicesScreen(navController)
        }
        composable("portfolio") {
            PortfolioScreen(navController)
        }

        composable("my_events") {
            MyEventsScreen(navController)
        }
        composable("event_detail/{eventId}") { backStackEntry ->
            val eventId = backStackEntry.arguments?.getString("eventId")?.toIntOrNull() ?: 0
            EventDetailScreen(navController, eventId)
        }
        composable("create_event") {
            EventCreateScreen(navController)
        }
        composable("edit_event/{eventId}") { backStackEntry ->
            val eventId = backStackEntry.arguments?.getString("eventId")?.toIntOrNull()
            EventCreateScreen(navController, eventId)
        }

        composable("vendor_list") { VendorListScreen(navController) }
        composable("vendor_detail/{vendorId}") { backStackEntry ->
            val id = backStackEntry.arguments?.getString("vendorId")?.toIntOrNull() ?: 0
            VendorDetailScreen(navController, id)
        }
        composable("booking/{vendorId}/{serviceId}") { backStackEntry ->
            val vendorId = backStackEntry.arguments?.getString("vendorId")?.toIntOrNull() ?: 0
            val serviceId = backStackEntry.arguments?.getString("serviceId")?.toIntOrNull() ?: 0
            BookingScreen(navController, vendorId, serviceId)
        }
        composable("social_feed") { SocialFeedScreen() }
        composable("social_feed_event/{eventId}") { backStackEntry ->
            val eventId = backStackEntry.arguments?.getString("eventId")?.toIntOrNull()
            SocialFeedScreen(eventId)
        }
        composable("chat/{eventId}") { backStackEntry ->
            val eventId = backStackEntry.arguments?.getString("eventId")?.toIntOrNull() ?: 0
            ChatScreen(eventId)
        }
        composable("livestream/{livestreamId}") { backStackEntry ->
            val id = backStackEntry.arguments?.getString("livestreamId")?.toIntOrNull() ?: 0
            // LivestreamPlayerScreen(id)
        }

        composable("vendor_bookings") {
            VendorBookingScreen(navController)
        }
        composable("vendor_bookings") {
            VendorBookingScreen(navController)
        }

    }
}
