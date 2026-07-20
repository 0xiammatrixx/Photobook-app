import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatService {
  final String baseUrl = 'https://api.photobookhq.com/api';

  Future<List<dynamic>> getConversations({required String token}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conversations'] ?? [];
    }
    throw Exception('Failed to load conversations (${response.statusCode})');
  }

  Future<Map<String, dynamic>> createConversation({
    required String token,
    required String participantId,
    String? initialMessage,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'type': 'direct',
        'participantIds': [participantId],
        if (initialMessage != null) 'initialMessage': initialMessage,
      }),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create conversation (${response.statusCode})');
  }

  Future<Map<String, dynamic>> getMessages({
    required String token,
    required String conversationId,
    String? cursor,
    int limit = 30,
  }) async {
    final uri = Uri.parse(
      '$baseUrl/conversations/$conversationId/messages'
    ).replace(queryParameters: {
      'limit': limit.toString(),
      'markRead': 'true',
      if (cursor != null) 'cursor': cursor,
    });

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load messages (${response.statusCode})');
  }

  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String conversationId,
    required String content,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'content': content}),
    );
    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to send message (${response.statusCode})');
  }
}