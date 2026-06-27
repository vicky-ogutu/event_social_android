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
import com.example.invyte.data.model.ServiceRequest
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ServicesScreen(
    navController: NavController,
    viewModel: VendorViewModel = hiltViewModel()
) {
    val servicesState by viewModel.servicesState.collectAsState()
    var showAddDialog by remember { mutableStateOf(false) }
    var editingService by remember { mutableStateOf<Pair<Int, ServiceRequest>?>(null) }

    LaunchedEffect(Unit) {
        viewModel.getServices()
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("My Services", color = Color.White) },
                navigationIcon = {
                    IconButton(onClick = { navController.navigateUp() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
            )
        },
        floatingActionButton = {
            FloatingActionButton(
                onClick = { showAddDialog = true },
                containerColor = Color(0xFFE91E63),
                shape = RoundedCornerShape(16.dp)
            ) {
                Icon(Icons.Default.Add, contentDescription = "Add Service", tint = Color.White)
            }
        }
    ) { paddingValues ->
        when (servicesState) {
            is ServicesUiState.Loading -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator()
                }
            }
            is ServicesUiState.ServicesLoaded -> {
                val services = (servicesState as ServicesUiState.ServicesLoaded).services
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color(0xFF121212))
                        .padding(paddingValues)
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(services) { service ->
                        ServiceCard(
                            service = service,
                            onEdit = {
                                editingService = service.id to ServiceRequest(
                                    category = service.category,
                                    price = service.price,
                                    description = service.description
                                )
                            },
                            onDelete = {
                                viewModel.deleteService(service.id)
                            }
                        )
                    }
                }
            }
            is ServicesUiState.Error -> {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text("Error: ${(servicesState as ServicesUiState.Error).message}", color = Color.Red)
                }
            }
            else -> Unit
        }
    }

    // Add/Edit Service Dialog
    if (showAddDialog) {
        ServiceDialog(
            onDismiss = { showAddDialog = false },
            onConfirm = { request ->
                viewModel.createService(request)
                showAddDialog = false
            }
        )
    }

    editingService?.let { (id, request) ->
        ServiceDialog(
            initialRequest = request,
            onDismiss = { editingService = null },
            onConfirm = { updatedRequest ->
                viewModel.updateService(id, updatedRequest)
                editingService = null
            }
        )
    }
}

@Composable
fun ServiceCard(
    service: com.example.invyte.data.model.Service,
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
                Text(text = service.category, style = MaterialTheme.typography.titleMedium, color = Color.White)
                Text(text = "Price: ₹${service.price}", color = Color.Gray)
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

@Composable
fun ServiceDialog(
    initialRequest: ServiceRequest? = null,
    onDismiss: () -> Unit,
    onConfirm: (ServiceRequest) -> Unit
) {
    var category by remember { mutableStateOf(initialRequest?.category ?: "") }
    var price by remember { mutableStateOf(initialRequest?.price?.toString() ?: "") }
    var description by remember { mutableStateOf(initialRequest?.description ?: "") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text(if (initialRequest == null) "Add Service" else "Edit Service", color = Color.White) },
        text = {
            Column {
                OutlinedTextField(
                    value = category,
                    onValueChange = { category = it },
                    label = { Text("Category", color = Color.Gray) },
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
                    value = price,
                    onValueChange = { price = it },
                    label = { Text("Price", color = Color.Gray) },
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
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    val priceDouble = price.toDoubleOrNull()
                    if (category.isNotBlank() && priceDouble != null) {
                        onConfirm(ServiceRequest(category, priceDouble, description.takeIf { it.isNotBlank() }))
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
            ) {
                Text(if (initialRequest == null) "Add" else "Update")
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