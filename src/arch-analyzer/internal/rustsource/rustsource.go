package rustsource

import (
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/jctanner/arch-analyzer/internal/model"
)

type Result struct {
	Components       []model.SourceComponent
	Dependencies     []model.LanguagePackage
	Internal         []model.InternalDependency
	HTTPEndpoints    []model.HTTPEndpoint
	Services         []model.Service
	Connections      []model.ExternalConnection
	Secrets          []model.Secret
	Authentication   []model.AuthenticationFact
	SecurityEvidence []model.SecurityEvidence
	Coverage         string
}

func Extract(root string) (Result, error) {
	manifestPath := filepath.Join(root, "Cargo.toml")
	if _, err := os.Stat(manifestPath); errors.Is(err, os.ErrNotExist) {
		return Result{Coverage: "not_applicable"}, nil
	} else if err != nil {
		return Result{}, fmt.Errorf("inspect Cargo.toml: %w", err)
	}

	components, dependencies, err := extractCargoManifests(root, manifestPath)
	if err != nil {
		return Result{}, err
	}
	defaults, defaultSources, err := extractClapDefaults(root)
	if err != nil {
		return Result{}, err
	}
	endpoints, services, err := extractAxumRoutes(root, defaults, defaultSources)
	if err != nil {
		return Result{}, err
	}
	connections, internal, err := extractConfiguredConnections(root)
	if err != nil {
		return Result{}, err
	}
	secrets, authentication, err := extractSecurityFacts(root, endpoints)
	if err != nil {
		return Result{}, err
	}
	securityEvidence := extractCryptoSecurityFacts(root)

	return Result{
		Components:       components,
		Dependencies:     dependencies,
		Internal:         internal,
		HTTPEndpoints:    endpoints,
		Services:         services,
		Connections:      connections,
		Secrets:          secrets,
		Authentication:   authentication,
		SecurityEvidence: securityEvidence,
		Coverage:         "partial: literal Axum routes, direct Cargo dependencies, Clap defaults, and example runtime configuration; macros and call graphs not expanded",
	}, nil
}
