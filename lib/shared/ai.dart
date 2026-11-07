/// OpenRouter AI adapter.
///
/// Contract notes honored here:
/// - AI output is NEVER treated as safety evidence. Anything the model
///   suggests must still pass the deterministic allergen filter before it is
///   shown as a meal option. An LLM cannot declare an ingredient safe.
/// - Feature is gated by the `aiProcessing` consent flag and adult role.
/// - API key is injected via `--dart-define=OPENROUTER_API_KEY`. For
///   production this call must move behind a Supabase Edge Function so the
///   key never ships in the client; the client surface is identical.
/// - Model and endpoint are overridable via dart-defines; failures fall back
///   to an honest "unavailable" state, never fabricated content.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'models.dart';

class OpenRouterConfig {
  const OpenRouterConfig();

  static const apiKey = String.fromEnvironment('OPENROUTER_API_KEY');
  static const baseUrl = String.fromEnvironment('OPENROUTER_BASE_URL', defaultValue: 'https://openrouter.ai/api/v1');
  static const model = String.fromEnvironment('OPENROUTER_MODEL', defaultValue: 'openrouter/auto');
  static const appName = String.fromEnvironment('OPENROUTER_APP_NAME', defaultValue: 'Family Circle');

  static bool get configured => apiKey.isNotEmpty;
}

class AiResult {
  const AiResult({required this.text, required this.model, required this.isAiGenerated});

  final String text;
  final String model;

  /// Always true for model output — UI must label it.
  final bool isAiGenerated;
}

class OpenRouterClient {
  OpenRouterClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// One-shot chat completion. Throws [FcException.validation] when
  /// unconfigured; callers treat transport failures as unavailable.
  Future<AiResult> complete(List<Map<String, String>> messages, {int maxTokens = 400, double temperature = 0.7}) async {
    if (!OpenRouterConfig.configured) {
      throw const FcException(FcErrorCode.validation, 'AI is not configured on this device.');
    }
    final uri = Uri.parse('${OpenRouterConfig.baseUrl}/chat/completions');
    final res = await _http
        .post(
          uri,
          headers: {
            'Authorization': 'Bearer ${OpenRouterConfig.apiKey}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://familycircle.local',
            'X-Title': OpenRouterConfig.appName,
          },
          body: jsonEncode({
            'model': OpenRouterConfig.model,
            'messages': messages,
            'max_tokens': maxTokens,
            'temperature': temperature,
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw FcException(FcErrorCode.validation, 'AI request failed (${res.statusCode}).');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final choices = body['choices'] as List?;
    final content = choices?.firstOrNull?['message']?['content'];
    if (content is! String || content.trim().isEmpty) {
      throw const FcException(FcErrorCode.validation, 'AI returned an empty answer.');
    }
    return AiResult(text: content.trim(), model: body['model'] as String? ?? OpenRouterConfig.model, isAiGenerated: true);
  }

  void dispose() => _http.close();
}

/// Builds the privacy-minimized prompt for a household meal idea. Sends only
/// non-identifying data: allergen keys, verified ingredient names, budget
/// presence — never names, events history, or child data.
List<Map<String, String>> mealIdeaPrompt({
  required Set<String> hardAllergens,
  required List<String> safeIngredientNames,
  required int servings,
  MealType? meal,
}) {
  return [
    {
      'role': 'system',
      'content':
          'You suggest one family meal idea. Rules: use only the listed verified-safe ingredients; never claim allergy safety; output dish name, 3-4 short steps, and which listed ingredients it uses. Plain text, no markdown.',
    },
    {
      'role': 'user',
      'content':
          'Hard allergens to avoid: ${hardAllergens.isEmpty ? 'none reported' : hardAllergens.join(', ')}. '
              'Verified-safe ingredients available: ${safeIngredientNames.join(', ')}. '
              'Servings needed: $servings. ${meal == null ? '' : 'Course: ${meal.label}.'} '
              'Give one realistic weeknight meal.',
    },
  ];
}
