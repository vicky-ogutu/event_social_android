package com.example.invyte.ui



import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.invyte.data.model.Message

@Composable
fun MessageBubble(
    message: Message,
    isCurrentUser: Boolean
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 8.dp, vertical = 4.dp),
        horizontalArrangement = if (isCurrentUser) Arrangement.End else Arrangement.Start
    ) {
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(16.dp))
                .background(
                    if (isCurrentUser) Color(0xFFE91E63) else Color(0xFF333333)
                )
                .padding(horizontal = 16.dp, vertical = 10.dp)
                .widthIn(max = 280.dp)
        ) {
            Text(
                text = message.message,
                color = if (isCurrentUser) Color.White else Color.White,
                fontSize = 14.sp,
                textAlign = if (isCurrentUser) TextAlign.End else TextAlign.Start
            )
        }
    }
}