// lib/core/constants/ai_constants.dart

class AIConstants {
  static String generateFarmPrompt(String data) {
    return """
Bạn là một chuyên gia nông nghiệp AI. Đây là dữ liệu từ cảm biến của trang trại tôi:
$data

Dựa trên dữ liệu này, hãy đưa ra một đánh giá ngắn gọn (khoảng 2 câu) về tình trạng cây trồng và lời khuyên cụ thể. 
Trả lời bằng tiếng Việt, giọng văn chuyên nghiệp.
""";
  }
}
