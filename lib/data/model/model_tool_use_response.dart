import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A standardized response from the FirebaseAiService.
/// It will either contain a tool to call or a simple text response.
@immutable
class ModelToolUseResponse extends Equatable {
  final bool isToolCall;
  final String? toolName;
  final Map<String, dynamic>? arguments;
  final String? textResponse;

  const ModelToolUseResponse({
    this.isToolCall = false,
    this.toolName,
    this.arguments,
    this.textResponse,
  });

  /// Factory for a simple text response
  factory ModelToolUseResponse.text(String text) {
    return ModelToolUseResponse(textResponse: text);
  }

  /// Factory for a tool call response
  factory ModelToolUseResponse.tool(String name, Map<String, dynamic> args) {
    return ModelToolUseResponse(
      isToolCall: true,
      toolName: name,
      arguments: args,
    );
  }

  /// Factory for an error response
  factory ModelToolUseResponse.error(String errorText) {
    return ModelToolUseResponse(textResponse: errorText);
  }

  @override
  List<Object?> get props => [
        isToolCall,
        toolName,
        arguments,
        textResponse,
      ];
}


