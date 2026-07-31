package com.example.invyte.ui.vendor

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController
import com.example.invyte.ui.MessageBubble
import com.example.invyte.utils.TokenManager

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatDetailScreen(
    navController: NavController,
    userId: Int,
    viewModel: ChatDetailViewModel = hiltViewModel(),
    tokenManager: TokenManager = hiltViewModel() // 👈 get token manager
) {
    val messages by viewModel.messages.collectAsState()
    val uiState by viewModel.uiState.collectAsState()
    var input by remember { mutableStateOf("") }
    val currentUserId = tokenManager.getUserIdFlow().collectAsState(initial = null).value ?: 0

    LaunchedEffect(Unit) {
        viewModel.loadConversation(userId)
    }

    Scaffold(
        topBar = { TopAppBar(title = { Text("Chat") }) }
    ) { padding ->
        Column(modifier = Modifier.padding(padding)) {
            LazyColumn(
                reverseLayout = true,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp)
            ) {
                items(messages.reversed()) { msg ->
                    MessageBubble(
                        message = msg,
                        isCurrentUser = msg.sender_id == currentUserId
                    )
                }
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                TextField(
                    value = input,
                    onValueChange = { input = it },
                    modifier = Modifier.weight(1f),
                    placeholder = { Text("Type a message...") }
                )
                Button(
                    onClick = {
                        if (input.isNotBlank()) {
                            viewModel.sendMessage(input)
                            input = ""
                        }
                    }
                ) {
                    Text("Send")
                }
            }
        }
    }
}