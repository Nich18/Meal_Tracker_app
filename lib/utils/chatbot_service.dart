import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String apiKey = 'vMUdvD182yzv5ijwsncHNU9ddp9dLqcwX302rFp1';

  Future<String> getBotResponse(String userMessage) async {
  final Uri apiUrl = Uri.parse('https://api.cohere.ai/v1/generate');

  try {
    final response = await http.post(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'prompt': userMessage,
        'max_tokens': 100,
        'temperature': 0.7,
      }),
    );

    print('Status code: ${response.statusCode}');
    print('Raw response body: ${response.body}'); // Pour débogage

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final generations = responseData['generations'] as List?;
      if (generations != null && generations.isNotEmpty) {
        final textResponse = generations[0]['text']?.toString();
        return textResponse ?? "Réponse vide.";
      } else {
        return "Aucune génération disponible.";
      }
    } else {
      print('Error response body: ${response.body}');
      return "Erreur avec l'API Cohere.";
    }
  } catch (e) {
    print('Exception: $e');
    return "Erreur lors de la connexion au chatbot.";
  }
}

}
