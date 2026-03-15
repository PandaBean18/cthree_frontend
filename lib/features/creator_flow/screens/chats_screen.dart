import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override  
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final List<Map<String, dynamic>> _mockChats = [
    {
      "campaign": "Nadidas Air Shoe Launch",
      "lastMessage": "Yeah try to keep it atleast 45 seconds long",
      "sender": "Sponsor",
      "timestamp": DateTime.now(),
      "isUnread": true,
    },
    {
      "campaign": "BlueBull Summer Series",
      "lastMessage": "okay",
      "sender": "You",
      "timestamp": DateTime.now().subtract(const Duration(days: 1)),
      "isUnread": false,
    },
    {
      "campaign": "Abode Creative Writing",
      "lastMessage": "Can we adjust the caption for the second post?",
      "sender": "Sponsor",
      "timestamp": DateTime.now().subtract(const Duration(days: 4)), 
      "isUnread": false,
    },
  ];

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
      body: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _mockChats.length,
        separatorBuilder: (context, index) => Divider(color: Theme.of(context).colorScheme.surface, height: 1),
        itemBuilder: (context, index) {
          final chat = _mockChats[index];
          return _buildChatTile(chat);

        },
      ),
    );
  }

  Widget _buildChatTile(Map<String, dynamic> chat) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      onTap: () {},
      leading: CircleAvatar(
        radius: 28,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: Text(
          chat['campaign'][0].toUpperCase(),
          style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),

        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              chat['campaign'],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              overflow: TextOverflow.clip,
            ),
          ),
          Text(
            _formatTimestamp(chat['timestamp']),
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
                "${chat['sender']}: ${chat['lastMessage']}",
                style: TextStyle(
                  color: chat['isUnread'] ? Colors.white70 : const Color(0xFF6F7685),
                  fontSize: 14,
                  fontWeight: chat['isUnread'] ? FontWeight.w600 : FontWeight.normal
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat['isUnread'])
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