package com.example.invyte.ui.profile

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.*
import androidx.compose.material3.TextFieldDefaults.colors
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.User
import com.example.invyte.ui.theme.FieldBorder
import com.example.invyte.ui.theme.PrimaryPink
import com.example.invyte.ui.theme.TextWhite
import okhttp3.MediaType.Companion.toMediaTypeOrNull
import okhttp3.MultipartBody
import okhttp3.RequestBody.Companion.asRequestBody
import java.io.File
import java.io.FileOutputStream

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreen(
    navController: NavController,
    viewModel: ProfileViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val uiState by viewModel.uiState.collectAsState()
    val currentUser by viewModel.currentUser.collectAsState()

    // Local mutable states for form fields
    var fullName by remember { mutableStateOf(currentUser?.fullName ?: "") }
    var bio by remember { mutableStateOf(currentUser?.bio ?: "") }
    var showPasswordDialog by remember { mutableStateOf(false) }

    // Image picker launcher
    val imagePickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.GetContent()
    ) { uri: Uri? ->
        uri?.let {
            // Convert URI to file and create MultipartBody.Part
            val file = File(context.cacheDir, "avatar_${System.currentTimeMillis()}.jpg")
            context.contentResolver.openInputStream(it)?.use { input ->
                FileOutputStream(file).use { output ->
                    input.copyTo(output)
                }
            }
            val requestFile = file.asRequestBody("image/jpeg".toMediaTypeOrNull())
            val body = MultipartBody.Part.createFormData("avatar", file.name, requestFile)
            viewModel.uploadAvatar(body)
        }
    }

    // Update local fields when currentUser changes (e.g., after successful update)
    LaunchedEffect(currentUser) {
        currentUser?.let { user ->
            fullName = user.fullName
            bio = user.bio ?: ""
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Profile", color = Color.White) },
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
            // Avatar with upload button
            Box(
                modifier = Modifier
                    .size(100.dp)
                    .clip(CircleShape)
                    .background(Color.Gray)
            ) {
                if (currentUser?.profilePicture != null) {
                    AsyncImage(
                        model = currentUser?.profilePicture,
                        contentDescription = "Profile picture",
                        modifier = Modifier.fillMaxSize(),
                        contentScale = ContentScale.Crop
                    )
                } else {
                    Text(
                        text = currentUser?.fullName?.firstOrNull()?.toString() ?: "?",
                        color = Color.White,
                        fontSize = 40.sp,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                Button(
                    onClick = { imagePickerLauncher.launch("image/*") },
                    modifier = Modifier
                        .align(Alignment.BottomEnd)
                        .size(32.dp),
                    shape = CircleShape,
                    colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
                ) {
                    Text("+", color = Color.White, fontSize = 18.sp)
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Editable fields
            OutlinedTextField(
                value = fullName,
                onValueChange = { fullName = it },
                label = { Text("Full Name", color = Color.Gray) },
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
                value = bio,
                onValueChange = { bio = it },
                label = { Text("Bio", color = Color.Gray) },
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
                    viewModel.updateProfile(fullName, bio.takeIf { it.isNotBlank() })
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
            ) {
                if (uiState is ProfileUiState.Loading) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(24.dp))
                } else {
                    Text("Update Profile", fontSize = 18.sp)
                }
            }

            Spacer(modifier = Modifier.height(12.dp))

            TextButton(
                onClick = { showPasswordDialog = true },
                modifier = Modifier.align(Alignment.Start)
            ) {
                Text("Change Password", color = Color(0xFFE91E63))
            }

            // Feedback messages
            when (uiState) {
                is ProfileUiState.Success -> {
                    Text(
                        text = (uiState as ProfileUiState.Success).message,
                        color = Color.Green,
                        modifier = Modifier.padding(top = 16.dp)
                    )
                    LaunchedEffect(Unit) {
                        viewModel.resetState()
                    }
                }
                is ProfileUiState.Error -> {
                    Text(
                        text = (uiState as ProfileUiState.Error).message,
                        color = Color.Red,
                        modifier = Modifier.padding(top = 16.dp)
                    )
                }
                else -> Unit
            }
        }
    }

    // Change password dialog
    if (showPasswordDialog) {
        ChangePasswordDialog(
            onDismiss = { showPasswordDialog = false },
            onConfirm = { old, new ->
                viewModel.changePassword(old, new)
                showPasswordDialog = false
            }
        )
    }
}

@Composable
fun ChangePasswordDialog(
    onDismiss: () -> Unit,
    onConfirm: (String, String) -> Unit
) {
    var oldPassword by remember { mutableStateOf("") }
    var newPassword by remember { mutableStateOf("") }
    var confirmPassword by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Change Password", color = Color.White) },
        text = {
            Column {
                OutlinedTextField(
                    value = oldPassword,
                    onValueChange = { oldPassword = it },
                    label = { Text("Old Password", color = Color.Gray) },
                    visualTransformation = PasswordVisualTransformation(),
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
                    value = newPassword,
                    onValueChange = { newPassword = it },
                    label = { Text("New Password", color = Color.Gray) },
                    visualTransformation = PasswordVisualTransformation(),
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
                    value = confirmPassword,
                    onValueChange = { confirmPassword = it },
                    label = { Text("Confirm New Password", color = Color.Gray) },
                    visualTransformation = PasswordVisualTransformation(),
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
                    if (newPassword == confirmPassword && newPassword.length >= 6) {
                        onConfirm(oldPassword, newPassword)
                    }
                },
                colors = ButtonDefaults.buttonColors(containerColor = Color(0xFFE91E63))
            ) {
                Text("Change")
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