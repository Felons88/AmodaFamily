/// AI adapter — calls the `ai-meal-idea` Supabase Edge Function, which owns
/// the OpenRouter key server-side. The APK carries no AI secrets; the
/// publishable Supabase anon key is designed for client use (RLS protects
/// data, and this function only accepts the minimal prompt payload below).
///
/// Contract notes honored here:
/// - AI output is NEVER treated as safety evidence. The hard allergen filter
///   always decides what is safe; the model only receives already-verified
///   ingredient names.
/// - Gated by the `aiProcessing` consent flag and adult role upstream.
/// - Failures fall back to an honest "unavailable" state.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'errors.dart';
import 'models.dart';

class AiConfig {
  const AiConfig();

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  static bool get configured =>
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static Uri get functionUri =>
      Uri.parse('$supabaseUrl/functions/v1/ai-meal-idea');
}

class AiResult {
  const AiResult({
    required this.text,
    required this.model,
    required this.isAiGenerated,
  });

  final String text;
  final String model;

  /// Always true for model output — UI must label it.
  final bool isAiGenerated;
}

class AiMealIdeaClient {
  AiMealIdeaClient({http.Client? httpClient})
    : _http = httpClient ?? http.Client();

  final http.Client _http;

  /// Sends only privacy-minimized inputs: allergen keys, verified-safe
  /// ingredient names, servings and meal type.
  Future<AiResult> mealIdea({
    required Set<String> hardAllergens,
    required List<String> safeIngredientNames,
    required int servings,
    MealType? meal,
  }) async {
    if (!AiConfig.configured) {
      throw const FcException(
        FcErrorCode.validation,
        'AI is not configured on this device.',
      );
    }
    final res = await _http
        .post(
          AiConfig.functionUri,
          headers: {
            'Authorization': 'Bearer ${AiConfig.supabaseAnonKey}',
            'apikey': AiConfig.supabaseAnonKey,
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'allergens': hardAllergens.toList(),
            'ingredients': safeIngredientNames,
            'servings': servings,
            'meal': meal?.name ?? 'dinner',
          }),
        )
        .timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      throw FcException(FcErrorCode.validation, 'AI is unavailable right now.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final text = body['text'];
    if (text is! String || text.trim().isEmpty) {
      throw const FcException(
        FcErrorCode.validation,
        'AI returned an empty answer.',
      );
    }
    return AiResult(
      text: text.trim(),
      model: body['model'] as String? ?? 'ai',
      isAiGenerated: true,
    );
  }

  void dispose() => _http.close();
}
