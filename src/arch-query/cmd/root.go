package cmd

import (
	"embed"
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/spf13/cobra"
)

const (
	OutputText = "text"
	OutputJSON = "json"
	OutputRaw  = "raw"
)

var (
	baseDir      string
	versionArg   string
	outputFormat string

	archFS       fs.FS
	overlayFS    fs.FS
	archSymlinks map[string]string

	embeddedFS *embed.FS
)

func addOutputFlag(cmd *cobra.Command, formats ...string) {
	cmd.Flags().StringVarP(&outputFormat, "output", "o", OutputText,
		"Output format: "+strings.Join(formats, ", "))

	allowed := make(map[string]bool, len(formats))
	for _, f := range formats {
		allowed[f] = true
	}
	existing := cmd.PreRunE
	cmd.PreRunE = func(cmd *cobra.Command, args []string) error {
		if !allowed[outputFormat] {
			return fmt.Errorf("invalid output format %q: must be %s", outputFormat, strings.Join(formats, ", "))
		}
		if existing != nil {
			return existing(cmd, args)
		}
		return nil
	}
}

func SetEmbeddedFS(efs *embed.FS) {
	embeddedFS = efs
}

var rootCmd = &cobra.Command{
	Use:   "arch-query",
	Short: "Query architecture context for RHOAI/ODH platforms",
	Long: `arch-query provides structured queries against architecture-context
markdown documentation. It replaces filesystem exploration (ls, grep, cat)
with purpose-built subcommands that return concise, structured results.`,
	PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
		resolved, oFS, symlinks, err := resolveFS(baseDir)
		if err != nil {
			return err
		}
		archFS = resolved
		overlayFS = oFS
		archSymlinks = symlinks

		if versionArg != "" {
			if target, ok := archSymlinks[versionArg]; ok {
				versionArg = target
			}
		}
		return nil
	},
}

func resolveFS(baseDir string) (fs.FS, fs.FS, map[string]string, error) {
	if info, err := os.Stat(baseDir); err == nil && info.IsDir() {
		fsys := os.DirFS(baseDir)
		symlinks := loader.LoadSymlinksFromDisk(baseDir)

		// Overlays live as a sibling of the architecture dir (../overlays/)
		parentDir := filepath.Dir(baseDir)
		overlayDir := filepath.Join(parentDir, "overlays")
		var oFS fs.FS
		if info, err := os.Stat(overlayDir); err == nil && info.IsDir() {
			oFS = os.DirFS(overlayDir)
		}
		return fsys, oFS, symlinks, nil
	}

	if embeddedFS != nil {
		sub, err := fs.Sub(embeddedFS, "_embedded/architecture")
		if err != nil {
			return nil, nil, nil, fmt.Errorf("embedded architecture data is corrupt: %w", err)
		}
		symlinks := loader.LoadSymlinksFromFS(sub)
		// In embedded mode, overlays are staged at _embedded/architecture/overlays/
		overlaysSub, _ := fs.Sub(embeddedFS, "_embedded/architecture/overlays")
		return sub, overlaysSub, symlinks, nil
	}

	return nil, nil, nil, fmt.Errorf("no architecture data: %s not found and no embedded data available", baseDir)
}

func Execute() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().StringVar(&baseDir, "base-dir", "./architecture", "Path to architecture directory")
	rootCmd.PersistentFlags().StringVar(&versionArg, "version", "", "Version to query (default: rhoai.next)")
}
