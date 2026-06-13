import 'package:cthree/core/api/conversation_repository.dart';
import 'package:cthree/core/models/conversation_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cthree/features/creator_flow/screens/individual_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override  
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final ConversationRepository _conversationRepository = ConversationRepository();
  List<ConversationModel> _conversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchConversations();
  }

  Future<void> _fetchConversations() async {
    final List<ConversationModel>? data = await _conversationRepository.getConversations();

    if (mounted) {
      setState(() {
        _conversations = data ?? [];
        _isLoading = false;
      });
    }

  }

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return DateFormat.jm().format(date);
    } else if (dateToCheck == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('dd/MM/yy').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
          // todo: add search button
        ),
      ),
      body: _isLoading
      ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary,),)
      : ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _conversations.length,
        separatorBuilder: (context, index) => Divider(color: Theme.of(context).colorScheme.surface, height: 1),
        itemBuilder: (context, index) {
          final chat = _conversations[index];
          return _buildChatTile(chat);

        },
      ),
    );
  }

  Widget _buildChatTile(ConversationModel chat) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IndividualChatScreen(conversation: chat),
          ),
        );
      },
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Text(
          chat.campaignTitle[0].toUpperCase(),
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),

        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chat.campaignTitle,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.clip,
            ),
          ),
          Text(
            _formatTimestamp(chat.latestMessage!.createdAt),
            style: const TextStyle(color: Color(0xFF6F7685), fontSize: 12),
          ),
        ],
      ),
      subtitle: Padding(
        padding: EdgeInsetsGeometry.only(top: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "${chat.latestMessage!.sender == 'creator' ? 'You' : 'Sponsor'}: ${chat.latestMessage!.body}",
                style: TextStyle(
                  color: (chat.latestMessage!.readAt == null) ? Colors.white70 : const Color(0xFF6F7685),
                  fontSize: 14,
                  fontWeight: (chat.latestMessage!.readAt == null)? FontWeight.w600 : FontWeight.normal
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.latestMessage!.readAt == null && chat.latestMessage!.sender == 'Sponsor')
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.secondary, shape: BoxShape.circle),
              )
          ],
        ),
      ),
    );
  }
}