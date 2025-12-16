import 'package:flutter/material.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_view_io.dart';
import 'chat_input_bar.dart';
import 'chat_message_list.dart';

/// A "dumb" UI widget for the main chat view.
///
/// It receives all its data via [input] and reports all user actions
/// via [callbacks]. It is stateful only to manage the [ScrollController].
class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.input,
    required this.callbacks,
  });

  final ChatViewInput input;
  final ChatViewCallbacks callbacks;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if new items were added to the list.
    // This is how we trigger a scroll-to-bottom from a "dumb" widget.
    if (widget.input.chatItems.length > oldWidget.input.chatItems.length) {
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    // A short delay ensures the list has built the new item
    // before we try to scroll.
    Future.delayed(const Duration(milliseconds: 50), () {
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
    return Column(
      children: [
        // 1. The Chat Message List
        Expanded(
          child: ChatMessageList(
            scrollController: _scrollController,
            // Pass the list of UI models to render
            chatItems: widget.input.chatItems,
            // Pass the callbacks (for auth forms, etc.)
            callbacks: widget.callbacks,
          ),
        ),

        // 2. The Chat Input Bar
        ChatInputBar(
          // Pass the input data for the bar
          input: widget.input.inputBarInput,
          // Pass the callbacks for the bar
          callbacks: widget.callbacks.inputBarCallbacks,
        ),
      ],
    );
  }
}