package com.example.invyte.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
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
import kotlinx.coroutines.flow.firstOrNull

@Composable
fun NavGraph(
    viewModel: AuthViewModel = hiltViewModel()
) {
    val navController = rememberNavController()
    val tokenFlow = viewModel.repository.getToken() // exposed via repository
    var startDestination by remember { mutableStateOf("login") }

    LaunchedEffect(Unit) {
        val token = tokenFlow.firstOrNull()
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
    }

    NavHost(
        navController = navController,
        startDestination = startDestination
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
            when (dashboardName) {
                "vendor_home" -> VendorHomeScreen(navController)
                else -> ConsumerHomeScreen(navController)
            }
        }
    }
}