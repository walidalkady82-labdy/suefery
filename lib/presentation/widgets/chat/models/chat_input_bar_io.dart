import 'package:flutter/foundation.dart';

/// This class passes data *into* the ChatInputBar
/// to tell it what state to render (e.g., show a loading
/// indicator or a hint text).
@immutable
class ChatInputBarInput {
  final bool isLoading;
  final bool isTyping;
  final String hintText;
  final bool isDisabled;

  const ChatInputBarInput({
    this.isLoading = false,
    this.isTyping = false,
    this.hintText = 'Type a message...',
    this.isDisabled = false, 
  });
}

/// This class sends events *out of* the ChatInputBar
/// when the user performs an action (e.g., taps the
/// send button or the voice button).
@immutable
class ChatInputBarCallbacks {
  final void Function(String) onSendMessage;
  final void Function(String) onTyping;
  final VoidCallback onShowActionMenu;
  final VoidCallback onSendVoiceOrder;

  const ChatInputBarCallbacks({
    required this.onSendMessage,
    required this.onTyping,
    required this.onShowActionMenu,
    required this.onSendVoiceOrder,
  });

  /// A factory for disabled callbacks.
  /// This provides empty functions to prevent null errors
  /// when the input bar is disabled.
  factory ChatInputBarCallbacks.disabled() {
    return ChatInputBarCallbacks(
      onSendMessage: (_) {},
      onTyping: (_) {},
      onShowActionMenu: () {},
      onSendVoiceOrder: () {},
    );
  }
}