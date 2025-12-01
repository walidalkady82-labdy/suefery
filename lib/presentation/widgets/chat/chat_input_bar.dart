import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:suefery/presentation/widgets/chat/models/chat_input_bar_io.dart';
import 'package:suefery/locator.dart';
import 'package:suefery/data/model/model_suggestion.dart'; // Import new model
import 'package:suefery/data/service/service_suggestion.dart'; // Import new service
import '../../../data/enum/suggestion_type.dart';

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
          // IconButton(
          //   icon: const Icon(Icons.add_circle_outline),
          //   // Call the callback provided by the parent
          //   onPressed: widget.callbacks.onShowActionMenu,
          // ),

          // --- Text Input Field ---
          // --- Autocomplete Text Input ---
          Expanded(
            child: TypeAheadField<ModelSuggestion>(
              controller: _controller,
              
              // 1. FETCH SUGGESTIONS
              suggestionsCallback: (pattern) async {
                if (pattern.trim().isEmpty) return [];
                // Use the mixed service instead of just brands
                return await sl<ServiceSuggestion>().getMixedSuggestions(pattern);
              },

              // 2. DISPLAY INPUT FIELD
              builder: (context, controller, focusNode) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onChanged: widget.callbacks.onTyping,
                  decoration: InputDecoration(
                    hintText: widget.input.hintText,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, 
                      vertical: 10
                    ),
                  ),
                  minLines: 1,
                  maxLines: 5,
                );
              },

              // 3. CONFIGURE SUGGESTION LIST
              itemBuilder: (context, ModelSuggestion suggestion) {
                // 1. DECIDE ICON BASED ON TYPE
              IconData icon;
              Color iconColor;
              
              switch (suggestion.type) {
                case SuggestionType.brand:
                  icon = Icons.local_grocery_store_outlined;
                  iconColor = Colors.blue;
                  break;
                case SuggestionType.category:
                  icon = Icons.category_outlined;
                  iconColor = Colors.orange;
                  break;
                case SuggestionType.command:
                  icon = Icons.assistant;
                  iconColor = Colors.purple;
                  break;
                default:
                  icon = Icons.history;
                  iconColor = Colors.grey;
              }
                return ListTile(
                  dense: true,
                  leading: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: iconColor.withAlpha(26),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 18, color: iconColor),
                  ),
                  title: Text(suggestion.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  subtitle: suggestion.subtitle != null 
                      ? Text(suggestion.subtitle!, style: const TextStyle(fontSize: 11, color: Colors.grey)) 
                      : null,
                );
              },

              // 4. HANDLE SELECTION
              onSelected: (ModelSuggestion suggestion) {
                // Append the selected brand to the text
                // Or simply replace the text if you prefer
                _controller.text = suggestion.title; 
                
                // Move cursor to end
                _controller.selection = TextSelection.fromPosition(
                  TextPosition(offset: _controller.text.length)
                );
              },

              // 5. APPEARANCE TWEAKS (Show ABOVE the bar)
              direction: VerticalDirection.up, // Important for chat apps!
              hideOnEmpty: true,
              hideOnError: true,
              constraints: const BoxConstraints(maxHeight: 200),
              decorationBuilder: (context, child) {
                return Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surface,
                  child: child,
                );
              },
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