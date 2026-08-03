package cmd

import (
	"fmt"
	"os"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/jctanner/arch-query/internal/output"
	"github.com/jctanner/arch-query/internal/query"
	"github.com/jctanner/arch-query/internal/types"
	"github.com/spf13/cobra"
)

var queryCmd = &cobra.Command{
	Use:   "query",
	Short: "Machine-readable one-shot queries with versioned contract",
	Long: `Query the architecture snapshot and return a versioned, machine-readable
JSON response. Every response includes contract_version, query identity,
status (ok, unknown, or not-extracted), evidence sources, and result data.

Queries that return data from the current snapshot use status "ok".
Queries for components not found use status "unknown".
Queries requiring source-level analysis not available in the snapshot
use status "not-extracted" with a reason.

Examples:
  arch-query query crds --component kserve
  arch-query query diff --component kserve --from rhoai-3.3 --to rhoai-3.4
  arch-query query dependency-status --component kserve
  arch-query query callers-of --function Reconcile --package controller
  arch-query query consumers-of --type InferenceService
  arch-query query config-sources --component kserve`,
}

// query crds

var queryCRDsComponent string

var queryCRDsCmd = &cobra.Command{
	Use:   "crds",
	Short: "CRDs, scope, versions, controllers, and watch relationships",
	RunE: func(cmd *cobra.Command, args []string) error {
		if queryCRDsComponent == "" {
			return fmt.Errorf("--component is required")
		}
		version, data, err := loadQueryVersion()
		if err != nil {
			return err
		}
		resp := query.QueryCRDs(queryCRDsComponent, version, data)
		return output.JSON(os.Stdout, resp)
	},
}

// query diff

var (
	queryDiffComponent string
	queryDiffFrom      string
	queryDiffTo        string
)

var queryDiffCmd = &cobra.Command{
	Use:   "diff",
	Short: "Added, removed, or changed facts between snapshots",
	RunE: func(cmd *cobra.Command, args []string) error {
		if queryDiffFrom == "" || queryDiffTo == "" {
			return fmt.Errorf("--from and --to are required")
		}
		from, err := loadVersionData(queryDiffFrom)
		if err != nil {
			qargs := map[string]any{
				"component": queryDiffComponent,
				"from":      queryDiffFrom,
				"to":        queryDiffTo,
			}
			resp := query.NotExtractedResponse("diff", qargs,
				queryDiffFrom+".."+queryDiffTo,
				"cannot load from-version: "+err.Error())
			return output.JSON(os.Stdout, resp)
		}
		to, err := loadVersionData(queryDiffTo)
		if err != nil {
			qargs := map[string]any{
				"component": queryDiffComponent,
				"from":      queryDiffFrom,
				"to":        queryDiffTo,
			}
			resp := query.NotExtractedResponse("diff", qargs,
				queryDiffFrom+".."+queryDiffTo,
				"cannot load to-version: "+err.Error())
			return output.JSON(os.Stdout, resp)
		}
		resp := query.QueryDiff(queryDiffComponent, queryDiffFrom, queryDiffTo, from, to)
		return output.JSON(os.Stdout, resp)
	},
}

// query dependency-status

var (
	queryDepComponent string
	queryDepRelease   string
)

var queryDepStatusCmd = &cobra.Command{
	Use:   "dependency-status",
	Short: "Dependency state, provenance, and release applicability",
	RunE: func(cmd *cobra.Command, args []string) error {
		if queryDepComponent == "" {
			return fmt.Errorf("--component is required")
		}
		version, data, err := loadQueryVersion()
		if err != nil {
			return err
		}
		resp := query.QueryDependencyStatus(queryDepComponent, queryDepRelease, version, data)
		return output.JSON(os.Stdout, resp)
	},
}

// query callers-of

var (
	queryCallersFunction string
	queryCallersPackage  string
)

