import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import '../services/ai_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/gamification_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/stats_bar.dart';
import '../widgets/badge_toast.dart';
import 'leaderboard_screen.dart';

class ChatScreen extends StatefulWidget {
  final UserProfile profile;
  const ChatScreen({super.key, required this.profile});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AIService _aiService = AIService();
  final FirestoreService _firestoreService = FirestoreService();
  final GamificationService _gamificationService = GamificationService();
  final AuthService _authService = AuthService();

  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  bool _sending = false;

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _sending) return;

    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _inputController.clear();
      _sending = true;
    });
    _scrollToBottom();

    try {
      final reply = await _aiService.sendMessage(
        userMessage: text,
        interests: widget.profile.interests,
        history: _messages,
      );

      setState(() {
        _messages.add(ChatMessage(
          text: reply,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
      });

      // Gamification: award points/streak/badges for this interaction.
      final result = _gamificationService.registerInteraction(widget.profile);
      await _firestoreService.applyGamificationUpdate(
        widget.profile.uid,
        result.updateFields,
      );
      if (mounted && result.newBadges.isNotEmpty) {
        showBadgeToast(context, result.newBadges);
      }
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Something went wrong reaching the AI: $e',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds with the live profile via StreamBuilder in AuthGate would
    // normally flow the updated points/streak down; for simplicity this
    // screen listens to its own stream so the stats bar stays live.
    return StreamBuilder<UserProfile>(
      stream: _firestoreService.watchUserProfile(widget.profile.uid),
      initialData: widget.profile,
      builder: (context, snapshot) {
        final profile = snapshot.data ?? widget.profile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI Companion'),
            actions: [
              IconButton(
                icon: const Icon(Icons.leaderboard_outlined),
                tooltip: 'Leaderboard',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LeaderboardScreen()),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign out',
                onPressed: () => _authService.signOut(),
              ),
            ],
          ),
          body: Column(
            children: [
              StatsBar(profile: profile),
              Expanded(
                child: _messages.isEmpty
                    ? Center(
                  child: Text(
                    'Ask me anything — I\'ll tailor it to '
                        '${profile.interests.isEmpty ? "you" : profile.interests.join(", ")}.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) =>
                      ChatBubble(message: _messages[index]),
                ),
              ),
              if (_sending)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: const InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.send),
                        onPressed: _sending ? null : _sendMessage,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
