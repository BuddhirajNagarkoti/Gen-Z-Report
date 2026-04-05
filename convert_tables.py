import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    in_table = False
    table_lines = []
    
    # Simple table detection: lines with 3+ columns separated by 2+ spaces
    def get_columns(l):
        parts = re.split(r'\s{2,}', l.strip())
        return parts if len(parts) >= 3 else []

    for line in lines:
        cols = get_columns(line)
        if cols:
            if not in_table:
                in_table = True
                table_lines = [cols]
            else:
                table_lines.append(cols)
        else:
            if in_table:
                # Close table and process it
                if len(table_lines) >= 2:
                    # Determine max columns
                    max_cols = max(len(c) for c in table_lines)
                    # Add header separator if it looks like a table
                    header = table_lines[0]
                    # Ensure same column count for all
                    table_lines_padded = []
                    for row in table_lines:
                        row += [""] * (max_cols - len(row))
                        table_lines_padded.append("| " + " | ".join(row) + " |")
                    
                    # Add separator after first line (assumed header)
                    table_lines_padded.insert(1, "| " + " | ".join(["---"] * max_cols) + " |")
                    new_lines.extend([l + "\n" for l in table_lines_padded])
                else:
                    # Not really a table, just put original line back
                    for r in table_lines:
                        new_lines.append("  ".join(r) + "\n")
                in_table = False
                table_lines = []
            new_lines.append(line)
    
    # Handle end of file table
    if in_table:
        if len(table_lines) >= 2:
            max_cols = max(len(c) for c in table_lines)
            table_lines_padded = []
            for row in table_lines:
                row += [""] * (max_cols - len(row))
                table_lines_padded.append("| " + " | ".join(row) + " |")
            table_lines_padded.insert(1, "| " + " | ".join(["---"] * max_cols) + " |")
            new_lines.extend([l + "\n" for l in table_lines_padded])
        else:
            for r in table_lines:
                new_lines.append("  ".join(r) + "\n")

    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)

texts_dir = r'e:\Antigravity\Antigravity Projects\GEN Z REPORT LLM\texts'
for filename in os.listdir(texts_dir):
    if filename.endswith('.txt'):
        process_file(os.path.join(texts_dir, filename))
