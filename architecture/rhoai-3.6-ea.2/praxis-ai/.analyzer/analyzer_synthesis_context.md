# Analyzer Synthesis Context: ai

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

No deterministic gap candidates were extracted.

## Section Evidence


## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **dependency-signal**: crypto-build-signal targets OpenSSL: Build file references OpenSSL; presence does not establish that application TLS uses a FIPS-validated provider [source: Containerfile, Containerfile.fips, Containerfile.test]
- **dependency-signal**: crypto-library targets rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:69]
- **dependency-signal**: crypto-library targets tokio-rustls: Rust TLS dependency is present; the cryptographic provider and FIPS mode require configuration or lockfile verification [source: Cargo.toml:90]
- **dependency-signal**: crypto-provider targets aws-lc-rs: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:321]
- **dependency-signal**: crypto-provider targets openssl: Cargo.lock selects this cryptographic provider; FIPS validation depends on build and runtime configuration [source: Cargo.lock:3221]
- **dependency-signal**: crypto-provider targets ring: Cargo.lock selects ring as a cryptographic provider; ring is not a FIPS-validated provider [source: Cargo.lock:4846]
- **not-extracted**: fips-posture targets FIPS validation: FIPS validation and runtime provider selection are not fully determined by static dependency/build signals [source: Cargo.toml:69]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
