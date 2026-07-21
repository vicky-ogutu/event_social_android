package com.example.invyte.ui.vendor

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.hilt.lifecycle.viewmodel.compose.hiltViewModel
import com.example.invyte.ui.PostCard

@Composable
fun SocialFeedScreen(
    eventId: Int? = null,
    viewModel: SocialFeedViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    LaunchedEffect(Unit) { viewModel.loadFeed(eventId) }

    when (uiState) {
        is SocialFeedUiState.Loading -> Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
        is SocialFeedUiState.Success -> {
            LazyColumn {
                items((uiState as SocialFeedUiState.Success).posts) { post ->
                    PostCard(post, onLike = { viewModel.toggleLike(post.id) })
                }
            }
        }
        is SocialFeedUiState.Error -> Text("Error: ${(uiState as SocialFeedUiState.Error).message}")
    }
}