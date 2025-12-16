import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:suefery/core/utils/logger.dart';
import 'package:suefery/data/enum/message_sender.dart';

import '../model/model_chat_message.dart';
import '../model/model_tool_use_response.dart';

class ServiceFirebaseAi with LogMixin{
  final FirebaseFunctions _functions;

  ServiceFirebaseAi(this._functions);

  /// --- REPLACES ALL OTHER METHODS ---
  /// Gets a structured response from the AI, which will be
  /// either a tool call or a simple text message.
  Future<ModelToolUseResponse> getStructuredResponse(List<ModelChatMessage> history) async {
    // if (_useMocks) {
    //   logInfo("FirebaseAiService: Using MOCK for getStructuredResponse()");
    //   return _getMockResponse(history.last.content ?? "");
    // }

    try {
      logInfo('Calling geminiProxy with tool definitions...');
      final callable = _functions.httpsCallable('geminiProxy');
      
      final response = await callable.call<Map<String, dynamic>>({
        'history': history
            .map((m) => {
                  'role': m.senderType == MessageSender.user ? 'user' : 'model',
                  'text': m.content,
                })
            .toList(),
      });

      logInfo('Successfully received structured response from geminiProxy.');

      // --- Parse the AI's response ---
      final data = response.data;

      // Check if the AI wants to call a tool
      if (data.containsKey('toolCall')) {
        final toolCall = data['toolCall'] as Map;
        final toolName = toolCall['name'] as String;
        final arguments = Map<String, dynamic>.from(toolCall['arguments'] as Map);
        
        return ModelToolUseResponse.tool(toolName, arguments);
      }
      
      // Otherwise, it's a simple text response
      final text = data['text'] as String? ?? "Sorry, I'm not sure how to help with that.";
      return ModelToolUseResponse.text(text);

    } on FirebaseFunctionsException catch (e, s) {
      logError('FunctionsException calling geminiProxy: ${e.message}', stackTrace: s);
      return ModelToolUseResponse.error('Sorry, I\'m having trouble connecting. Please try again.');
    } catch (e, s) {
      logError('Generic error calling geminiProxy: $e', stackTrace: s);
      rethrow;
    }
  }
}
 
