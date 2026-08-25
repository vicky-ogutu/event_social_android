package com.example.invyte.ui.vendor

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController
import kotlin.collections.reversed

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    eventId: Int,
    viewModel: ChatViewModel = hiltViewModel(),
   // navController: NavController,
) {
    val messages by viewModel.messages.collectAsState()
    var input by remember { mutableStateOf("") }

    LaunchedEffect(Unit) { viewModel.joinEventChat(eventId) }

//    Scaffold(
//        topBar = {
//            TopAppBar(
//                title = { Text("Chat", color = Color.White) },
//                navigationIcon = {
//                    IconButton(onClick = { navController.navigateUp() }) {
//                        Icon(Icons.Default.ArrowBack, contentDescription = "Back", tint = Color.White)
//                    }
//                },
//                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color(0xFF1A1A1A))
//            )
//        }
//    ) { paddingValues ->
    Column {
        LazyColumn(reverseLayout = true,
            modifier = Modifier
                .fillMaxSize()
                .background(Color(0xFF121212))
                //.padding(paddingValues)
                .padding(horizontal = 16.dp),
            ) {
            items(messages.reversed()) { msg ->
                Text("${msg.full_name}: ${msg.message}")
            }
        }
        Row {
            TextField(value = input, onValueChange = { input = it }, modifier = Modifier.weight(1f))
            Button(onClick = {
                if (input.isNotBlank()) {
                    viewModel.sendMessage(input)
                    input = ""
                }
            }) { Text("Send") }
        }
    }
}
//}


