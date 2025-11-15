import 'package:flutter/material.dart';
import 'package:suefery/core/widgets/chat/models/chat_input_bar_io.dart';

class ChatInputBar extends StatefulWidget {
  const ChatInputBar({
    super.key,
    required this.input,
    required this.callbacks,
  });

  final ChatInputBarInput input;
  final ChatInputBarCallbacks callbacks;

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  final TextEditingController _controller = TextEditingController();

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      // Call the parent's callback with the message
      widget.callbacks.onSendMessage(text);
      
      // Clear the text field
      _controller.clear();
      
      // Notify the parent that typing has stopped
      widget.callbacks.onTyping('');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // --- Action Menu Button ---
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            // Call the callback provided by the parent
            onPressed: widget.callbacks.onShowActionMenu,
          ),

          // --- Text Input Field ---
          Expanded(
            child: TextField(
              controller: _controller,
              // Call the typing callback on every change
              onChanged: widget.callbacks.onTyping,
              decoration: InputDecoration(
                hintText: widget.input.hintText,
              ),
              minLines: 1,
              maxLines: 5,
            ),
          ),
          const SizedBox(width: 4),

          // --- Send/Voice Button ---
          FloatingActionButton(
            mini: true,
            // Use the input data to configure the button's appearance
            backgroundColor: widget.input.isLoading
                ? Colors.grey // Disabled color
                : Theme.of(context).colorScheme.primary,
            
            // Use the input data to disable the button
            onPressed: widget.input.isLoading
                ? null // This disables the button
                : () {
                    // Use input data to decide which callback to call
                    if (widget.input.isTyping) {
                      _handleSendMessage();
                    } else {
                      widget.callbacks.onSendVoiceOrder();
                    }
                  },
            // Use input data to set the icon
            child: Icon(widget.input.isTyping ? Icons.send : Icons.mic),
          ),
        ],
      ),
    );
  }
}