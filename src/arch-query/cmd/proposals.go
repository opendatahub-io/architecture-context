package cmd

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/overlay"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/jctanner/arch-query/internal/types"
	"github.com/spf13/cobra"
)

var proposalsCmd = &cobra.Command{
	Use:   "proposals",
	Short: "Generate or validate correction proposals from overlays",
}

var proposalsGenerateCmd = &cobra.Command{
	Use:   "generate",
	Short: "Generate proposal artifacts from active overlays (read-only, never modifies architecture output)",
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

		ps := overlay.GenerateProposalSet(data.Overlays, proposalsGeneratedAt)
		return output.JSON(os.Stdout, ps)
	},
}

var proposalsGeneratedAt string
var proposalsValidateFile string

var proposalsValidateCmd = &cobra.Command{
	Use:   "validate",
	Short: "Validate a proposals.json file",
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return nil
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		data, err := os.ReadFile(proposalsValidateFile)
		if err != nil {
			return fmt.Errorf("reading %s: %w", proposalsValidateFile, err)
		}

		var ps types.ProposalSet
		if err := json.Unmarshal(data, &ps); err != nil {
			return fmt.Errorf("parsing %s: %w", proposalsValidateFile, err)
		}

		errs := overlay.ValidateProposalSet(&ps)
		if len(errs) == 0 {
			fmt.Println("OK: all proposals valid")
			return nil
		}

		for _, e := range errs {
			fmt.Fprintf(os.Stderr, "ERROR: %s\n", e)
		}
		return fmt.Errorf("%d validation error(s)", len(errs))
	},
}

func init() {
	proposalsGenerateCmd.Flags().StringVar(&proposalsGeneratedAt, "generated-at", "", "RFC3339 timestamp for generated_at field (empty if omitted for deterministic output)")
	proposalsValidateCmd.Flags().StringVarP(&proposalsValidateFile, "file", "f", "proposals.json", "Path to proposals.json file")

	proposalsCmd.AddCommand(proposalsGenerateCmd)
	proposalsCmd.AddCommand(proposalsValidateCmd)
	rootCmd.AddCommand(proposalsCmd)
}
