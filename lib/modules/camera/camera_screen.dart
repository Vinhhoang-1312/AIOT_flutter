import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/farm_event_model.dart';
import '../../data/services/api_service.dart';

class AICameraGalleryScreen extends StatefulWidget {
  final List<FarmEvent>? events; // Optional: initial data

  const AICameraGalleryScreen({super.key, this.events});

  @override
  State<AICameraGalleryScreen> createState() => _AICameraGalleryScreenState();
}

class _AICameraGalleryScreenState extends State<AICameraGalleryScreen> {
  List<FarmEvent> _imageEvents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.events != null && widget.events!.isNotEmpty) {
      _filterImages(widget.events!);
      _isLoading = false;
    } else {
      _fetchGalleryData();
    }
  }

  void _filterImages(List<FarmEvent> remoteEvents) {
    final withImages = remoteEvents
        .where((e) => e.imageBase64 != null && e.imageBase64!.isNotEmpty)
        .toList();
    // Sort newest first
    withImages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    setState(() {
      _imageEvents = withImages;
    });
  }

  Future<void> _fetchGalleryData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch history for the last 7 days to find images
      // Note: If the API returns too much data without images, this might be inefficient,
      // but without a specific "getImages" endpoint, this is the best approach.
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 7));

      final events = await ApiService.getEnvironmentHistory(
        startTime: startTime.toIso8601String(),
        endTime: now.toIso8601String(),
        interval:
            '1h', // Get rawest possible resolution if allowed, or standard interval
      );

      _filterImages(events);
    } catch (e) {
      debugPrint("Error loading gallery: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          "AI Camera Gallery",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchGalleryData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    "Tìm thấy ${_imageEvents.length} hình ảnh phân tích",
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                Expanded(
                  child: _imageEvents.isEmpty
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
                          itemCount: _imageEvents.length,
                          itemBuilder: (context, index) {
                            return _buildImageCard(
                              context,
                              _imageEvents[index],
                            );
                          },
                        ),
                ),
              ],
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
                _buildImage(event),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(event.plantStatus),
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

  Widget _buildImage(FarmEvent event) {
    if (event.imageBytes != null) {
      return Image.memory(
        event.imageBytes!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => const Center(
          child: Icon(Icons.broken_image, color: Colors.white24),
        ),
      );
    }
    return const Center(
      child: Icon(Icons.image_not_supported, color: Colors.white24),
    );
  }

  Color _getStatusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('healthy') || s.contains('tốt')) return Colors.green;
    if (s.contains('unknown') || s.contains('chưa')) return Colors.grey;
    return Colors.orange;
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
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _fetchGalleryData,
            icon: const Icon(Icons.refresh),
            label: const Text("Thử lại"),
          ),
        ],
      ),
    );
  }
}
