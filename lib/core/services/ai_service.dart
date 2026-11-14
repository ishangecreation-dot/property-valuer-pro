import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../security/encryption_service.dart';
import '../../models/deed_data.dart';
import '../../models/survey_plan_data.dart';

/// Real AI Document Extraction Service powered by Gemini / OpenAI APIs.
/// Strictly parses real documents and does NOT silently substitute hardcoded sample data.
class AiService {
  static const String _geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';

  /// Optional mock hook for automated unit tests
  static bool? testConnectionOverride;

  /// Tests connectivity with the configured AI provider and API Key.
  static Future<bool> testConnection() async {
    if (testConnectionOverride != null) {
      return testConnectionOverride!;
    }

    final apiKey = await EncryptionService.getAiApiKey();
    if (apiKey.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('$_geminiBaseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping test. Reply with OK.'}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 12));

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Extracts Title Deed Details (15 fields from SKILL.md) using Gemini Vision API.
  static Future<DeedData> extractDeed({
    required List<String> filePaths,
    Function(String)? onProgress,
  }) async {
    final apiKey = await EncryptionService.getAiApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'AI API Key is not configured. Please open Admin Settings (gear icon in the top right) and enter your Gemini API Key.',
      );
    }

    if (filePaths.isEmpty) {
      throw Exception('No document file or photo was selected. Please attach a title deed file.');
    }

    onProgress?.call('Compressing document pages for extraction...');
    final parts = <Map<String, dynamic>>[];

    // Read and attach up to 3 document images/pages
    for (final path in filePaths.take(3)) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        final ext = path.toLowerCase();
        String mimeType = 'image/jpeg';
        if (ext.endsWith('.png')) mimeType = 'image/png';
        if (ext.endsWith('.pdf')) mimeType = 'application/pdf';

        parts.add({
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Encode(bytes),
          }
        });
      }
    }

    onProgress?.call('Calling Gemini Vision OCR model...');

    final promptText = '''
You are a senior real estate title deed examiner in Sri Lanka.
Analyze the attached deed images and extract the following 15 fields strictly in valid JSON format:
{
  "deedNumber": string,
  "executionDate": string,
  "notaryPublicName": string,
  "notaryPublicStation": string,
  "landRegistry": string,
  "registrationDate": string,
  "dayBookNumber": string,
  "registerFolioNumber": string,
  "vendeeName": string,
  "vendeeNic": string,
  "vendeeAddress": string,
  "vendorName": string,
  "vendorNic": string,
  "vendorAddress": string,
  "purchaseConsideration": number
}
If any field is obscured or unreadable, mark it as empty string "" and do not invent details.
''';

    parts.add({'text': promptText});

    try {
      final response = await http.post(
        Uri.parse('$_geminiBaseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': parts}],
          'generationConfig': {
            'temperature': 0.1,
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        if (response.statusCode == 400 || response.statusCode == 401 || response.statusCode == 403) {
          throw Exception('AI API Key is invalid or unauthorized (HTTP ${response.statusCode}). Please verify your key in Settings.');
        }
        throw Exception('Gemini API returned HTTP ${response.statusCode}: ${response.body}');
      }

      final jsonResp = jsonDecode(response.body);
      final rawContent = jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final cleanJson = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> extractedMap = jsonDecode(cleanJson);

      onProgress?.call('Extraction complete. Populating deed fields...');

      final deed = DeedData.fromJson(extractedMap);
      deed.documentFilePaths = filePaths;

      // Mark uncertain fields if empty
      extractedMap.forEach((key, val) {
        if (val == null || (val is String && val.trim().isEmpty)) {
          deed.uncertainFields[key] = true;
        }
      });

      return deed;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to extract deed data: $e');
    }
  }

  /// Extracts Survey Plan Details (Lot, Extent, Boundaries) using Gemini Vision API.
  static Future<SurveyPlanData> extractSurveyPlan({
    required List<String> filePaths,
    Function(String)? onProgress,
  }) async {
    final apiKey = await EncryptionService.getAiApiKey();
    if (apiKey.isEmpty) {
      throw Exception('AI API Key is not configured. Please open Admin Settings and enter your Gemini API Key.');
    }

    if (filePaths.isEmpty) {
      throw Exception('No survey plan document was selected.');
    }

    onProgress?.call('Preprocessing survey plan image...');
    final parts = <Map<String, dynamic>>[];

    for (final path in filePaths.take(2)) {
      final file = File(path);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        parts.add({
          'inline_data': {
            'mime_type': 'image/jpeg',
            'data': base64Encode(bytes),
          }
        });
      }
    }

    final promptText = '''
You are a licensed cadastral surveyor and real estate valuer in Sri Lanka.
Analyze the attached survey plan and extract the particulars strictly in valid JSON format:
{
  "planNumber": string,
  "surveyDate": string,
  "surveyorName": string,
  "surveyorQualifications": string,
  "landName": string,
  "villageOrLocality": string,
  "localAuthority": string,
  "koraleOrDivision": string,
  "district": string,
  "province": string,
  "lots": [
    {
      "lotNumber": string,
      "acres": number,
      "roods": number,
      "perches": number,
      "hectares": number,
      "squareMeters": number
    }
  ],
  "boundaries": {
    "north": string,
    "south": string,
    "east": string,
    "west": string
  }
}
If any extent is unreadable, do not assume or invent values.
''';

    parts.add({'text': promptText});

    try {
      onProgress?.call('Analyzing cadastral boundaries with Gemini Vision...');
      final response = await http.post(
        Uri.parse('$_geminiBaseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': parts}],
          'generationConfig': {
            'temperature': 0.1,
            'responseMimeType': 'application/json',
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode != 200) {
        throw Exception('Survey extraction returned HTTP ${response.statusCode}: ${response.body}');
      }

      final jsonResp = jsonDecode(response.body);
      final rawContent = jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final cleanJson = rawContent.replaceAll('```json', '').replaceAll('```', '').trim();
      final Map<String, dynamic> extractedMap = jsonDecode(cleanJson);

      onProgress?.call('Processing surveyed lots and boundaries...');

      final plan = SurveyPlanData.fromJson(extractedMap);
      plan.planFilePaths = filePaths;
      return plan;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to extract survey plan: $e');
    }
  }

  /// Polishes raw inspection notes or driving directions into formal Chartered Valuation terminology
  static Future<String> polishValuationLanguage(String rawText) async {
    final apiKey = await EncryptionService.getAiApiKey();
    if (apiKey.isEmpty || rawText.trim().isEmpty) return rawText;

    try {
      final response = await http.post(
        Uri.parse('$_geminiBaseUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      'Rewrite the following access and driving directions into formal, professional real estate valuation report terminology suitable for a Chartered Valuation Report in Sri Lanka. Return only the revised paragraph:\n\n$rawText'
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final jsonResp = jsonDecode(response.body);
        return jsonResp['candidates']?[0]?['content']?['parts']?[0]?['text']?.trim() ?? rawText;
      }
    } catch (_) {}

    return rawText;
  }
}
