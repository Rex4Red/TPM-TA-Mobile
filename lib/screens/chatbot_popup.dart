import 'package:flutter/material.dart';
import '../services/ai_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatbotPopup extends StatefulWidget {
  const ChatbotPopup({super.key});

  @override
  State<ChatbotPopup> createState() => _ChatbotPopupState();
}

class _ChatbotPopupState extends State<ChatbotPopup> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> messages = [];
  bool isLoading = false;

  void sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"text": text, "isUser": true});
      isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final response = await AiService.sendMessage(text);

    setState(() {
      messages.add({"text": response, "isUser": false});
      isLoading = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget buildMessage(Map<String, dynamic> msg) {
    final isUser = msg["isUser"];

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? ChatbotPopupColors.bubbleUser
              : ChatbotPopupColors.bubbleAI,
          borderRadius: BorderRadius.circular(12),
        ),
        child: MarkdownBody(
          data: msg["text"],
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(
              color: isUser ? ChatbotPopupColors.textOnUser : ChatbotPopupColors.textOnAI,
              fontSize: 14,
            ),
            strong: TextStyle(
              fontWeight: FontWeight.bold,
              color: isUser ? ChatbotPopupColors.textOnUser : ChatbotPopupColors.textOnAI,
            ),
            listBullet: TextStyle(
              color: isUser ? ChatbotPopupColors.textOnUser : ChatbotPopupColors.textOnAI,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 12,
        ),
        decoration: BoxDecoration(
          color: ChatbotPopupColors.background,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              height: 5,
              width: 50,
              decoration: BoxDecoration(
                color: ChatbotPopupColors.handle,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              "AI Chatbot",
              style: TextStyle(
                color: ChatbotPopupColors.title,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return buildMessage(messages[index]);
                },
              ),
            ),

            if (isLoading)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  "AI lagi mikir...",
                  style: TextStyle(color: ChatbotPopupColors.loadingText),
                ),
              ),

            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: TextStyle(color: ChatbotPopupColors.inputText),
                        decoration: InputDecoration(
                          hintText: "Ketik pesan...",
                          hintStyle:
                              TextStyle(color: ChatbotPopupColors.hintText),
                          filled: true,
                          fillColor: ChatbotPopupColors.inputBg,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: sendMessage,
                      icon: Icon(Icons.send,
                          color: ChatbotPopupColors.sendButton),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ========== COLOR SETTINGS - chatbot_popup.dart ==========
// Ganti warna di bawah, lalu Hot Reload (r). Langsung berubah!
// =========================================================
class ChatbotPopupColors {
  static const background  = Color(0xFF1E1E1E);     // Background popup chatbot
  static const handle      = Color.fromARGB(255, 54, 53, 53);            // Garis handle atas popup
  static const title       = Colors.white;           // Judul "AI Chatbot"
  static const bubbleUser  = Colors.blueAccent;      // Bubble chat user (kanan)
  static final  bubbleAI    = Colors.grey.shade300;    // Bubble chat AI (kiri)
  static const textOnUser  = Colors.white;           // Teks di bubble user
  static const textOnAI    = Colors.black;           // Teks di bubble AI
  static const loadingText = Colors.white54;         // Teks "AI lagi mikir..."
  static const inputText   = Colors.white;           // Teks ketikan user
  static const hintText    = Colors.white54;         // Placeholder "Ketik pesan..."
  static final inputBg     = Colors.grey[900];       // Background input field
  static const sendButton  = Colors.blueAccent;      // Ikon tombol kirim
}
// =========================================================