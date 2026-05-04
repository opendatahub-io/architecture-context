package markdown

import (
	"regexp"
	"strings"
)

var metadataRe = regexp.MustCompile(`^-\s+\*\*(.+?)\*\*:\s*(.+)$`)

func ParseMetadata(lines []string) map[string]string {
	m := make(map[string]string)
	for _, line := range lines {
		line = strings.TrimSpace(line)
		matches := metadataRe.FindStringSubmatch(line)
		if matches != nil {
			m[matches[1]] = matches[2]
		}
	}
	return m
}
