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
var proposalsReportFile string
var proposalsReportGeneratedAt string

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

var proposalsReportCmd = &cobra.Command{
	Use:   "report",
	Short: "Generate a correction-frequency report from a validated proposals.json (read-only)",
	Long: `Generate a correction-frequency report from a validated proposals.json (read-only).

Proposal statuses:
  pending     — not yet reviewed by a human
  reviewed    — reviewed and accepted as correct
  rejected    — reviewed and determined incorrect
  superseded  — replaced by a newer proposal (excluded from active counts)

Superseded proposals are counted in input_identity.total_proposals and
superseded_count but excluded from by_component, by_category, by_status,
by_release, and summary.active_proposals.

Example JSON output (--output json):

  {
    "contract_version": "v1",
    "generated_at": "2026-07-24T00:00:00Z",
    "input_identity": {
      "proposal_contract_version": "v1",
      "proposal_generated_at": "2026-07-20T10:00:00Z",
      "total_proposals": 3
    },
    "summary": {
      "active_proposals": 2,
      "components": 2,
      "categories": 2,
      "releases": 1
    },
    "by_component": [
      {"component": "notebooks", "total": 1, "by_status": {"pending": 1}},
      {"component": "kserve", "total": 1, "by_status": {"reviewed": 1}}
    ],
    "by_category": [
      {"category": "scope-correction", "total": 1},
      {"category": "version-correction", "total": 1}
    ],
    "by_status": [
      {"status": "pending", "total": 1},
      {"status": "reviewed", "total": 1}
    ],
    "by_release": [
      {"release": "3.4", "total": 2}
    ],
    "superseded_count": 1
  }`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		return nil
	},
	RunE: func(cmd *cobra.Command, args []string) error {
		data, err := os.ReadFile(proposalsReportFile)
		if err != nil {
			return fmt.Errorf("reading %s: %w", proposalsReportFile, err)
		}

		var ps types.ProposalSet
		if err := json.Unmarshal(data, &ps); err != nil {
			return fmt.Errorf("parsing %s: %w", proposalsReportFile, err)
		}

		report, err := overlay.GenerateCorrectionFrequencyReport(&ps, proposalsReportGeneratedAt)
		if err != nil {
			return err
		}

		if outputFormat == OutputJSON {
			return output.JSON(os.Stdout, report)
		}
		overlay.FormatReportText(os.Stdout, report)
		return nil
	},
}

func init() {
	proposalsGenerateCmd.Flags().StringVar(&proposalsGeneratedAt, "generated-at", "", "RFC3339 timestamp for generated_at field (empty if omitted for deterministic output)")
	proposalsValidateCmd.Flags().StringVarP(&proposalsValidateFile, "file", "f", "proposals.json", "Path to proposals.json file")

	addOutputFlag(proposalsReportCmd, OutputText, OutputJSON)
	proposalsReportCmd.Flags().StringVarP(&proposalsReportFile, "file", "f", "proposals.json", "Path to proposals.json file")
	proposalsReportCmd.Flags().StringVar(&proposalsReportGeneratedAt, "generated-at", "", "RFC3339 timestamp for report generated_at field")

	proposalsCmd.AddCommand(proposalsGenerateCmd)
	proposalsCmd.AddCommand(proposalsValidateCmd)
	proposalsCmd.AddCommand(proposalsReportCmd)
	rootCmd.AddCommand(proposalsCmd)
}
