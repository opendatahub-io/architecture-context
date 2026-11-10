# Architecture Diagrams for llm-d-planner

Generated from: `architecture/rhoai-3.7-ea.1/llm-d-planner.md`
Date: 2026-11-10

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./llm-d-planner-component.mmd) - backend library layers, UI, Ollama, SQLite, simulator, and integrations
- [Data Flows](./llm-d-planner-dataflow.mmd) - Sequence diagram: recommendation, generate/deploy, GPU detection, quality refresh
- [Dependencies](./llm-d-planner-dependencies.mmd) - Component dependency graph

### For Architects
- [C4 Context](./llm-d-planner-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./llm-d-planner-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./llm-d-planner-security-network.mmd) - Trust zones; unauthenticated backend Route highlighted
- [Security Network Diagram (ASCII)](./llm-d-planner-security-network.txt) - Precise text format for SAR submissions (ports, TLS, auth, sensitive endpoints, secrets)
- [RBAC Visualization](./llm-d-planner-rbac.mmd) - planner-gpu-reader binding and permissions that are missing for the deploy endpoints

## Key Security Observations

- Backend API (`planner-backend` Route) has no authentication and uses CORS `*` with credentials.
- `POST /api/v1/deploy-bundle-to-cluster` applies arbitrary YAML to a namespace the caller picks. Two things limit this today, neither by design: the image has no `kubectl`, and RBAC only grants `list nodes`.
- DB admin endpoints are open when `DB_ADMIN_PASSWORD` is empty (the shipped default).
- Images use a non-AIPCC `python:3.14-slim` base, `:latest` tags, and unpinned `llm-optimizer`. The builds are not hermetic and show no FIPS signals.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ```` ```mermaid ```` code blocks. They render automatically.
- **Live editor**: https://mermaid.live (paste code, edit, export)

**Manual PNG generation** (if needed):
```bash
npm install -g @mermaid-js/mermaid-cli
PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i llm-d-planner-component.mmd -o llm-d-planner-component.png -w 3000
```

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace llm-d-planner-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Suited to security reviews because the technical details are exact

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/llm-d-planner.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
