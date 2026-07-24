package main

import (
	"fmt"
	"os"

	"github.com/jctanner/arch-analyzer/cmd"
)

func main() {
	if err := cmd.Execute(os.Args[1:]); err != nil {
		fmt.Fprintln(os.Stderr, "arch-analyzer:", err)
		os.Exit(1)
	}
}
