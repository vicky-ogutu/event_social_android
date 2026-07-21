package com.example.invyte

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.example.invyte.data.model.Service

@Composable
fun ServiceCard(
    service: Service,
    onBook: () -> Unit,
    onEdit: (() -> Unit)? = null,
    onDelete: (() -> Unit)? = null
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(service.serviceName, style = MaterialTheme.typography.titleMedium)
            service.description?.let { Text(it) }
            Text("$${service.basePrice} per ${service.priceUnit}")
            Row(
                horizontalArrangement = Arrangement.SpaceEvenly,
                modifier = Modifier.fillMaxWidth()
            ) {
                Button(onClick = onBook) { Text("Book") }
                if (onEdit != null) {
                    Button(onClick = onEdit) { Text("Edit") }
                }
                if (onDelete != null) {
                    Button(onClick = onDelete) { Text("Delete") }
                }
            }
        }
    }
}