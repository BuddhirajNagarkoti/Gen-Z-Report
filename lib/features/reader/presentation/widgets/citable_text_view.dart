import 'package:flutter/material.dart';

class CitableTextView extends StatelessWidget {
  final String content;
  final double fontSize;
  final bool showLineNumbers;
  final int? activeLine;
  final Function(int, GlobalKey)? onLineRendered;

  const CitableTextView({
    super.key,
    required this.content,
    this.fontSize = 18.0,
    this.showLineNumbers = true,
    this.activeLine,
    this.onLineRendered,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = content.split('\n');
    final List<Widget> children = [];
    
    int i = 0;
    while (i < lines.length) {
      final lineText = lines[i].trim();
      final currentLineNum = i + 1;
      final bool isActive = activeLine == currentLineNum;
      
      if (lineText.startsWith('|') && lineText.endsWith('|')) {
        // Collect contiguous table lines
        final List<String> tableLines = [];
        final int startLineNum = i + 1;
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          tableLines.add(lines[i].trim());
          i++;
        }
        children.add(_buildTable(context, tableLines, startLineNum));
      } else {
        children.add(_buildLine(context, lineText, currentLineNum, isActive));
        i++;
      }
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  Widget _buildLine(BuildContext context, String text, int lineNum, bool isActive) {
    final theme = Theme.of(context);
    final GlobalKey? lineKey = isActive ? GlobalKey() : null;
    
    return Container(
      key: lineKey,
      padding: const EdgeInsets.only(bottom: 8.0),
      decoration: BoxDecoration(
        color: isActive 
            ? (theme.brightness == Brightness.dark 
                ? theme.colorScheme.primary.withOpacity(0.2) 
                : theme.colorScheme.primary.withOpacity(0.15))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        border: isActive ? Border(
          left: BorderSide(color: theme.colorScheme.primary, width: 3),
        ) : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLineNumbers)
            SizedBox(
              width: 32,
              child: Text(
                '$lineNum',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.25),
                  fontFamily: 'monospace',
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          if (showLineNumbers) const SizedBox(width: 20),
          Expanded(
            child: Text(
              text.isEmpty ? ' ' : text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: fontSize,
                height: 1.6,
                color: isActive ? theme.colorScheme.primary : null,
                fontWeight: isActive ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<String> tableLines, int startLineNum) {
    final theme = Theme.of(context);
    
    // Simple MD-style parsing (skip header separator if present)
    final allRows = tableLines
        .where((l) => !l.contains('---'))
        .map((l) => l.split('|').where((s) => s.isNotEmpty).map((s) => s.trim()).toList())
        .toList();

    if (allRows.isEmpty) return const SizedBox.shrink();

    // Find the max number of columns to prevent Assertion errors
    int maxCols = 0;
    for (final row in allRows) {
      if (row.length > maxCols) maxCols = row.length;
    }

    // Pad all rows to match maxCols
    final normalizedRows = allRows.map((row) {
      while (row.length < maxCols) {
        row.add('');
      }
      return row;
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(theme.colorScheme.primaryContainer.withOpacity(0.1)),
            dataRowMinHeight: 48,
            columns: normalizedRows[0].map((cell) => DataColumn(
              label: Text(
                cell,
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: fontSize * 0.8),
              ),
            )).toList(),
            rows: normalizedRows.skip(1).map((row) => DataRow(
              cells: row.map((cell) => DataCell(
                Text(
                  cell,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: fontSize * 0.75),
                ),
              )).toList(),
            )).toList(),
          ),
        ),
      ),
    );
  }
}
