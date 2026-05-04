package markdown

import "strings"

func ParseTable(lines []string) [][]string {
	var rows [][]string
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line == "" || !strings.HasPrefix(line, "|") {
			if len(rows) > 0 {
				break
			}
			continue
		}
		if isSeparatorRow(line) {
			continue
		}
		cells := splitTableRow(line)
		rows = append(rows, cells)
	}
	return rows
}

func ParseTableSkipHeader(lines []string) [][]string {
	all := ParseTable(lines)
	if len(all) <= 1 {
		return nil
	}
	return all[1:]
}

func isSeparatorRow(line string) bool {
	stripped := strings.ReplaceAll(line, "|", "")
	stripped = strings.ReplaceAll(stripped, "-", "")
	stripped = strings.ReplaceAll(stripped, ":", "")
	stripped = strings.TrimSpace(stripped)
	return stripped == ""
}

func splitTableRow(line string) []string {
	line = strings.TrimSpace(line)
	if strings.HasPrefix(line, "|") {
		line = line[1:]
	}
	if strings.HasSuffix(line, "|") {
		line = line[:len(line)-1]
	}
	parts := strings.Split(line, "|")
	cells := make([]string, len(parts))
	for i, p := range parts {
		cells[i] = strings.TrimSpace(p)
	}
	return cells
}
