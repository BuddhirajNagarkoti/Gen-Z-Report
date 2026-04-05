import 'dart:io';
import 'dart:convert';

void main() async {
  final textsDir = Directory('texts');
  if (!textsDir.existsSync()) {
    print('Error: texts directory not found.');
    return;
  }

  final files = textsDir.listSync().whereType<File>().toList();
  // Sort files by name (e.g., 1-4.txt, 5-16.txt, etc.)
  // We need to handle numeric sorting properly: 1-4, 5-16, 17-50...
  files.sort((a, b) {
    final aName = a.uri.pathSegments.last.split('-').first;
    final bName = b.uri.pathSegments.last.split('-').first;
    return int.parse(aName).compareTo(int.parse(bName));
  });

  List<Map<String, dynamic>> pages = [];
  int currentPageNumber = 0;
  StringBuffer currentPageContent = StringBuffer();

  const nepaliDigits = '०१२३४५६७८९';
  const arabicDigits = '0123456789';

  int nepaliToArabic(String nepali) {
    String arabic = '';
    for (var i = 0; i < nepali.length; i++) {
      int index = nepaliDigits.indexOf(nepali[i]);
      if (index != -1) {
        arabic += arabicDigits[index];
      }
    }
    return int.tryParse(arabic) ?? 0;
  }

  // Regex to find page markers: lots of space then Nepali digits
  // Example: "                                                                                                     १"
  final pageMarkerRegex = RegExp(r'^\s+([०-९]+)\s*$');

  for (var file in files) {
    print('Processing ${file.path}...');
    final lines = await file.readAsLines();
    
    for (var line in lines) {
      final match = pageMarkerRegex.firstMatch(line);
      if (match != null) {
        int pageNum = nepaliToArabic(match.group(1)!);
        
        // Finalize current page if we were tracking one
        if (currentPageNumber > 0) {
          pages.add({
            'page': currentPageNumber,
            'content': currentPageContent.toString().trim(),
          });
        }
        
        currentPageNumber = pageNum;
        currentPageContent = StringBuffer();
      } else {
        // Only skip the page marker line, everything else is content
        currentPageContent.writeln(line);
      }
    }
  }

  // Add the last captured page
  if (currentPageNumber > 0) {
    pages.add({
      'page': currentPageNumber,
      'content': currentPageContent.toString().trim(),
    });
  }

  // Deduplicate and sort pages (just in case)
  pages.sort((a, b) => (a['page'] as int).compareTo(b['page'] as int));
  
  // Remove duplicates (sometimes markers appear twice or files overlap)
  final uniquePages = <int, Map<String, dynamic>>{};
  for (var p in pages) {
    uniquePages[p['page']] = p;
  }
  final finalPages = uniquePages.values.toList();
  finalPages.sort((a, b) => (a['page'] as int).compareTo(b['page'] as int));

  final outputDir = Directory('assets/data');
  if (!outputDir.existsSync()) outputDir.createSync(recursive: true);

  final bundleFile = File('assets/data/bundle.json');
  await bundleFile.writeAsString(JsonEncoder.withIndent('  ').convert(finalPages));
  
  print('Successfully processed ${finalPages.length} pages into assets/data/bundle.json');
}
