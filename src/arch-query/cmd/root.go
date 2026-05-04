package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
)

var (
	baseDir    string
	versionArg string
)

var rootCmd = &cobra.Command{
	Use:   "arch-query",
	Short: "Query architecture context for RHOAI/ODH platforms",
	Long: `arch-query provides structured queries against architecture-context
markdown documentation. It replaces filesystem exploration (ls, grep, cat)
with purpose-built subcommands that return concise, structured results.`,
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
