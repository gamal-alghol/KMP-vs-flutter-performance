package com.example.test_KMP

import CryptoItem
import SparklineCanvas
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.tooling.preview.Preview

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlin.math.roundToInt

@Composable
@Preview
fun App() {
    var cryptoList by remember { mutableStateOf(CryptoDataGenerator.generateInitialData()) }

    LaunchedEffect(Unit) {
        while (isActive) {
            delay(100)
            cryptoList = CryptoDataGenerator.updatePrices(cryptoList)
        }
    }

     val infiniteTransition = rememberInfiniteTransition()
    val animatedOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(10000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        )
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)),
                    start = androidx.compose.ui.geometry.Offset(animatedOffset, 0f),
                    end = androidx.compose.ui.geometry.Offset(0f, animatedOffset)
                )
            )
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            contentPadding = PaddingValues(top = 110.dp, bottom = 24.dp, start = 16.dp, end = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            items(
                items = cryptoList,
                key = { it.id }
            ) { item ->
                CryptoCardItem(item)
            }
        }

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(100.dp)
                .align(Alignment.TopCenter)
                .blur(16.dp)
                .background(Color.White.copy(alpha = 0.1f))
        )

        Text(
            text = "KMP Live Benchmark",
            fontSize = 20.sp,
            fontWeight = FontWeight.Bold,
            color = Color.White,
            modifier = Modifier
                .align(Alignment.TopCenter)
                .statusBarsPadding()
                .padding(top = 16.dp)
        )
    }
}

@Composable
fun CryptoCardItem(item: CryptoItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(
            containerColor = Color.White.copy(alpha = 0.08f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1.2f)) {
                Text(text = item.symbol, fontWeight = FontWeight.Bold, color = Color.White, fontSize = 16.sp)
                Text(text = item.name, color = Color.Gray, fontSize = 12.sp)
            }

            SparklineCanvas(
                points = item.sparklinePoints,
                isPositive = item.changePercentage >= 0,
                modifier = Modifier
                    .weight(1.5f)
                    .height(40.dp)
                    .padding(horizontal = 8.dp)
            )

            Column(
                modifier = Modifier.weight(1.3f),
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = "$${(item.price.toFormattedString(2))}",
                    fontWeight = FontWeight.SemiBold,
                    color = Color.White,
                    fontSize = 14.sp
                )
                Text(
                    text = "${if (item.changePercentage >= 0) "+" else ""}${item.changePercentage.toFormattedString(2)}%",
                    color = if (item.changePercentage >= 0) Color(0xFF00E676) else Color(0xFFFF5252),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}
fun Double.toFormattedString(decimals: Int = 2): String {
    var multiplier = 1.0
    repeat(decimals) { multiplier *= 10 }
    val rounded = (this * multiplier).roundToInt() / multiplier
    return rounded.toString()
}