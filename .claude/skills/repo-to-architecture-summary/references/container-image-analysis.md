# Container Image Analysis

Analyze image-only repositories that package upstream projects into container images with minimal custom source code. These repos consist primarily of Dockerfiles, install scripts, and configuration — the "source code" IS the Dockerfile.

## When to use

The repository has:
- Dockerfiles/Containerfiles as the primary content
- Little or no application source code (no `go.mod`, `pyproject.toml`, `package.json` with actual source)
- The purpose is to build a container image wrapping an upstream project

Common examples: `s2i-*` notebook images, `devops-runner-images`, `intel-aikit-*`, notebook base images.

## Sub-agents

**Not needed.** These repos are small. Read all Dockerfiles and scripts directly.

## Step 1: Enumerate build files

```bash
# All Dockerfiles and Containerfiles
find . -maxdepth 3 \( -name "Dockerfile*" -o -name "Containerfile*" \) ! -name "*.md" | sort

# Install/setup scripts referenced by Dockerfiles
find . -maxdepth 3 \( -name "*.sh" -o -name "install*" -o -name "setup*" \) | sort

# Requirements files (pip packages baked into images)
find . -maxdepth 3 \( -name "requirements*.txt" -o -name "Pipfile*" \) | sort

# Any config or customization files
find . -maxdepth 3 \( -name "*.cfg" -o -name "*.ini" -o -name "*.conf" \) | sort
```

## Step 2: Read every Dockerfile

For each Dockerfile, extract:

| Field | What to look for | Architecture relevance |
|-------|-----------------|----------------------|
| **Base image** | `FROM` line | Upstream project + version, UBI variant, security posture |
| **Build stages** | Multi-stage `AS` names | Build vs. runtime separation |
| **Installed packages** | `dnf install`, `pip install`, `npm install` | Runtime dependencies, attack surface |
| **Copied files** | `COPY` directives | Custom configs, scripts, patches |
| **Exposed ports** | `EXPOSE` | Network interface |
| **Entry point** | `CMD` / `ENTRYPOINT` | How the container starts |
| **User** | `USER` | Non-root execution (security) |
| **Labels** | `LABEL` | Metadata: version, maintainer, description |
| **Environment** | `ENV` | Default configuration, feature flags |
| **Volumes** | `VOLUME` | Persistent storage requirements |
| **Health check** | `HEALTHCHECK` | Built-in health monitoring |

## Step 3: Read install scripts

Scripts referenced by `RUN` or `COPY` in Dockerfiles often contain the real logic:
- Package lists being installed
- Configuration file generation
- Upstream project patching
- Permission setup
- S2I (Source-to-Image) assemble/run scripts

## Step 4: Document findings

Map to architecture template sections:

### Architecture Components
| Component | Base Image | Upstream Project | Customizations | Purpose |
|-----------|-----------|-----------------|----------------|---------|

### Container Images
| Image | Base | Installed Packages | Size Implications | FIPS | Purpose |
|-------|------|-------------------|-------------------|------|---------|

### Network Architecture → Services
Only if the container exposes ports:
| Port | Protocol | Purpose |
|------|----------|---------|

### Security
| Aspect | Detail |
|--------|--------|
| Runtime user | UID from `USER` directive |
| Base image provenance | UBI9, Fedora, distroless, etc. |
| Package sources | Only Red Hat repos? PyPI? Third-party? |
| FIPS compliance | Build flags, crypto libraries |

### Deployment
| Aspect | Detail |
|--------|--------|
| Environment variables | From `ENV` directives |
| Volumes | From `VOLUME` directives |
| Resource requirements | GPU/accelerator needs from installed packages |

### Integration Points
| Target | How | Purpose |
|--------|-----|---------|
Document what the container connects to at runtime (if determinable from config/entrypoint).

## Key patterns to recognize

| Pattern | Example | What to document |
|---------|---------|-----------------|
| **S2I (Source-to-Image)** | s2i-minimal-notebook | Assemble script that builds user code into image at deploy time |
| **Multi-variant** | vllm-cpu, vllm-gaudi, vllm-rocm | Same project, different accelerator targets — document hardware requirements |
| **UBI-based** | Most RHOAI images | Red Hat Universal Base Image — note version and variant (ubi9, ubi9-minimal) |
| **Notebook image** | s2i-*, intel-aikit-* | JupyterLab + pre-installed ML libraries — document the library stack |
| **Wrapper image** | openvino_model_server | Thin wrapper around upstream project container |
