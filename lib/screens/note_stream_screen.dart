import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:soul_note/screens/sync_radar_screen.dart';

class NoteStreamScreen extends StatefulWidget {
  const NoteStreamScreen({super.key});

  @override
  State<NoteStreamScreen> createState() => _NoteStreamScreenState();
}

class _NoteStreamScreenState extends State<NoteStreamScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<NoteMessage> _messages = [
    NoteMessage(
      text: 'Started the new project brainstorm. The local-first architecture feels really snappy. No more spinner anxiety.',
      time: DateTime.now().subtract(const Duration(hours: 3, minutes: 18)),
      isSynced: true,
    ),
    NoteMessage(
      text: 'Remember to check the P2P sync stability when walking between rooms. Bluetooth range is the only limit now. 🛰️',
      time: DateTime.now().subtract(const Duration(hours: 2, minutes: 45)),
      isSynced: true,
    ),
    NoteMessage(
      text: 'Note to self: sage green palette works better for the minimalist aesthetic than deep blue for the branding.',
      time: DateTime.now().subtract(const Duration(hours: 1, minutes: 30)),
      isSynced: true,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCHTU-Wcj1pTu0lJ-EZJOV-OnmfxwhVNpooJZ9HfDepJ3vaWgygWCw_3SguB8TIRc3-j3vZpm5nGYXqwUrCLh8zyL_03BNmnZhf81NEXUFuwf1kKLv6OE4N2yJDqQH5N3zZBY9FKshP9IsdKDElFwPFI5Ukg0BrXl21WusdQO1E7081IqPt48T8EfYG4vKZKdfHF3ripSn_rzCjFb3-XYSCTCLBWqdPCAEZMnDwNDJLKZBoIAqiYI2TsCk1omXCcjPIFvyIZzuZujga',
    ),
    NoteMessage(
      text: 'Meeting notes attached. Local DB performance is looking great with 10k entries.',
      time: DateTime.now().subtract(const Duration(minutes: 2)),
      isSynced: false,
      isRecent: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF101922).withOpacity(0.8),
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF137FEC),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'SoulNote',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'LOCAL STREAM',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: const Color(0xFF137FEC),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SyncRadarScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF137FEC).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.bluetooth_connected,
                          color: const Color(0xFF137FEC),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'P2P Active',
                          style: TextStyle(
                            color: const Color(0xFF137FEC),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.settings_outlined,
                  color: Colors.white.withOpacity(0.6),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C2632),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ..._messages.map((message) => _buildMessageBubble(message)),
              ],
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(NoteMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.85,
            ),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: message.isRecent ? const Color(0xFF137FEC) : const Color(0xFF1C2632),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(4),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              border: !message.isRecent
                  ? Border.all(color: Colors.white.withOpacity(0.05))
                  : null,
              boxShadow: message.isRecent
                  ? [
                      BoxShadow(
                        color: const Color(0xFF137FEC).withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.imageUrl != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      message.imageUrl!,
                      fit: BoxFit.cover,
                      height: 150,
                      width: double.infinity,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: message.isRecent ? Colors.white : Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                DateFormat('h:mm a').format(message.time).toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                message.isSynced ? Icons.done_all : Icons.sync,
                size: 12,
                color: const Color(0xFF137FEC),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101922).withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.1),
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF1C2632),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.add,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C2632),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Capture a thought...',
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          hintStyle: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF137FEC),
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF137FEC).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.send, size: 18),
                      ),
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

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}

class NoteMessage {
  final String text;
  final DateTime time;
  final bool isSynced;
  final bool isRecent;
  final String? imageUrl;

  NoteMessage({
    required this.text,
    required this.time,
    this.isSynced = false,
    this.isRecent = false,
    this.imageUrl,
  });
}
