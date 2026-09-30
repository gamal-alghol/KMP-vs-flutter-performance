import androidx.compose.runtime.Immutable
import kotlin.random.Random

@Immutable
data class CryptoItem(
    val id: String,
    val name: String,
    val symbol: String,
    val price: Double,
    val changePercentage: Double,
    val sparklinePoints: List<Float>
)

object CryptoDataGenerator {
    fun generateInitialData(count: Int = 500): List<CryptoItem> {
        return List(count) { index ->
            CryptoItem(
                id = "item_$index",
                name = "Crypto Asset #$index",
                symbol = "CRYPTO$index",
                price = Random.nextDouble(10.0, 50000.0),
                changePercentage = Random.nextDouble(-12.0, 12.0),
                sparklinePoints = List(20) { Random.nextFloat() * 100f }
            )
        }
    }

    fun updatePrices(currentList: List<CryptoItem>): List<CryptoItem> {
        return currentList.map { item ->
            if (Random.nextBoolean()) {
                val newPrice = item.price * (1 + Random.nextDouble(-0.02, 0.02))
                val newPoints = item.sparklinePoints.drop(1) + (Random.nextFloat() * 100f)
                item.copy(
                    price = newPrice,
                    changePercentage = item.changePercentage + Random.nextDouble(-0.5, 0.5),
                    sparklinePoints = newPoints
                )
            } else item
        }
    }
}