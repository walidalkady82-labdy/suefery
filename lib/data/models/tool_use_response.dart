import 'package:flutter/foundation.dart';

/// A standardized response from the FirebaseAiService.
/// It will either contain a tool to call or a simple text response.
@immutable
class ToolUseResponse {
  final bool isToolCall;
  final String? toolName;
  final Map<String, dynamic>? arguments;
  final String? textResponse;

  const ToolUseResponse({
    this.isToolCall = false,
    this.toolName,
    this.arguments,
    this.textResponse,
  });

  /// Factory for a simple text response
  factory ToolUseResponse.text(String text) {
    return ToolUseResponse(textResponse: text);
  }

  /// Factory for a tool call response
  factory ToolUseResponse.tool(String name, Map<String, dynamic> args) {
    return ToolUseResponse(
      isToolCall: true,
      toolName: name,
      arguments: args,
    );
  }

  /// Factory for an error response
  factory ToolUseResponse.error(String errorText) {
    return ToolUseResponse(textResponse: errorText);
  }
}