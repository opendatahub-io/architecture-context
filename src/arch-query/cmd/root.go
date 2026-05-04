package cmd

import (
	"embed"
	"fmt"
	"io/fs"
	"os"

	"github.com/jctanner/arch-query/internal/loader"
	"github.com/spf13/cobra"
)

var (
	baseDir    string
	versionArg string

	archFS       fs.FS
	archSymlinks map[string]string

	embeddedFS *embed.FS
)

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
		resolved, symlinks, err := resolveFS(baseDir)
		if err != nil {
			return err
		}
		archFS = resolved
		archSymlinks = symlinks

		if versionArg != "" {
			if target, ok := archSymlinks[versionArg]; ok {
				versionArg = target
			}
		}
		return nil
	},
}

func resolveFS(baseDir string) (fs.FS, map[string]string, error) {
	if info, err := os.Stat(baseDir); err == nil && info.IsDir() {
		fsys := os.DirFS(baseDir)
		symlinks := loader.LoadSymlinksFromDisk(baseDir)
		return fsys, symlinks, nil
	}

	if embeddedFS != nil {
		sub, err := fs.Sub(embeddedFS, "_embedded/architecture")
		if err != nil {
			return nil, nil, fmt.Errorf("embedded architecture data is corrupt: %w", err)
		}
		symlinks := loader.LoadSymlinksFromFS(sub)
		return sub, symlinks, nil
	}

	return nil, nil, fmt.Errorf("no architecture data: %s not found and no embedded data available", baseDir)
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
