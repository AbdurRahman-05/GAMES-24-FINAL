import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_text_field.dart';

class ChatUiScreen extends StatefulWidget {
  const ChatUiScreen({super.key});

  @override
  State<ChatUiScreen> createState() => _ChatUiScreenState();
}

class _ChatUiScreenState extends State<ChatUiScreen> {
  final TextEditingController _msgController = TextEditingController();

  final List<_ChatMessage> _messages = [
    _ChatMessage(text: "Hey everyone! Is court 1 ready at KK Nagar?", isMe: false, sender: "Vijay Sethu", time: "06:45 PM"),
    _ChatMessage(text: "Yes, host confirmed lights are turned on!", isMe: false, sender: "Manojh", time: "06:46 PM"),
    _ChatMessage(text: "I'm arriving in 10 mins with extra footballs.", isMe: true, sender: "You", time: "06:48 PM"),
  ];

  void _sendMessage([String? customText]) {
    final text = customText ?? _msgController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        _ChatMessage(
          text: text,
          isMe: true,
          sender: "You",
          time: "Just now",
        ),
      );
      if (customText == null) _msgController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          children: [
            Text('Match Lobby Chat', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Football (7v7) • KK Nagar Turf', style: TextStyle(fontSize: 11, color: Colors.grey)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? AppColors.primary
                          : (isDark ? AppColors.cardDark : AppColors.borderLight),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: msg.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        if (!msg.isMe)
                          Text(msg.sender, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                        Text(
                          msg.text,
                          style: TextStyle(
                            color: msg.isMe ? Colors.white : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          msg.time,
                          style: TextStyle(
                            fontSize: 9,
                            color: msg.isMe ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick message chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                'Arriving in 10 mins 🏃',
                'Bringing extra ball ⚽',
                'Where is parking entrance?',
                'Ready to play! 🔥',
              ].map((chip) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 11)),
                    onPressed: () => _sendMessage(chip),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),

          // Input Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _msgController,
                    hint: 'Type a message...',
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isMe;
  final String sender;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isMe,
    required this.sender,
    required this.time,
  });
}
