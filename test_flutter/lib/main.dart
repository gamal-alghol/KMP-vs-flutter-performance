import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Live Benchmark',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const AppScreen(),
    );
  }
}

// ==========================================
// 1. Data Model & 100 Items Data Generator
// ==========================================
class CryptoItem {
  final String id;
  final String symbol;
  final String name;
  final double price;
  final double changePercentage;
  final List<double> sparklinePoints;

  CryptoItem({
    required this.id,
    required this.symbol,
    required this.name,
    required this.price,
    required this.changePercentage,
    required this.sparklinePoints,
  });

  CryptoItem copyWith({
    double? price,
    double? changePercentage,
    List<double>? sparklinePoints,
  }) {
    return CryptoItem(
      id: id,
      symbol: symbol,
      name: name,
      price: price ?? this.price,
      changePercentage: changePercentage ?? this.changePercentage,
      sparklinePoints: sparklinePoints ?? this.sparklinePoints,
    );
  }
}

class CryptoDataGenerator {
  static final Random _random = Random();

  static List<CryptoItem> generateInitialData() {
    return List.generate(100, (index) {
      final String formattedIndex = index.toString().padLeft(2, '0');
      final bool isPositive = _random.nextBool();
      final double change = (isPositive ? 1 : -1) * (_random.nextDouble() * 20);

      final List<double> points = List.generate(20, (_) => 10.0 + _random.nextDouble() * 50.0);

      return CryptoItem(
        id: index.toString(),
        symbol: 'CRYPTO$formattedIndex',
        name: 'Crypto Asset #$index',
        price: 1000.0 + _random.nextDouble() * 30000.0,
        changePercentage: change,
        sparklinePoints: points,
      );
    });
  }

  // تحديث أسعار الـ 100 عنصر كل 100ms
  static List<CryptoItem> updatePrices(List<CryptoItem> currentList) {
    return currentList.map((item) {
      final double delta = (_random.nextDouble() - 0.5) * 50.0;
      final newPrice = (item.price + delta).clamp(100.0, 100000.0);
      final newChange = item.changePercentage + (delta * 0.01);

      final newPoints = List<double>.from(item.sparklinePoints)
        ..removeAt(0)
        ..add((item.sparklinePoints.last + (_random.nextDouble() - 0.5) * 10.0).clamp(5.0, 60.0));

      return item.copyWith(
        price: newPrice,
        changePercentage: newChange,
        sparklinePoints: newPoints,
      );
    }).toList();
  }
}

// ==========================================
// 2. Sparkline Canvas مع إضافة الـ Glow & Blur Fill
// ==========================================
class SparklineCanvas extends StatelessWidget {
  final List<double> points;
  final bool isPositive;

  const SparklineCanvas({
    super.key,
    required this.points,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(
        points: points,
        isPositive: isPositive,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final bool isPositive;

  _SparklinePainter({
    required this.points,
    required this.isPositive,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final Color mainColor = isPositive
        ? const Color(0xFF00E676)
        : const Color(0xFFFF5252);

    final double minVal = points.reduce((a, b) => a < b ? a : b);
    final double maxVal = points.reduce((a, b) => a > b ? a : b);
    final double range = (maxVal - minVal) == 0 ? 1 : (maxVal - minVal);
    final double stepX = size.width / (points.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < points.length; i++) {
      final double x = i * stepX;
      final double normalizedY = (points[i] - minVal) / range;
      final double y = size.height - (normalizedY * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // 1. رسم التعبئة المتدرجة المضيئة (Glow / Shadow Gradient under line)
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          mainColor.withOpacity(0.35),
          mainColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 2. رسم خط المنحنى الخارجي
    final strokePaint = Paint()
      ..color = mainColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.isPositive != isPositive;
  }
}

// ==========================================
// 3. Main Screen Widget
// ==========================================
class AppScreen extends StatefulWidget {
  const AppScreen({super.key});

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> with SingleTickerProviderStateMixin {
  late List<CryptoItem> cryptoList;
  late AnimationController _animController;
  late Animation<double> _animatedOffset;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    cryptoList = CryptoDataGenerator.generateInitialData();

    // تحديث مستمر بنفس سرعة كوتلن (100ms)
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() {
        cryptoList = CryptoDataGenerator.updatePrices(cryptoList);
      });
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _animatedOffset = Tween<double>(begin: 0.0, end: 1000.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _animatedOffset,
        builder: (context, child) {
          final offset = _animatedOffset.value;
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364),
                ],
                begin: Alignment((offset / 500.0) - 1.0, -1.0),
                end: Alignment(-1.0, (offset / 500.0) - 1.0),
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // القائمة (100 عنصر)
            ListView.separated(
              padding: EdgeInsets.only(
                top: 110.0 + MediaQuery.of(context).padding.top,
                bottom: 24.0,
                left: 16.0,
                right: 16.0,
              ),
              itemCount: cryptoList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = cryptoList[index];
                return CryptoCardItem(
                  key: ValueKey(item.id),
                  item: item,
                );
              },
            ),

            // طبقة الـ Glassmorphic Overlay العلوية
            Align(
              alignment: Alignment.topCenter,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16.0, sigmaY: 16.0),
                  child: Container(
                    width: double.infinity,
                    height: 100.0,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),

            // العنوان العلوي
            Align(
              alignment: Alignment.topCenter,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: const Text(
                    'Flutter Live Benchmark',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 4. Crypto Card Item
// ==========================================
class CryptoCardItem extends StatelessWidget {
  final CryptoItem item;

  const CryptoCardItem({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final bool isPositive = item.changePercentage >= 0;

    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Symbol + Name
            Expanded(
              flex: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.symbol,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    item.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Sparkline مع الـ Glow
            Expanded(
              flex: 15,
              child: SizedBox(
                height: 40,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SparklineCanvas(
                    points: item.sparklinePoints,
                    isPositive: isPositive,
                  ),
                ),
              ),
            ),

            // Price + Change
            Expanded(
              flex: 13,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '\$${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${isPositive ? '+' : ''}${item.changePercentage.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}