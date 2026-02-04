import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/farm_event_model.dart';

class AICameraGalleryScreen extends StatelessWidget {
  final List<FarmEvent> events;

  const AICameraGalleryScreen({super.key, required this.events});

  @override
  Widget build(BuildContext context) {
    // Chỉ lọc những event nào có chứa ảnh
    final imageEvents = events.where((e) => e.imageBase64 != null).toList();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFF121212)),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Text(
                "AI Camera Gallery",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                "Tìm thấy ${imageEvents.length} hình ảnh phân tích",
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: imageEvents.isEmpty
                  ? _buildEmptyState()
                  : GridView.builder(
                      padding: const EdgeInsets.all(15),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.8,
                          ),
                      itemCount: imageEvents.length,
                      itemBuilder: (context, index) {
                        final event = imageEvents[index];
                        return _buildImageCard(context, event);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, FarmEvent event) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2630),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hiển thị ảnh (ở đây mock bằng URL từ server hoặc Base64 nếu có)
                Image.network(
                  event.imageBase64!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(Icons.broken_image, color: Colors.white24),
                  ),
                ),
                // Badge trạng thái
                PositionBy(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: event.plantStatus == "Healthy"
                          ? Colors.green
                          : Colors.orange,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.plantStatus,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('HH:mm - dd/MM').format(event.timestamp),
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "Đất: ${event.soil.toStringAsFixed(1)}%",
                  style: const TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_enhance_outlined,
            size: 80,
            color: Colors.white.withOpacity(0.1),
          ),
          const SizedBox(height: 16),
          const Text(
            "Chưa có ảnh chụp nào",
            style: TextStyle(color: Colors.white24),
          ),
        ],
      ),
    );
  }
}

// Widget phụ trợ để đặt vị trí trong Stack
class PositionBy extends StatelessWidget {
  final double? top, left, right, bottom;
  final Widget child;
  const PositionBy({
    super.key,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.child,
  });
  @override
  Widget build(BuildContext context) => Positioned(
    top: top,
    left: left,
    right: right,
    bottom: bottom,
    child: child,
  );
}
