import 'package:google_generative_ai/google_generative_ai.dart';
import '../repositories/page_repository.dart';

class GeminiChatService {
  final PageRepository _repo;
  final List<Content> _chatHistory = [];

  static const String _apiKey = 'AIzaSyA020P5qyauN67lUrxX9TcVSSipA6OXumE';

  // ── System prompts ────────────────────────────────────────────────────────

  static const String _systemNepali = '''
तपाईं जियनजेड अनुसन्धान प्रतिवेदन २०८२ को एक विशेष र विश्वसनीय सहायक हुनुहुन्छ।

## कठोर नियमहरू (यी नियम कुनै हालतमा तोड्न मिल्दैन):

१. **केवल प्रदान गरिएको सन्दर्भ (Context) बाट मात्र उत्तर दिनुहोस्।**
   - यदि प्रश्नको जवाफ सन्दर्भमा छैन भने, यसरी भन्नुहोस्: "यो जानकारी प्रतिवेदनको उपलब्ध सन्दर्भमा फेला परेन।"
   - आफ्नै ज्ञान वा अनुमानबाट कहिल्यै उत्तर नदिनुहोस्।
   - सन्दर्भ नदिइएको उत्तर ठाडो गलत हो।

२. **पृष्ठ र पङ्क्ति नम्बर अनिवार्य:** उत्तरमा सम्बन्धित पृष्ठ र पङ्क्ति नम्बर सधैं उल्लेख गर्नुहोस्, जस्तै: "(पृष्ठ ३४५, पङ्क्ति १२)" वा "[पृष्ठ ३४५, ३४६; पङ्क्ति ८-१०]"।

३. **भाषा:** नेपालीमा मात्र उत्तर दिनुहोस्। शैली: सरल, तटस्थ, तथ्यपरक।

४. **हलुचिनेशन निषेध:** सन्दर्भमा नभएको कुनै पनि संख्या, नाम, मिति वा घटना कहिल्यै नभन्नुहोस्।

## उत्तरको ढाँचा:
- सन्दर्भमा जानकारी भेटियो भने → सीधा तथ्यपरक उत्तर + पृष्ठ नम्बर
- सन्दर्भमा जानकारी नभेटियो भने → "यो जानकारी प्रतिवेदनको उपलब्ध सन्दर्भमा फेला परेन। प्रतिवेदनको सम्बन्धित भाग सिधै हेर्नुहोस्।"
''';

// ── Public API ────────────────────────────────────────────────────────────

  GeminiChatService(this._repo);

  Future<String> sendMessage(String message, {bool isEnglish = false}) async {
    // 1. Search grounded context from the report
    final searchResults = _repo.searchPages(message, limit: 6, minScore: 1.0);

    // 2. HARD STOP — if nothing relevant found, don't call Gemini at all
    if (searchResults.isEmpty) {
      return 'यो जानकारी प्रतिवेदनको उपलब्ध सन्दर्भमा फेला परेन। '
               'कृपया आफ्नो प्रश्न अर्को तरिकाले सोध्नुहोस् वा '
               'प्रतिवेदनको सम्बन्धित भाग सिधै पाठकमा हेर्नुहोस्।';
    }

    // 3. Build the context block — include page numbers and categories prominently
    final contextLines = StringBuffer();
    final pageLabel = 'पृष्ठ';
    final lineLabel = 'प';

    for (final r in searchResults) {
      final category = r['category'] ?? '';
      contextLines.writeln('=== $pageLabel ${r['page']} [$category] ===');
      
      final lines = r['lines'] as List<String>;
      // Only include lines that actually have content to save tokens
      for (int i = 0; i < lines.length; i++) {
        final lineText = lines[i].trim();
        if (lineText.isNotEmpty) {
          contextLines.writeln('[$lineLabel${i + 1}] $lineText');
        }
      }
      contextLines.writeln();
    }

    final contextBlock = contextLines.toString();
    final questionLabel = 'प्रयोगकर्ताको प्रश्न';

    final prompt = '''
--- REPORT CONTEXT (use ONLY this) ---
$contextBlock
--- END CONTEXT ---

$questionLabel: $message

REMINDER: Answer strictly and only from the context above. Citing BOTH (Page X, Line Y) is mandatory for every factual claim.
''';

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.1, // Slight flexibility
          maxOutputTokens: 1024,
        ),
        systemInstruction: Content.system(_systemNepali),
      );

      final response = await model.generateContent([
        ..._chatHistory,
        Content.text(prompt),
      ]);

      final fallback = 'उत्तर प्राप्त गर्न सकिएन। कृपया फेरि प्रयास गर्नुहोला।';
      final textResponse = response.text ?? fallback;

      // 4. Update conversation memory (cap to 8 turns)
      if (_chatHistory.length > 8) _chatHistory.removeAt(0);
      _chatHistory.add(Content.text('Q: $message\nA: $textResponse'));

      return textResponse;
    } catch (e) {
      return 'एआई सेवामा समस्या देखियो। कृपया आफ्नो इन्टरनेट जडान जाँच्नुहोस् वा केही बेर पछि प्रयास गर्नुहोस्।';
    }
  }

  void clearHistory() => _chatHistory.clear();
}
