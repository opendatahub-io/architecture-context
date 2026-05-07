package cmd

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"os"
	"sort"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/spf13/cobra"
)

var schemaKind string

var schemasCmd = &cobra.Command{
	Use:   "schemas [component]",
	Short: "List or show CRD JSON schemas from arch-analyzer",
	Long: `Query CRD JSON schemas extracted by arch-analyzer's extract-schema
command. Schemas are stored in contracts/schemas/<component>/.

Examples:
  arch-query schemas                          # list all schemas
  arch-query schemas models-as-a-service      # list schemas for a component
  arch-query schemas --kind tenant            # show schema for a specific kind`,
	Args: cobra.MaximumNArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		version := versionArg
		if version == "" {
			versions, err := loader.DiscoverVersions(archFS, archSymlinks)
			if err != nil {
				return err
			}
			version = loader.DefaultVersion(versions)
		}

		resolved, err := loader.ResolveVersion(archFS, version)
		if err != nil {
			return fmt.Errorf("resolving version %s: %w", version, err)
		}

		schemasBase := resolved + "/contracts/schemas"

		componentFilter := ""
		if len(args) == 1 {
			componentFilter = strings.ToLower(args[0])
		}

		type schemaInfo struct {
			Component string `json:"component"`
			Kind      string `json:"kind"`
			File      string `json:"file"`
		}

		var schemas []schemaInfo

		// Walk the schemas directory
		compDirs, err := fs.ReadDir(archFS, schemasBase)
		if err != nil {
			if outputFormat == OutputJSON {
				return output.JSON(os.Stdout, []any{})
			}
			fmt.Fprintf(os.Stderr, "No CRD schemas found in %s.\n", version)
			return nil
		}

		for _, compDir := range compDirs {
			if !compDir.IsDir() {
				continue
			}
			comp := compDir.Name()
			if componentFilter != "" && !strings.EqualFold(comp, componentFilter) {
				continue
			}

			compPath := schemasBase + "/" + comp
			files, err := fs.ReadDir(archFS, compPath)
			if err != nil {
				continue
			}
			for _, f := range files {
				if f.IsDir() || !strings.HasSuffix(f.Name(), ".json") {
					continue
				}
				kind := strings.TrimSuffix(f.Name(), ".json")
				// File format: kind.version.json — extract the kind part
				parts := strings.SplitN(kind, ".", 2)
				kindName := parts[0]

				if schemaKind != "" && !strings.EqualFold(kindName, schemaKind) {
					continue
				}

				schemas = append(schemas, schemaInfo{
					Component: comp,
					Kind:      kind,
					File:      compPath + "/" + f.Name(),
				})
			}
		}

		sort.Slice(schemas, func(i, j int) bool {
			if schemas[i].Component != schemas[j].Component {
				return schemas[i].Component < schemas[j].Component
			}
			return schemas[i].Kind < schemas[j].Kind
		})

		// If --kind is set, print the actual schema content
		if schemaKind != "" && len(schemas) > 0 {
			for _, s := range schemas {
				data, err := fs.ReadFile(archFS, s.File)
				if err != nil {
					return fmt.Errorf("reading schema %s: %w", s.File, err)
				}
				if outputFormat == OutputJSON {
					// Re-emit as-is (it's already JSON)
					var raw json.RawMessage
					if err := json.Unmarshal(data, &raw); err != nil {
						return err
					}
					return output.JSON(os.Stdout, raw)
				}
				fmt.Printf("# %s/%s\n", s.Component, s.Kind)
				var pretty map[string]any
				if err := json.Unmarshal(data, &pretty); err == nil {
					enc := json.NewEncoder(os.Stdout)
					enc.SetIndent("", "  ")
					enc.Encode(pretty)
				} else {
					os.Stdout.Write(data)
				}
			}
			return nil
		}

		if len(schemas) == 0 {
			if outputFormat == OutputJSON {
				return output.JSON(os.Stdout, []any{})
			}
			fmt.Fprintf(os.Stderr, "No CRD schemas found in %s.\n", version)
			return nil
		}

		if outputFormat == OutputJSON {
			return output.JSON(os.Stdout, schemas)
		}

		fmt.Printf("%d CRD schema(s) in %s:\n", len(schemas), version)
		tw := output.NewTabWriter(os.Stdout)
		for _, s := range schemas {
			fmt.Fprintf(tw, "  %s\t%s\n", s.Component, s.Kind)
		}
		tw.Flush()
		return nil
	},
}

func init() {
	schemasCmd.Flags().StringVar(&schemaKind, "kind", "", "Show full schema for this CRD kind")
	addOutputFlag(schemasCmd, OutputText, OutputJSON)
	rootCmd.AddCommand(schemasCmd)
}
