package output

import (
	"fmt"
	"io"
	"strings"
	"text/tabwriter"
)

func NewTabWriter(w io.Writer) *tabwriter.Writer {
	return tabwriter.NewWriter(w, 2, 4, 2, ' ', 0)
}

func SectionHeader(w io.Writer, title string) {
	fmt.Fprintf(w, "\n## %s\n", title)
}

func KeyValue(w io.Writer, key, value string) {
	fmt.Fprintf(w, "%-16s %s\n", key+":", value)
}

func Indent(s string, prefix string) string {
	lines := strings.Split(s, "\n")
	for i, l := range lines {
		if l != "" {
			lines[i] = prefix + l
		}
	}
	return strings.Join(lines, "\n")
}
