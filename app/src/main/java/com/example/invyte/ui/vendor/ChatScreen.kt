package com.example.invyte.ui.vendor

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import kotlin.collections.reversed

@Composable
fun ChatScreen(
    eventId: Int,
    viewModel: ChatViewModel = hiltViewModel()
) {
    val messages by viewModel.messages.collectAsState()
    var input by remember { mutableStateOf("") }

    LaunchedEffect(Unit) { viewModel.joinEventChat(eventId) }

    Column {
        LazyColumn(reverseLayout = true) {
            items(messages.reversed()) { msg ->
                Text("${msg.full_name}: ${msg.message}")
            }
        }
        Row {
            TextField(value = input, onValueChange = { input = it }, modifier = Modifier.weight(1f))
            Button(onClick = {
                if (input.isNotBlank()) {
                    viewModel.sendMessage(eventId, input)
                    input = ""
                }
            }) {
                Text("Send")
            }
        }
    }
}