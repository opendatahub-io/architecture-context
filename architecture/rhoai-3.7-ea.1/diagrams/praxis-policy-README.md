# Architecture Diagrams for praxis-policy

Generated from: `architecture/rhoai-3.7-ea.1/praxis-policy.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: praxis-policy (Praxis Policy Engine, PPE) is an embeddable Rust library, not a service. It has no listener, Service, CRD, RBAC or container image. In RHOAI it runs inside the Praxis proxy, which owns inbound exposure, the outbound `HttpTransport` (pingora), and the process FIPS configuration. Ports marked "host-defined" or "configurable" come from host or policy config.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./praxis-policy-component.mmd) - Layered crates (facade, core, orchestration, APL runtime/CMF/core), feature-gated builtins, reference plugins, host integration
- [Data Flows](./praxis-policy-dataflow.mmd) - Sequence diagram: Vault secret resolution, tool call with JWT/Valkey/PDP/RFC 8693 delegation and result redaction, CIBA approval
- [Dependencies](./praxis-policy-dependencies.mmd) - Host, platform services, required crates, and optional feature-gated crates

### For Architects
- [C4 Context](./praxis-policy-c4-context.dsl) - System context and containers in C4 format (Structurizr), modeled inside the Praxis host
- [Component Overview](./praxis-policy-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./praxis-policy-security-network.mmd) - Trust zones: callers, host process, platform services, upstreams
- [Security Network Diagram (ASCII)](./praxis-policy-security-network.txt) - Precise text format for SAR submissions, with secrets, authZ, multi-tenancy, crypto/FIPS and observations
- [RBAC Visualization](./praxis-policy-rbac.mmd) - No Kubernetes RBAC in this repo; shows application-level authorization (APL, PDPs, Session Taint, delegation)

## Key Security Points
- All HTTP egress (JWKS, token exchange, CIBA, Vault, Limitador, API-key directory) goes through the host-injected transport, so the host owns TLS trust and mTLS. Valkey uses redis-rs with rustls and requires TLS except to localhost.
- Fails closed: plaintext is refused unless `insecure_http: true`, unknown plugin kinds or config keys fail loading, and Limitador `on_error` defaults to `deny`.
- The default build is not FIPS (RustCrypto). The `fips` / `jwt-openssl-fips` features use OpenSSL. OAuth/Vault delegation, Valkey, ordinary `jwt` and `http-hyper` fall outside the FIPS profile. Whether RHOAI is FIPS-safe depends on the Cargo features Praxis selects.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks. They render automatically.
- **Live editor**: https://mermaid.live (paste code, edit, export)

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor and include in SAR documentation as-is.

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/praxis-policy.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
