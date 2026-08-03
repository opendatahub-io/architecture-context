package cmd

import (
	"fmt"
	"os"
	"sort"

	"github.com/jctanner/arch-query/internal/index"
	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var indexCmd = &cobra.Command{
	Use:   "index",
	Short: "Generate a deterministic context index for a version",
	Long: `Generate a deterministic index mapping components to their available
architecture sections. The index lists each component with its available
fact categories, counts, source artifact paths, and category-to-section
mappings for common question types.

The "purpose" category maps to an empty section list because it is
answered by the purpose field on each component entry, not by a section.

Examples:
  arch-query index
  arch-query index --version rhoai-3.5 --output json

JSON output (format_version "2"):
  {
    "format_version": "2",
    "version": "rhoai-3.5",
    "category_mappings": {
      "api-surface": ["crds", "endpoints", "grpc_services"],
      "dependencies": ["external_deps", "internal_deps"],
      "deployment-model": ["architecture_components", "dockerfiles", "services"],
      "purpose": [],
      "security": ["egresses", "ingresses", "network_policies", "rbac_roles"]
    },
    "components": [
      {
        "name": "kserve",
        "source_path": "rhoai-3.5/kserve.md",
        "purpose": "Model serving infrastructure",
        "deploy_type": "operator",
        "repository": "https://github.com/opendatahub-io/kserve",
        "sections": {
          "crds": 5,
          "endpoints": 3,
          "external_deps": 2,
          "services": 4
        },
        "metadata": {
          "commit_sha": "abc123",
          "analyzer_version": "1.0"
        }
      }
    ]
  }`,
	RunE: func(cmd *cobra.Command, args []string) error {
		version := versionArg
		if version == "" {
			versions, err := loader.DiscoverVersions(archFS, archSymlinks)
			if err != nil {
				return err
			}
			version = loader.DefaultVersion(versions)
		}

		data, err := loader.LoadVersion(archFS, overlayFS, version)
		if err != nil {
			return fmt.Errorf("loading version %s: %w", version, err)
		}

		idx := index.Generate(version, data)

		if outputFormat == OutputJSON {
			return output.JSON(os.Stdout, idx)
		}

		fmt.Printf("Context index v%s for %s (%d components)\n\n",
			idx.FormatVersion, idx.Version, len(idx.Components))

		tw := output.NewTabWriter(os.Stdout)
		for _, entry := range idx.Components {
			sectionNames := make([]string, 0, len(entry.Sections))
			for s := range entry.Sections {
				sectionNames = append(sectionNames, s)
			}
			sort.Strings(sectionNames)

			var sectionSummary string
			for i, s := range sectionNames {
				if i > 0 {
					sectionSummary += ", "
				}
				sectionSummary += fmt.Sprintf("%s(%d)", s, entry.Sections[s])
			}
			if sectionSummary == "" {
				sectionSummary = "(empty)"
			}

			fmt.Fprintf(tw, "  %s\t%s\n", entry.Name, sectionSummary)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	addOutputFlag(indexCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(indexCmd)
}
