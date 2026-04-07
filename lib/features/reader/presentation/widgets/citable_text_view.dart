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
    final lines = content.split('\n');
    final List<Widget> children = [];
    
    int i = 0;
    while (i < lines.length) {
      String lineText = lines[i].trim();
      final currentLineNum = i + 1;
      final bool isActive = activeLine == currentLineNum;
      
      // Improved table detection: starts with | 
      if (lineText.startsWith('|')) {
        // Try to find a title immediately before the table (allowing for one empty line)
        String? tableTitle;
        if (children.isNotEmpty) {
          // Look at the last added widget if it was a line and looks like a title
          // Or check the lines list directly which is more reliable
          int titleIdx = i - 1;
          if (titleIdx >= 0 && lines[titleIdx].trim().isEmpty) titleIdx--;
          
          if (titleIdx >= 0) {
            String potentialTitle = lines[titleIdx].trim();
            // A title usually starts with a section number or "Table" / "तालिका"
            if (RegExp(r'^(\d+\.|\(|तालिका|Table)').hasMatch(potentialTitle) || (potentialTitle.length < 100 && potentialTitle.isNotEmpty && !potentialTitle.startsWith('|'))) {
              tableTitle = potentialTitle;
              // If we found a title, remove the last added widget if it corresponds to this title
              if (children.isNotEmpty && i > 0) {
                // We don't want to double-render the title
                children.removeLast();
              }
            }
          }
        }

        final List<String> tableLines = [];
        final int startLineNum = i + 1;
        
        while (i < lines.length && lines[i].trim().startsWith('|')) {
          tableLines.add(lines[i]);
          i++;
        }
        
        if (tableLines.isNotEmpty) {
          children.add(_buildTable(context, tableLines, startLineNum, title: tableTitle));
        } else {
          children.add(_buildLine(context, lineText, currentLineNum, isActive));
          i++;
        }
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: isActive 
            ? (theme.brightness == Brightness.dark 
                ? theme.colorScheme.primary.withOpacity(0.1) 
                : theme.colorScheme.primary.withOpacity(0.08))
            : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showLineNumbers)
            Container(
              width: 36,
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '$lineNum',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.2),
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          if (showLineNumbers) const SizedBox(width: 16),
          Expanded(
            child: Text(
              text.isEmpty ? ' ' : text,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontSize: fontSize,
                height: 1.7,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context, List<String> tableLines, int startLineNum, {String? title}) {
    return ScrollableDataTable(
      tableLines: tableLines,
      fontSize: fontSize,
      title: title,
    );
  }
}

class ScrollableDataTable extends StatefulWidget {
  final List<String> tableLines;
  final double fontSize;
  final String? title;

  const ScrollableDataTable({
    super.key,
    required this.tableLines,
    required this.fontSize,
    this.title,
  });

  @override
  State<ScrollableDataTable> createState() => _ScrollableDataTableState();
}

class _ScrollableDataTableState extends State<ScrollableDataTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.08);
    final headerBgColor = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);

    // Filter out separator lines (|---|---|) more robustly
    final dataLines = widget.tableLines.where((l) {
      final trimmed = l.trim();
      if (trimmed.isEmpty) return false;
      // Match markdown table separators like |---| or |:---|
      return !RegExp(r'^\|\s*[:\-|\s]*[:\-]\s*\|$').hasMatch(trimmed);
    }).toList();
    
    if (dataLines.isEmpty) return const SizedBox.shrink();

    // Parse rows and columns
    final List<List<String>> rows = dataLines.map((line) {
      final cells = line.split('|');
      List<String> cleanedCells = [];
      // Split creates empty strings at start/end if line starts/ends with |
      for (int j = 1; j < cells.length; j++) {
        // Skip trailing empty cell if line ends with |
        if (j == cells.length - 1 && cells[j].trim().isEmpty) continue;
        cleanedCells.add(cells[j].trim());
      }
      return cleanedCells;
    }).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    final int maxCols = rows.fold(0, (max, row) => row.length > max ? row.length : max);

    // Prepare cell merging logic (rowspan simulation)
    // For each column, find contiguous empty cells that should be merged with the one above
    final Map<int, List<Map<String, dynamic>>> columnGroups = {};
    for (int col = 0; col < maxCols; col++) {
      columnGroups[col] = [];
      int startRow = 1; // Skip header
      while (startRow < rows.length) {
        String baseValue = col < rows[startRow].length ? rows[startRow][col] : "";
        int endRow = startRow;
        
        // If the cell is empty, we don't merge "empty" blocks by default 
        // OR we merge them if they follow a non-empty block.
        // Actually, if a cell is empty, it usually belongs to the non-empty block above it.
        // Let's refine:
        if (baseValue.isNotEmpty) {
          while (endRow + 1 < rows.length) {
            String nextValue = col < rows[endRow + 1].length ? rows[endRow + 1][col] : "";
            if (nextValue.isEmpty) {
              endRow++;
            } else {
              break;
            }
          }
        }
        
        columnGroups[col]!.add({
          'start': startRow,
          'end': endRow,
          'value': baseValue,
        });
        startRow = endRow + 1;
      }
    }

    // Prepare table rows
    final List<TableRow> tableRows = [];
    
    // Add Header Row
    if (rows.isNotEmpty) {
      tableRows.add(
        TableRow(
          decoration: BoxDecoration(color: headerBgColor),
          children: List.generate(maxCols, (colIndex) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Text(
                colIndex < rows[0].length ? rows[0][colIndex] : "",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: widget.fontSize * 0.7,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }),
        ),
      );
    }

    // Add Data Rows
    for (int rowIndex = 1; rowIndex < rows.length; rowIndex++) {
      final bool isEven = rowIndex % 2 == 0;
      tableRows.add(
        TableRow(
          decoration: BoxDecoration(
            color: isEven ? (isDark ? Colors.white.withOpacity(0.01) : Colors.black.withOpacity(0.01)) : Colors.transparent,
          ),
          children: List.generate(maxCols, (colIndex) {
            String value = "";
            bool isFirstInGroup = false;

            // Check merge logic
            if (colIndex < columnGroups.length && columnGroups[colIndex] != null) {
              for (var group in columnGroups[colIndex]!) {
                if (rowIndex >= group['start'] && rowIndex <= group['end']) {
                  if (rowIndex == group['start']) {
                    value = group['value'];
                    isFirstInGroup = true;
                  }
                  break;
                }
              }
            } else {
              value = colIndex < rows[rowIndex].length ? rows[rowIndex][colIndex] : "";
              isFirstInGroup = true;
            }

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              alignment: Alignment.center,
              child: Text(
                isFirstInGroup ? value : "", // Only show value in the first cell of a merged group
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: widget.fontSize * 0.65,
                  height: 1.4,
                  color: theme.colorScheme.onSurface.withOpacity(0.9),
                ),
                textAlign: TextAlign.center,
                softWrap: true,
              ),
            );
          }),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table Title
          if (widget.title != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: headerBgColor,
                border: Border(bottom: BorderSide(color: borderColor, width: 1.5)),
              ),
              child: Text(
                widget.title!,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
          // Helper instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.swipe_left_outlined, size: 14, color: theme.colorScheme.primary.withOpacity(0.5)),
                const SizedBox(width: 6),
                Text(
                  'दायाँ-बायाँ सार्नुहोस्',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable Area
          Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Container(
                constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 64),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  columnWidths: {
                    for (int i = 0; i < maxCols; i++) i: const MaxColumnWidth(FixedColumnWidth(100), IntrinsicColumnWidth())
                  },
                  border: TableBorder.all(color: borderColor, width: 1),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: tableRows,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