var queryCallersCmd = &cobra.Command{
	Use:   "callers-of",
	Short: "Direct callers with source locations (not-extracted)",
	RunE: func(cmd *cobra.Command, args []string) error {
		if queryCallersFunction == "" || queryCallersPackage == "" {
			return fmt.Errorf("--function and --package are required")
		}
		version := resolveQueryVersionName()
		resp := query.QueryCallersOf(queryCallersFunction, queryCallersPackage, version, nil)
		return output.JSON(os.Stdout, resp)
	},
}

// query consumers-of

var queryConsumersType string

var queryConsumersCmd = &cobra.Command{
	Use:   "consumers-of",
	Short: "Files/functions that reference a type (not-extracted)",
	RunE: func(cmd *cobra.Command, args []string) error {
		if queryConsumersType == "" {
			return fmt.Errorf("--type is required")
		}
		version := resolveQueryVersionName()
		resp := query.QueryConsumersOf(queryConsumersType, version, nil)
		return output.JSON(os.Stdout, resp)
	},
}

// query config-sources

var queryConfigComponent string

var queryConfigCmd = &cobra.Command{
	Use:   "config-sources",
	Short: "Environment, ConfigMap, and CLI configuration sources",
	RunE: func(cmd *cobra.Command, args []string) error {
		if queryConfigComponent == "" {
			return fmt.Errorf("--component is required")
		}
		version, data, err := loadQueryVersion()
		if err != nil {
			return err
		}
		resp := query.QueryConfigSources(queryConfigComponent, version, data)
		return output.JSON(os.Stdout, resp)
	},
}

func loadQueryVersion() (string, *types.VersionData, error) {
	version := versionArg
	if version == "" {
		versions, err := loader.DiscoverVersions(archFS, archSymlinks)
		if err != nil {
			return "", nil, err
		}
		version = loader.DefaultVersion(versions)
	}
	data, err := loader.LoadVersion(archFS, overlayFS, version)
	if err != nil {
		return "", nil, fmt.Errorf("loading version %s: %w", version, err)
	}
	return version, data, nil
}

func loadVersionData(version string) (*types.VersionData, error) {
	if target, ok := archSymlinks[version]; ok {
		version = target
	}
	return loader.LoadVersion(archFS, overlayFS, version)
}

func resolveQueryVersionName() string {
	if versionArg != "" {
		return versionArg
	}
	versions, err := loader.DiscoverVersions(archFS, archSymlinks)
	if err != nil {
		return ""
	}
	return loader.DefaultVersion(versions)
}

func init() {
	queryCRDsCmd.Flags().StringVar(&queryCRDsComponent, "component", "", "Component name (required)")
	queryCmd.AddCommand(queryCRDsCmd)

	queryDiffCmd.Flags().StringVar(&queryDiffComponent, "component", "", "Component name (empty for platform-wide)")
	queryDiffCmd.Flags().StringVar(&queryDiffFrom, "from", "", "From version (required)")
	queryDiffCmd.Flags().StringVar(&queryDiffTo, "to", "", "To version (required)")
	queryCmd.AddCommand(queryDiffCmd)

	queryDepStatusCmd.Flags().StringVar(&queryDepComponent, "component", "", "Component name (required)")
	queryDepStatusCmd.Flags().StringVar(&queryDepRelease, "release", "", "Release version filter")
	queryCmd.AddCommand(queryDepStatusCmd)

	queryCallersCmd.Flags().StringVar(&queryCallersFunction, "function", "", "Function name (required)")
	queryCallersCmd.Flags().StringVar(&queryCallersPackage, "package", "", "Package name (required)")
	queryCmd.AddCommand(queryCallersCmd)

	queryConsumersCmd.Flags().StringVar(&queryConsumersType, "type", "", "Type name (required)")
	queryCmd.AddCommand(queryConsumersCmd)

	queryConfigCmd.Flags().StringVar(&queryConfigComponent, "component", "", "Component name (required)")
	queryCmd.AddCommand(queryConfigCmd)

	rootCmd.AddCommand(queryCmd)
}
