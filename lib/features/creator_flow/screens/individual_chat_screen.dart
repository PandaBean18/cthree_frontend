import 'dart:convert';
import 'package:cthree/core/storage/auth_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cthree/core/models/conversation_model.dart';
import 'package:cthree/core/api/conversation_repository.dart';

class IndividualChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const IndividualChatScreen({super.key, required this.conversation});

  @override
  State<IndividualChatScreen> createState() => _IndividualChatScreenState();
}

class _IndividualChatScreenState extends State<IndividualChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ConversationRepository _conversationRepo = ConversationRepository();
  
  List<Message> _messages = [];
  bool _isLoading = true;
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  Future<void> _initChat() async {
    await _fetchMessageHistory();
    
    await _connectWebSocket();
  }

  Future<void> _fetchMessageHistory() async {
    try {
      final data = await _conversationRepo.getConversationMessages(widget.conversation.id);
      
      setState(() {
        _messages = data ?? [];
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      print("Error fetching history: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      final token =  await AuthStorage.getAccessToken(); 
      
      final wsUrl = Uri.parse('wss://api.ontwynn.com/cable?token=$token');
      
      _channel = WebSocketChannel.connect(wsUrl);

      final subscribeMsg = jsonEncode({
        "command": "subscribe",
        "identifier": '{"channel":"ChatChannel","id":"${widget.conversation.id}"}',
      });
      
      _channel!.sink.add(subscribeMsg);

      _channel!.stream.listen((message) {
        final decoded = jsonDecode(message);
        
        if (decoded['type'] == 'ping') return;
        
        if (decoded['message'] != null) {
          setState(() {
            _messages.add(decoded['message']);
          });
          _scrollToBottom();
          
          if (decoded['message']['sender_label'] == 'sponsor') {
            _markMessageAsRead(decoded['message']['id']);
          }
        }
      });
    } catch (e) {
      print("WebSocket Connection Error: $e");
    }
  }

  void _markMessageAsRead(String messageId) {
    if (_channel == null) return;
    
    final identifier = jsonEncode({
      "channel": "ChatChannel",
      "id": widget.conversation.id
    });

    final data = jsonEncode({
      "action": "read_message",
      "message_id": messageId
    });

    final markReadMsg = jsonEncode({
      "command": "message",
      "identifier": identifier,
      "data": data
    });

    _channel!.sink.add(markReadMsg);
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();

    final tempMessage = Message(
                          id: "temp_${DateTime.now().millisecondsSinceEpoch}", 
                          body: text, 
                          createdAt: DateTime.now(), 
                          senderId: 'currentUser', 
                          sender: 'creator'
                        );

    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();
    _conversationRepo.sendMessageViaSocket(_channel!, widget.conversation.id, text);
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
  void dispose() {
    _channel?.sink.close();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF12151C),
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF1E222A),
              child: Text(
                widget.conversation.campaignTitle[0].toUpperCase(),
                style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.conversation.campaignTitle,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading 
              ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.secondary))
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg.sender == 'creator';
                    return _buildChatBubble(msg, isMe);
                  },
                ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Message msg, bool isMe) {
    // Parse time
    DateTime time;
    try {
      time = msg.createdAt;
    } catch (e) {
      time = DateTime.now();
    }
    final timeStr = DateFormat.jm().format(time);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? Theme.of(context).primaryColor : const Color(0xFF1E222A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
            bottomRight: isMe ? Radius.zero : const Radius.circular(16),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.body,
              style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.3),
            ),
            const SizedBox(height: 4),
            Text(
              timeStr,
              style: TextStyle(
                color: isMe ? Colors.white70 : const Color(0xFF6F7685), 
                fontSize: 10
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12).copyWith(
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF12151C),
        border: Border(top: BorderSide(color: Color(0xFF1E222A), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              textCapitalization: TextCapitalization.sentences,
              maxLines: null, // Allows multiline typing
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: const TextStyle(color: Color(0xFF6F7685)),
                filled: true,
                fillColor: const Color(0xFF1E222A),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary, // Pink accent button
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}