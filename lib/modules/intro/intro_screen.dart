import 'package:flutter/material.dart';
import '../home/home_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});
  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _data = [
    {
      "t": "Nông Nghiệp 4.0",
      "d": "Giải pháp AIoT tối ưu hóa 70% lượng nước ngọt tiêu thụ.",
      "img":
          "https://images.unsplash.com/photo-1625246333195-78d9c38ad449?q=80&w=1000",
    },
    {
      "t": "Tiết Kiệm Nước",
      "d": "Giảm thiểu lãng phí và tăng năng suất thông qua dữ liệu thực.",
      "img":
          "https://images.unsplash.com/photo-1560493676-04071c5f467b?q=80&w=1000",
    },
    {
      "t": "Dự Báo AI",
      "d": "Mô hình LSTM dự đoán chính xác nhu cầu tưới tiêu của cây trồng.",
      "img":
          "https://images.unsplash.com/photo-1581092580497-e0d23cbdf1dc?q=80&w=1000",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: _data.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (context, i) => Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_data[i]['img']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _data[_currentIndex]['t']!,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _data[_currentIndex]['d']!,
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: List.generate(
                          _data.length,
                          (i) => Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentIndex == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Colors.greenAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      FloatingActionButton(
                        backgroundColor: Colors.greenAccent,
                        onPressed: () {
                          if (_currentIndex < 2) {
                            _controller.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.ease,
                            );
                          } else {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HomeScreen(),
                              ),
                            );
                          }
                        },
                        child: Icon(
                          _currentIndex == 2
                              ? Icons.check
                              : Icons.arrow_forward_ios,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
