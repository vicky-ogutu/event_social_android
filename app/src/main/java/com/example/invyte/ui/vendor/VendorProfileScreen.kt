package com.example.invyte.ui.vendor
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.VendorProfileRequest
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.material3.TextFieldDefaults.colors
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VendorProfileScreen(
    navController: NavController,
    isEdit: Boolean = false,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val profileState by viewModel.vendorProfileState.collectAsState()
    var businessName by remember { mutableStateOf("") }
    var address by remember { mutableStateOf("") }
    var phone by remember { mutableStateOf("") }
    var description by remember { mutableStateOf("") }

    LaunchedEffect(Unit) {
        if (isEdit) {
            viewModel.getVendorProfile()
        }
    }

    LaunchedEffect(profileState) {
        if (profileState is VendorProfileUiState.Success) {
            val profile = (profileState as VendorProfileUiState.Success).profile
            businessName = profile.businessName
            address = profile.address
            phone = profile.phone
            description = profile.description ?: ""
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(if (isEdit) "Edit Vendor Profile" else "Vendor Setup", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
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
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            OutlinedTextField(
                value = businessName,
                onValueChange = { businessName = it },
                label = { Text("Business Name", color = Color.Gray) },
                modifier = Modifier.fillMaxWidth(),
                colors = colors(
                    focusedIndicatorColor = PrimaryPink,
                    unfocusedIndicatorColor = FieldBorder,
                    focusedLabelColor = TextWhite,
                    unfocusedLabelColor = FieldBorder,
                    focusedTextColor = TextWhite,
                    unfocusedTextColor = TextWhite
                )
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = address,
                onValueChange = { address = it },
                label = { Text("Address", color = Color.Gray) },
                modifier = Modifier.fillMaxWidth(),
                colors = colors(
                    focusedIndicatorColor = PrimaryPink,
                    unfocusedIndicatorColor = FieldBorder,
                    focusedLabelColor = TextWhite,
                    unfocusedLabelColor = FieldBorder,
                    focusedTextColor = TextWhite,
                    unfocusedTextColor = TextWhite
                )
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = phone,
                onValueChange = { phone = it },
                label = { Text("Phone", color = Color.Gray) },
                modifier = Modifier.fillMaxWidth(),
                colors = colors(
                    focusedIndicatorColor = PrimaryPink,
                    unfocusedIndicatorColor = FieldBorder,
                    focusedLabelColor = TextWhite,
                    unfocusedLabelColor = FieldBorder,
                    focusedTextColor = TextWhite,
                    unfocusedTextColor = TextWhite
                )
            )
            Spacer(modifier = Modifier.height(12.dp))
            OutlinedTextField(
                value = description,
                onValueChange = { description = it },
                label = { Text("Description (optional)", color = Color.Gray) },
                modifier = Modifier.fillMaxWidth(),
                colors = colors(
                    focusedIndicatorColor = PrimaryPink,
                    unfocusedIndicatorColor = FieldBorder,
                    focusedLabelColor = TextWhite,
                    unfocusedLabelColor = FieldBorder,
                    focusedTextColor = TextWhite,
                    unfocusedTextColor = TextWhite
                )
            )

            Spacer(modifier = Modifier.height(24.dp))

            Button(
                onClick = {
                    val request = VendorProfileRequest(businessName, address, phone, description.takeIf { it.isNotBlank() })
                    if (isEdit) {
                        viewModel.updateVendorProfile(request)
                    } else {
                        viewModel.createVendorProfile(request)
                    }
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
            ) {
                if (profileState is VendorProfileUiState.Loading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text(if (isEdit) "Update Profile" else "Create Profile", fontSize = 18.sp)
                }
            }

            when (profileState) {
                is VendorProfileUiState.Success -> {
                    Text(
                        text = if (isEdit) "Profile updated successfully!" else "Profile created successfully!",
                        color = Color.Green,
                        modifier = Modifier.padding(top = 16.dp)
                    )
                    LaunchedEffect(Unit) {
                        // Optionally navigate back after success
                        navController.navigateUp()
                    }
                }
                is VendorProfileUiState.Error -> {
                    Text(
                        text = (profileState as VendorProfileUiState.Error).message,
                        color = Color.Red,
                        modifier = Modifier.padding(top = 16.dp)
                    )
                }
                else -> Unit
            }
        }
    }
}