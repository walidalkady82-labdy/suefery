import 'package:flutter/foundation.dart';
import 'chat_input_bar_io.dart'; // We need this for the input bar's contract
import 'chat_item.dart';           // We need this for the list of bubbles

/// Data class to hold all state information the `ChatView` needs
/// to render itself and its children.
@immutable
class ChatViewInput {
  const ChatViewInput({
    required this.chatItems,
    required this.inputBarInput,
  });

  /// The complete list of all bubbles (text, recipes, auth forms, etc.)
  /// that the `ChatMessageList` should render.
  final List<ChatItem> chatItems;

  /// The complete input data object to be passed down to the
  /// `ChatInputBar` widget.
  final ChatInputBarInput inputBarInput;
}

/// Data class to hold all callback functions that the `ChatView`
/// and its children will call in response to user interactions.
@immutable
class ChatViewCallbacks {
  const ChatViewCallbacks({
    required this.inputBarCallbacks,
    // --- REMOVED: These callbacks are no longer needed ---
    // this.onSignIn,
    // this.onRegister,
  });

  /// The complete callbacks object to be passed down to the
  /// `ChatInputBar` widget.
  final ChatInputBarCallbacks inputBarCallbacks;
  
}