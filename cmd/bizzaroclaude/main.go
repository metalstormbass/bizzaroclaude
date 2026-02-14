package main

import (
	"fmt"
	"os"

	"github.com/dlorenc/bizzaroclaude/internal/cli"
	"github.com/dlorenc/bizzaroclaude/internal/errors"
)

// Version is set at build time via ldflags
var Version = "dev"

func main() {
	// Set the version in the CLI package
	cli.Version = Version

	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, errors.Format(err))
		os.Exit(1)
	}
}

func run() error {
	c, err := cli.New()
	if err != nil {
		return err
	}

	return c.Execute(os.Args[1:])
}
