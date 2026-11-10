# Architecture Diagrams for model-metadata-collection

Generated from: `architecture/rhoai-3.7-ea.1/model-metadata-collection.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

**Scope**: RHOAI ships only the static data image `quay.io/rhoai/odh-model-metadata-collection-rhel9`. It holds `data/*.yaml` at `/app/data` and runs `sleep infinity`. The Go CLIs (`model-extractor`, `serving-runtime-catalog`, `serving-runtime-validate`, `metadata-report`) run offline in CI or on a workstation and are never deployed. The model-registry consumer link is inferred from the README and overlay 0018.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./model-metadata-collection-component.mmd) - Offline CLIs and internal packages, inputs, generated catalogs, shipped data image, model-registry consumer
- [Data Flows](./model-metadata-collection-dataflow.mmd) - Sequence diagram: model/MCP/agent catalog generation, serving-runtime catalog generation, image build and consumption
- [Dependencies](./model-metadata-collection-dependencies.mmd) - Go libraries, skopeo/kustomize/cosign, external SaaS, internal RHOAI integrations

### For Architects
- [C4 Context](./model-metadata-collection-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./model-metadata-collection-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./model-metadata-collection-security-network.mmd) - Build zone, external services, supply-chain trust boundary, cluster runtime
- [Security Network Diagram (ASCII)](./model-metadata-collection-security-network.txt) - Precise text format for SAR submissions, with secrets, crypto and supply-chain controls
- [RBAC Visualization](./model-metadata-collection-rbac.mmd) - No RBAC in repo; access control delegated to the consumer; build-time credentials

## Key Security Points
- The shipped image has no listeners, no egress, no credentials and no Kubernetes API access (`io.openshift.expose-services=""`).
- All egress (443/TCP HTTPS to huggingface.co, api.github.com, raw.githubusercontent.com and registry.redhat.io) comes from offline tooling.
- The supply-chain trust boundary is git PR review of `data/*.yaml` plus the integrity of upstream inputs. The base image and all serving-runtime images are digest-pinned.
- The 3.7-ea.1 image currently carries 3.6-ea.1 serving-runtime templates.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks
- **Live editor**: https://mermaid.live

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in security documentation as-is

## Updating Diagrams

```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/model-metadata-collection.md
```
