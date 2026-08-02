package com.example.invyte.ui.vendor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Logout
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Vendor
import com.example.invyte.ui.auth.AuthViewModel
import com.example.invyte.ui.theme.PrimaryPink
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorListScreen(
    navController: NavController,
    viewModel: VendorListViewModel = hiltViewModel(),
    authViewModel: AuthViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf<String?>(null) }
    var minRating by remember { mutableStateOf<Double?>(null) }
    val scope = rememberCoroutineScope()
    val categories = listOf("Venue", "Catering", "Music & DJ", "Photography", "Furniture", "Lighting", "MC & Host", "Security", "Transportation", "Entertainment")

    LaunchedEffect(Unit) {
        viewModel.loadVendors()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Vendors", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                actions = {
                    IconButton(onClick = {
                        scope.launch {
                            authViewModel.logout()
                            navController.navigate("login") { popUpTo(0) { inclusive = true } }
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
            // Search Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = {
                    searchQuery = it
                    viewModel.loadVendors(search = it.takeIf { it.isNotBlank() }, category = selectedCategory, minRating = minRating)
                },
                label = { Text("Search vendors", color = Color.Gray) },
                leadingIcon = { Icon(Icons.Default.Search, contentDescription = null, tint = Color.Gray) },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 8.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = PrimaryPink,
                    unfocusedBorderColor = Color.Gray,
                    focusedLabelColor = PrimaryPink,
                    unfocusedLabelColor = Color.Gray,
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White
                ),
                shape = RoundedCornerShape(16.dp)
            )

            // Category Filter Chips
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    FilterChip(
                        selected = selectedCategory == null,
                        onClick = {
                            selectedCategory = null
                            viewModel.loadVendors(search = searchQuery.takeIf { it.isNotBlank() }, category = null, minRating = minRating)
                        },
                        label = { Text("All", color = if (selectedCategory == null) Color.White else Color.Gray) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = PrimaryPink,
                            disabledSelectedContainerColor = Color.Gray,
                            selectedLabelColor = Color.White
                        )
                    )
                }
                items(categories) { category ->
                    FilterChip(
                        selected = selectedCategory == category,
                        onClick = {
                            selectedCategory = category
                            viewModel.loadVendors(search = searchQuery.takeIf { it.isNotBlank() }, category = category, minRating = minRating)
                        },
                        label = { Text(category, color = if (selectedCategory == category) Color.White else Color.Gray) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = PrimaryPink,
                            disabledSelectedContainerColor = Color.Gray,
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }

            // Rating Filter
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                listOf(4.0, 3.5, 3.0).forEach { rating ->
                    FilterChip(
                        selected = minRating == rating,
                        onClick = {
                            minRating = if (minRating == rating) null else rating
                            viewModel.loadVendors(search = searchQuery.takeIf { it.isNotBlank() }, category = selectedCategory, minRating = minRating)
                        },
                        label = { Text("⭐ ${rating}+", color = if (minRating == rating) Color.White else Color.Gray) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = PrimaryPink,
                            disabledSelectedContainerColor = Color.Gray,
                            selectedLabelColor = Color.White
                        )
                    )
                }
            }

            // Vendor List
            when (uiState) {
                is VendorListUiState.Loading -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator()
                    }
                }
                is VendorListUiState.Success -> {
                    val data = (uiState as VendorListUiState.Success).data
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(data.data) { vendor ->
                            VendorCard(vendor, onClick = { navController.navigate("vendor_detail/${vendor.id}") })
                        }
                    }
                }
                is VendorListUiState.Error -> {
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("Error: ${(uiState as VendorListUiState.Error).message}", color = Color.Red)
                    }
                }
                else -> Unit
            }
        }
    }
}

@Composable
fun VendorCard(vendor: Vendor, onClick: () -> Unit) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Left accent bar (like Google Calendar)
            Box(
                modifier = Modifier
                    .width(6.dp)
                    .height(56.dp)
                    .clip(RoundedCornerShape(4.dp))
                    .background(PrimaryPink)
            )
            Spacer(modifier = Modifier.width(12.dp))

            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = vendor.business_name,
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White,
                    fontWeight = FontWeight.Bold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "⭐ ${String.format("%.1f", vendor.rating)}",
                        color = Color(0xFFFFC107),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Medium
                    )
                    Text(
                        text = "(${vendor.review_count} reviews)",
                        color = Color.Gray,
                        fontSize = 12.sp
                    )
                    if (vendor.service_category != null) {
                        Surface(
                            shape = RoundedCornerShape(12.dp),
                            color = Color(0xFF333333)
                        ) {
                            Text(
                                text = vendor.service_category!!,
                                color = Color.White,
                                fontSize = 11.sp,
                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 2.dp)
                            )
                        }
                    }
                }
                Row(
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.padding(top = 4.dp)
                ) {
                    Text(
                        text = "💼 ${vendor.completed_jobs} jobs",
                        color = Color.Gray,
                        fontSize = 12.sp
                    )
                    Text(
                        text = "💰 $${String.format("%.0f", vendor.total_earnings)}",
                        color = Color.Gray,
                        fontSize = 12.sp
                    )
                }
            }

            Icon(
                Icons.Default.ChevronRight,
                contentDescription = null,
                tint = Color.Gray,
                modifier = Modifier.size(24.dp)
            )
        }
    }
}