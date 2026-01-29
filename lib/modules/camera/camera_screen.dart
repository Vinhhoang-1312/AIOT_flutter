// lib/modules/camera/camera_screen.dart
import 'package:flutter/material.dart';

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 7,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: Colors.greenAccent.withOpacity(0.5),
                width: 2,
              ),
              image: const DecorationImage(
                image: NetworkImage(
                  "https://images.unsplash.com/photo-1530836361253-efad5d718465?q=80&w=1000",
                ),
                fit: BoxFit.cover,
                opacity: 0.6,
              ),
            ),
            child: Stack(
              children: [
                // AI Scanning Lines
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white24),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  left: 40,
                  child: _buildHUDTag("REC 00:42:11", Colors.red),
                ),
                Positioned(
                  bottom: 40,
                  right: 40,
                  child: _buildHUDTag("BUG DETECTED: 85%", Colors.orange),
                ),
              ],
            ),
          ),
        ),
        _buildControlPanel(context),
      ],
    );
  }

  Widget _buildHUDTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: Color(0xFF1E2630),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _circleBtn(Icons.flash_on, "Flash", Colors.orange),
          _circleBtn(Icons.camera, "Capture", Colors.blue),
          _circleBtn(Icons.videocam, "Record", Colors.red),
        ],
      ),
    );
  }

  Widget _circleBtn(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
