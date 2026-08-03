# Security and Build Analysis

Load for legacy runs or declared partial security/build gaps.

Check FIPS at both layers:

- Build: Konflux Dockerfiles, `CGO_ENABLED`, `strictfipsruntime`, OpenSSL,
  CSV FIPS annotations, and dynamic linking/check-payload assumptions.
- Runtime: TLS configuration, cipher suites, `InsecureSkipVerify`, and
  non-FIPS crypto libraries or providers for Go, Python, Rust, and Java.

Check hermeticity at every layer: `rpms.lock.yaml`, language lock files,
`artifacts.lock.yaml`, and Hermeto/cachi2 prefetch configuration. Record what
exists on the analyzed branch and distinguish upstream from downstream
release hardening. Never infer compliance from a missing signal; render
`unknown` or `not-extracted`.
