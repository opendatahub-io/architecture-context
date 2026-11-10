# Architecture Diagrams for notebooks

Generated from: `architecture/rhoai-3.7-ea.1/notebooks.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned). This index is named `notebooks-README.md` so it does not overwrite the shared platform `README.md` in this directory.

**Scope**: `notebooks` is a container-image product with no operator or controller. It builds 15 RHOAI images on `rhoai-3.7-ea.1`: 10 workbenches (JupyterLab and code-server) and 5 Elyra/DSP pipeline runtimes. It also ships 24 `ImageStream` manifests that rhods-operator applies. Gateway, HTTPRoute, kube-rbac-proxy, Services and NetworkPolicy belong to the ODH notebook controller and appear as external elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./notebooks-component.mmd) - Jupyter, code-server and runtime image families, code-server in-pod process topology (nginx/code-server/httpd), ImageStream manifests, build-time components
- [Data Flows](./notebooks-dataflow.mmd) - Sequence diagram: opening a JupyterLab workbench, the code-server request and culler path, Elyra pipeline submission and execution
- [Dependencies](./notebooks-dependencies.mmd) - AIPCC bases and index, Konflux, shipped SDK stack, internal RHOAI integrations, runtime external services

### For Architects
- [C4 Context](./notebooks-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./notebooks-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./notebooks-security-network.mmd) - Trust zones: external, platform gateway, user namespace pods, cluster services, external services
- [Security Network Diagram (ASCII)](./notebooks-security-network.txt) - Precise text format for SAR submissions, with auth summary, RBAC, secrets, TLS/FIPS and risks
- [RBAC Visualization](./notebooks-rbac.mmd) - The repo defines no RBAC. Shows the runtime identities, mounted credentials and external enforcement points

## Key Security Points
- No in-pod authentication or TLS. Jupyter runs with `token=''`/`password=''` and `allow_origin="*"`, and code-server runs with `--auth none`. kube-rbac-proxy, the HTTPRoute and controller NetworkPolicy provide all protection.
- code-server binds `0.0.0.0:8787` / `[::]:8787`, so the unauthenticated backend is reachable on the pod IP and not only through nginx.
- The Elyra bootstrapper uses plaintext HTTP when the object-storage endpoint is `http://`.
- The images are explicitly outside "Designed for FIPS". `pycryptodome` and `pynacl` ship in datascience-derived images.
- Builds are hermetic (Hermeto prefetch). Hash integrity is checked at prefetch time; install runs with `--no-verify-hashes`.

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
- **CLI export**: `structurizr-cli export -workspace notebooks-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Suited to security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/notebooks.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
