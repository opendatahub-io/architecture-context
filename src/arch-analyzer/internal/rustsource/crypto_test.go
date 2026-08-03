package rustsource

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

func TestExtractCryptoSecurityFactsReportsProviderAndUnknownFIPSPosture(t *testing.T) {
	root := t.TempDir()
	write := func(name, content string) {
		t.Helper()
		if err := os.WriteFile(filepath.Join(root, name), []byte(content), 0o600); err != nil {
			t.Fatal(err)
		}
	}
	write("Cargo.toml", "[dependencies]\nrustls = \"0.23\"\n")
	write("Cargo.lock", "[[package]]\nname = \"ring\"\nversion = \"0.17.0\"\n")
	write("Dockerfile.konflux", "FROM ubi9\nRUN microdnf install openssl-libs\n")

	records := extractCryptoSecurityFacts(root)
	joined := ""
	for _, record := range records {
		joined += record.Kind + "|" + record.Target + "|" + record.Detail + "|" + record.Status + "|" + record.Source + "\n"
	}
	for _, expected := range []string{
		"crypto-library|rustls",
		"crypto-provider|ring|Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider",
		"crypto-build-signal|OpenSSL",
		"fips-posture|FIPS validation",
	} {
		if !strings.Contains(joined, expected) {
			t.Errorf("records = %s, want %q", joined, expected)
		}
	}
}

func TestExtractCryptoSecurityFactsDoesNotInventEvidence(t *testing.T) {
	root := t.TempDir()
	records := extractCryptoSecurityFacts(root)
	if len(records) != 1 {
		t.Fatalf("records = %#v, want an explicit unknown FIPS posture", records)
	}
	if records[0].Kind != "fips-posture" || records[0].Status != "not-extracted" {
		t.Fatalf("record = %#v, want not-extracted FIPS posture", records[0])
	}
	if !strings.Contains(records[0].Detail, "not verified") {
		t.Fatalf("record = %#v, want explicit not-verified detail", records[0])
	}
}
