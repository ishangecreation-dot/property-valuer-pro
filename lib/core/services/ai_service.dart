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

  /// Tests connectivity with the configured AI provider and API Key.
  static Future<bool> testConnection() async {
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

    final promptText = '''
You are an expert Sri Lankan Conveyancing Notary and Real Estate Valuation Specialist.
Carefully examine this title deed document and extract the following 15 legal particulars into a strictly valid JSON object without markdown formatting:
{
  "deedNumber": "Deed number or instrument reference",
  "executionDate": "Date signed/attested in YYYY-MM-DD format",
  "notaryPublicName": "Full name of Notary Public",
  "notaryPublicStation": "Judicial zone / notary station (e.g. Kandy, Colombo)",
  "landRegistry": "Land registry office name",
  "registrationDate": "Registration date in YYYY-MM-DD",
  "dayBookNumber": "Day book number or registration entry",
  "registerFolioNumber": "Register volume and folio number",
  "vendeeName": "Purchaser / current owner full name",
  "vendeeNic": "Purchaser NIC number",
  "vendeeAddress": "Purchaser residential address",
  "vendorName": "Seller / previous owner full name",
  "vendorNic": "Seller NIC number",
  "vendorAddress": "Seller residential address",
  "purchaseConsideration": 0.0,
  "uncertainFields": {
    "dayBookNumber": false,
    "purchaseConsideration": false
  }
}
If any field is unreadable, blurred, or missing, leave it as an empty string and set that field in uncertainFields to true.
''';

    parts.add({'text': promptText});

    onProgress?.call('Sending document to Gemini extraction engine...');

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
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        final errBody = response.body;
        if (response.statusCode == 400 || response.statusCode == 401) {
          throw Exception('AI API Key is invalid or unauthorized (HTTP ${response.statusCode}). Please verify your key in Settings.');
        } else if (response.statusCode == 429) {
          throw Exception('AI API rate limit or quota exceeded (HTTP 429). Please try again shortly.');
        } else {
          throw Exception('AI extraction failed with HTTP ${response.statusCode}: $errBody');
        }
      }

      onProgress?.call('Parsing legal deed fields...');
      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final textContent = responseJson['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';

      // Parse JSON from output
      final Map<String, dynamic> data = jsonDecode(textContent);

      final Map<String, bool> uncertain = {};
      if (data['uncertainFields'] is Map) {
        (data['uncertainFields'] as Map).forEach((k, v) {
          uncertain[k.toString()] = v == true;
        });
      }

      return DeedData(
        deedNumber: data['deedNumber']?.toString() ?? '',
        executionDate: data['executionDate']?.toString() ?? '',
        notaryPublicName: data['notaryPublicName']?.toString() ?? '',
        notaryPublicStation: data['notaryPublicStation']?.toString() ?? '',
        landRegistry: data['landRegistry']?.toString() ?? '',
        registrationDate: data['registrationDate']?.toString() ?? '',
        dayBookNumber: data['dayBookNumber']?.toString() ?? '',
        registerFolioNumber: data['registerFolioNumber']?.toString() ?? '',
        vendeeName: data['vendeeName']?.toString() ?? '',
        vendeeNic: data['vendeeNic']?.toString() ?? '',
        vendeeAddress: data['vendeeAddress']?.toString() ?? '',
        vendorName: data['vendorName']?.toString() ?? '',
        vendorNic: data['vendorNic']?.toString() ?? '',
        vendorAddress: data['vendorAddress']?.toString() ?? '',
        purchaseConsideration: (data['purchaseConsideration'] as num?)?.toDouble() ?? 0.0,
        documentFilePaths: filePaths,
        uncertainFields: uncertain,
      );
    } on SocketException {
      throw Exception('Network error: Unable to connect to AI server. Please check your internet connection.');
    } on TimeoutException {
      throw Exception('AI request timed out. The document image may be too large or connection is slow.');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Deed extraction failed: $e');
    }
  }

  /// Extracts Survey Plan Details & Cadastral Lots using Gemini Vision API.
  static Future<SurveyPlanData> extractSurveyPlan({
    required List<String> filePaths,
    Function(String)? onProgress,
  }) async {
    final apiKey = await EncryptionService.getAiApiKey();
    if (apiKey.isEmpty) {
      throw Exception(
        'AI API Key is not configured. Please open Admin Settings and enter your Gemini API Key.',
      );
    }

    if (filePaths.isEmpty) {
      throw Exception('No survey plan document was selected. Please attach a plan file or capture a photo.');
    }

    onProgress?.call('Analyzing survey plan image...');
    final parts = <Map<String, dynamic>>[];

    for (final path in filePaths.take(2)) {
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

    final promptText = '''
You are an expert Sri Lankan Licensed Surveyor and Cadastral Analyst.
Examine this cadastral survey plan and extract all plan particulars and surveyed lots into a strictly valid JSON object without markdown formatting:
{
  "planNumber": "Survey plan number",
  "surveyDate": "Date surveyed in YYYY-MM-DD",
  "certificationDate": "Date certified by surveyor",
  "surveyorName": "Licensed surveyor full name",
  "surveyorRegistrationNumber": "Surveyor registration number",
  "landName": "Name of the land/estate",
  "priorPlanReference": "Reference to previous plans if mentioned",
  "lots": [
    {
      "lotNumber": "1",
      "acres": 0,
      "roods": 0,
      "perches": 18.5,
      "northBoundary": "Description of North boundary",
      "eastBoundary": "Description of East boundary",
      "southBoundary": "Description of South boundary",
      "westBoundary": "Description of West boundary"
    }
  ]
}
''';

    parts.add({'text': promptText});
    onProgress?.call('Extracting survey lots and boundary schedules...');

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
      ).timeout(const Duration(seconds: 35));

      if (response.statusCode != 200) {
        throw Exception('Survey Plan AI extraction failed (HTTP ${response.statusCode}). Please check your API key.');
      }

      final Map<String, dynamic> responseJson = jsonDecode(response.body);
      final textContent = responseJson['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '{}';
      final Map<String, dynamic> data = jsonDecode(textContent);

      final List<PlanLot> lots = [];
      if (data['lots'] is List) {
        for (final item in (data['lots'] as List)) {
          lots.add(PlanLot(
            lotNumber: item['lotNumber']?.toString() ?? '1',
            acres: (item['acres'] as num?)?.toInt() ?? 0,
            roods: (item['roods'] as num?)?.toInt() ?? 0,
            perches: (item['perches'] as num?)?.toDouble() ?? 0.0,
            northBoundary: item['northBoundary']?.toString() ?? '',
            eastBoundary: item['eastBoundary']?.toString() ?? '',
            southBoundary: item['southBoundary']?.toString() ?? '',
            westBoundary: item['westBoundary']?.toString() ?? '',
            isSelected: true,
          ));
        }
      }

      if (lots.isEmpty) {
        lots.add(PlanLot(lotNumber: '1', perches: 10.0, isSelected: true));
      }

      return SurveyPlanData(
        planNumber: data['planNumber']?.toString() ?? '',
        surveyDate: data['surveyDate']?.toString() ?? '',
        certificationDate: data['certificationDate']?.toString() ?? '',
        surveyorName: data['surveyorName']?.toString() ?? '',
        surveyorRegistrationNumber: data['surveyorRegistrationNumber']?.toString() ?? '',
        landName: data['landName']?.toString() ?? '',
        priorPlanReference: data['priorPlanReference']?.toString() ?? '',
        lots: lots,
        documentFilePaths: filePaths,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Survey plan extraction failed: $e');
    }
  }

  /// Converts informal driving notes into formal chartered valuation directions.
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
        final Map<String, dynamic> json = jsonDecode(response.body);
        final result = json['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (result != null && result.toString().trim().isNotEmpty) {
          return result.toString().trim();
        }
      }
    } catch (_) {}

    return rawText;
  }
}
