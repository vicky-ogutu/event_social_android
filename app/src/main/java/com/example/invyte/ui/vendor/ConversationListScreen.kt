package com.example.invyte.ui.vendor

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Badge
import androidx.compose.material3.Card
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import androidx.navigation.NavController
import coil.compose.AsyncImage
import com.example.invyte.data.model.Conversation

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConversationListScreen(
    navController: NavController,
    viewModel: ConversationListViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Scaffold(
        topBar = { TopAppBar(title = { Text("Messages") }) }
    ) { padding ->
        when (uiState) {
            //is ConversationListUiState.Loading -> Box(...) { CircularProgressIndicator() }
            is ConversationListUiState.Success -> {
                val conversations = (uiState as ConversationListUiState.Success).conversations
                LazyColumn(modifier = Modifier.padding(padding)) {
                    items(conversations) { conv ->
                        ConversationItem(conv, onClick = {
                            navController.navigate("chat/${conv.user_id}")
                        })
                    }
                }
            }
            is ConversationListUiState.Error -> Text("Error: ${(uiState as ConversationListUiState.Error).message}")
            else -> {}
        }
    }
}

@Composable
fun ConversationItem(conversation: Conversation, onClick: () -> Unit) {
    Card(modifier = Modifier.clickable { onClick() }) {
        Row(modifier = Modifier.padding(16.dp)) {
            AsyncImage(model = conversation.profile_picture, contentDescription = null, modifier = Modifier.size(48.dp).clip(CircleShape))
            Column(modifier = Modifier.padding(start = 12.dp)) {
                Text(conversation.full_name, fontWeight = FontWeight.Bold)
                Text(conversation.last_message ?: "No messages", maxLines = 1)
                if (conversation.unread_count > 0) {
                    Badge { Text(conversation.unread_count.toString()) }
                }
            }
        }
    }
}