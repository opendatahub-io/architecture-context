# Architecture Diagrams for rhoai-additional-images

Generated from: `architecture/rhoai-3.7-ea.1/rhoai-additional-images.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: This is a configuration / release-metadata placeholder. On `rhoai-3.7-ea.1` it contains only `README.md`. It has no workloads, network surface, RBAC, secrets or build. The diagrams show that. The single data flow is inferred from the README and is not implemented. Dashed elements mark intended or absent items.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./rhoai-additional-images-component.mmd) - README.md, the intended (absent) image list, and its intended producer and consumer
- [Data Flows](./rhoai-additional-images-dataflow.mmd) - Intended release image tracking flow (git over HTTPS/443)
- [Dependencies](./rhoai-additional-images-dependencies.mmd) - Intended link to Konflux release tooling and the manifest-to-related-images gap

### For Architects
- [C4 Context](./rhoai-additional-images-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./rhoai-additional-images-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./rhoai-additional-images-security-network.mmd) - Trust zones; no runtime footprint in the cluster
- [Security Network Diagram (ASCII)](./rhoai-additional-images-security-network.txt) - SAR text format, including FIPS, hermeticity and supply-chain notes
- [RBAC Visualization](./rhoai-additional-images-rbac.mmd) - No RBAC defined

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown inside a ```` ```mermaid ```` code block and it renders automatically
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
- View in any text editor; include in SAR documentation as-is

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/rhoai-additional-images.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
