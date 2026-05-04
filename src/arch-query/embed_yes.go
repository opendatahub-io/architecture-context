//go:build embedded

package main

import "embed"

//go:embed _embedded/architecture
var _embeddedArchitecture embed.FS

var embeddedArchitecture *embed.FS = &_embeddedArchitecture
