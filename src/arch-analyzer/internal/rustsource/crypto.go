package rustsource

import (
	"os"
	"path/filepath"
	"strconv"
	"strings"

	"github.com/jctanner/arch-analyzer/internal/model"
)

// extractCryptoSecurityFacts reports dependency and build signals without
// treating the presence of a TLS library as proof of FIPS compliance.
func extractCryptoSecurityFacts(root string) []model.SecurityEvidence {
	var result []model.SecurityEvidence
	add := func(kind, target, detail, status, source string) {
		if strings.TrimSpace(target) == "" || strings.TrimSpace(source) == "" {
			return
		}
		result = append(result, model.SecurityEvidence{
			Kind: kind, Target: target, Detail: detail, Status: status, Source: source,
		})
	}

	cargoPath := filepath.Join(root, "Cargo.toml")
	cargoContent, err := os.ReadFile(cargoPath)
	if err == nil {
		content := string(cargoContent)
		for _, dependency := range []string{"rustls", "tokio-rustls", "hyper-rustls"} {
			if strings.Contains(content, dependency+" =") || strings.Contains(content, dependency+" ") {
				add(
					"crypto-library", dependency,
					"Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification",
					"dependency-signal", "Cargo.toml:"+itoaLine(content, dependency+" ="),
				)
			}
		}
	}

	lockPath := filepath.Join(root, "Cargo.lock")
	lockContent, err := os.ReadFile(lockPath)
	if err == nil {
		content := string(lockContent)
		for _, provider := range []string{"ring", "aws-lc-rs", "openssl"} {
			needle := `name = "` + provider + `"`
			if !strings.Contains(content, needle) {
				continue
			}
			detail := "Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration"
			if provider == "ring" {
				detail = "Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider"
			}
			add("crypto-provider", provider, detail, "dependency-signal", "Cargo.lock:"+itoaLine(content, needle))
		}
	}

	for _, pattern := range []string{"Dockerfile*", "Containerfile*"} {
		matches, _ := filepath.Glob(filepath.Join(root, pattern))
		for _, path := range matches {
			content, readErr := os.ReadFile(path)
			if readErr != nil {
				continue
			}
			source := filepath.ToSlash(filepath.Base(path))
			text := strings.ToLower(string(content))
			if strings.Contains(text, "strictfipsruntime") || strings.Contains(text, "fips-mode") || strings.Contains(text, "fips mode") {
				add("fips-build-signal", "FIPS build configuration", "Build file contains an explicit FIPS-mode signal; validate the selected module and runtime configuration", "literal", source)
			}
			if strings.Contains(text, "openssl") || strings.Contains(text, "openssl-libs") {
				add("crypto-build-signal", "OpenSSL", "Build file references OpenSSL; presence does not establish that application TLS uses a FIPS-validated provider", "dependency-signal", source)
			}
		}
	}

	source := "coverage:fips_compliance"
	if len(result) > 0 {
		source = result[0].Source
	}
	if hasCryptoSignal(result) {
		result = append(result, model.SecurityEvidence{
			Kind: "fips-posture", Target: "FIPS validation", Status: "not-extracted",
			Detail: "FIPS validation and runtime provider selection are not fully determined by static dependency/build signals",
			Source: source,
		})
	} else {
		result = append(result, model.SecurityEvidence{
			Kind: "fips-posture", Target: "FIPS validation", Status: "not-extracted",
			Detail: "No deterministic crypto or FIPS build signal was extracted; FIPS validation and runtime provider selection are not verified",
			Source: source,
		})
	}
	return result
}

func hasCryptoSignal(records []model.SecurityEvidence) bool {
	return len(records) > 0
}

func itoaLine(content, needle string) string {
	index := strings.Index(content, needle)
	if index < 0 {
		return "1"
	}
	line := strings.Count(content[:index], "\n") + 1
	return strconv.Itoa(line)
}
