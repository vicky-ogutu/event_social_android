package com.example.invyte.ui.vendor

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
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.data.model.Service
import com.example.invyte.data.model.ServiceRequest
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import kotlin.String


@Composable
fun ServicesScreen(
    navController: NavController,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val servicesState by viewModel.servicesState.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }
    var editingService by remember { mutableStateOf<Service?>(null) }

    LaunchedEffect(Unit) {
        viewModel.getServices()
    }

    val currentState = servicesState

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFF121212))
    ) {
        when (currentState) {
            is ServicesUiState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is ServicesUiState.ServicesLoaded -> {
                val services = currentState.services
                if (services.isEmpty()) {
                    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                        Text("No services added yet.", color = Color.Gray)
                    }
                } else {
                    LazyColumn(
                        modifier = Modifier.fillMaxSize(),
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(services) { service ->
                            ServiceCard(
                                service = service,
                                onEdit = { editingService = service },
                                onDelete = { viewModel.deleteService(service.id) }
                            )
                        }
                    }
                }
            }
            is ServicesUiState.Error -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${currentState.message}", color = Color.Red)
                }
            }
            else -> Unit
        }

        FloatingActionButton(
            onClick = { showAddDialog = true },
            containerColor = Color(0xFFE91E63),
            shape = RoundedCornerShape(16.dp),
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(Icons.Default.Add, contentDescription = "Add Service", tint = Color.White)
        }
    }

    if (showAddDialog) {
        ServiceDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { request ->
                viewModel.createService(request)
                showAddDialog = false
            }
        )
    }

    editingService?.let { service ->
        ServiceDialog(
            initialService = service,
            onDismiss = { editingService = null },
            onConfirm = { request ->
                viewModel.updateService(service.id, request)
                editingService = null
            }
        )
    }
}

// ---------- Service Card (null‑safe) ----------
@Composable
fun ServiceCard(
    service: Service,
    onEdit: () -> Unit,
    onDelete: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = Color(0xFF2A2A2A))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                // serviceName is non‑null, but we still use a safe fallback
                Text(
                    text = service.serviceName ?: "Unnamed",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White
                )
                Text(
                    text = "Price: KSH ${service.basePrice ?: 0.0}",
                    color = Color.Gray
                )
                Text(
                    text = "Category: ${service.serviceName ?: 0}",
                    color = Color.Gray,
                    fontSize = 12.sp
                )
                // description can be null – show only if present
                service.description?.let {
                    Text(text = it, color = Color.Gray, fontSize = 12.sp)
                }
            }
            Row {
                IconButton(onClick = onEdit) {
                    Icon(Icons.Default.Edit, contentDescription = "Edit", tint = Color(0xFFE91E63))
                }
                IconButton(onClick = onDelete) {
                    Icon(Icons.Default.Delete, contentDescription = "Delete", tint = Color.Red)
                }
            }
        }
    }
}

// ---------- Service Dialog (correct fields, null‑safe) ----------
@Composable
fun ServiceDialog(
    initialService: Service? = null,   // null = add mode
    onDismiss: () -> Unit,
    onConfirm: (ServiceRequest) -> Unit
) {
    var categoryId by remember { mutableStateOf(initialService?.categoryId?.toString() ?: "") }
    var serviceName by remember { mutableStateOf(initialService?.serviceName ?: "") }
    var description by remember { mutableStateOf(initialService?.description ?: "") }
    var basePrice by remember { mutableStateOf(initialService?.basePrice?.toString() ?: "") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (initialService == null) "Add Service" else "Edit Service", color = Color.White) },
        text = {
            Column {
                OutlinedTextField(
                    value = categoryId,
                    onValueChange = { categoryId = it },
                    label = { Text("Category ID", color = Color.Gray) },
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
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = serviceName,
                    onValueChange = { serviceName = it },
                    label = { Text("Service Name", color = Color.Gray) },
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
                Spacer(modifier = Modifier.height(8.dp))

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
                Spacer(modifier = Modifier.height(8.dp))

                OutlinedTextField(
                    value = basePrice,
                    onValueChange = { basePrice = it },
                    label = { Text("Base Price (KSH)", color = Color.Gray) },
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
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val catId = categoryId.toIntOrNull()
                    val price = basePrice.toDoubleOrNull()
                    if (catId != null && serviceName.isNotBlank() && price != null) {
                        onConfirm(
                            ServiceRequest(
                                categoryId = catId,
                                serviceName = serviceName.trim(),
                                description = description.takeIf { it.isNotBlank() },
                                basePrice = price
                            )
                        )
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
            ) {
                Text(if (initialService == null) "Add" else "Update")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel", color = Color.White)
            }
        },
        containerColor = Color(0xFF1A1A1A)
    )
}
