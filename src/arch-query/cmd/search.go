package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var searchCmd = &cobra.Command{
	Use:   "search <term>",
	Short: "Search for components by name or purpose",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		term := strings.ToLower(args[0])

		version := versionArg
		if version == "" {
			versions, err := loader.DiscoverVersions(archFS, archSymlinks)
			if err != nil {
				return err
			}
			version = loader.DefaultVersion(versions)
		}

		data, err := loader.LoadVersion(archFS, version)
		if err != nil {
			return fmt.Errorf("loading version %s: %w", version, err)
		}

		type match struct {
			key     string
			purpose string
		}
		var matches []match

		for key, doc := range data.Components {
			if strings.Contains(strings.ToLower(key), term) ||
				strings.Contains(strings.ToLower(doc.Name), term) ||
				strings.Contains(strings.ToLower(doc.Purpose), term) {
				purpose := doc.Purpose
				if len(purpose) > 70 {
					purpose = purpose[:67] + "..."
				}
				matches = append(matches, match{key: key, purpose: purpose})
			}
		}

		if len(matches) == 0 {
			fmt.Fprintf(os.Stderr, "No components matching %q in %s inventory.\n", term, version)
			return nil
		}

		fmt.Printf("Found %d components matching %q:\n", len(matches), term)
		tw := output.NewTabWriter(os.Stdout)
		for _, m := range matches {
			fmt.Fprintf(tw, "  %s\t%s\n", m.key, m.purpose)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	rootCmd.AddCommand(searchCmd)
}
