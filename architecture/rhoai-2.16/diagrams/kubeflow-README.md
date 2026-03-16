# Architecture Diagrams for Notebook Controller (Kubeflow)

Generated from: `architecture/rhoai-2.16/kubeflow.md`
Date: 2026-03-16

**Note**: Diagram filenames use base component name `kubeflow` (from filename) without version. The directory `rhoai-2.16/` is already versioned.

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - Mermaid diagram showing internal components (NotebookReconciler, CullingReconciler, Metrics Collector)
- [Data Flows](./kubeflow-dataflow.png) ([mmd](./kubeflow-dataflow.mmd)) - Sequence diagram of notebook creation, culling, metrics scraping, and user access flows
- [Dependencies](./kubeflow-dependencies.png) ([mmd](./kubeflow-dependencies.mmd)) - Component dependency graph showing external and internal dependencies

### For Architects
- [C4 Context](./kubeflow-c4-context.dsl) - System context in C4 format (Structurizr) showing Notebook Controller in the RHOAI ecosystem
- [Component Overview](./kubeflow-component.png) ([mmd](./kubeflow-component.mmd)) - High-level component view with CRDs and generated resources

### For Security Teams
- [Security Network Diagram (PNG)](./kubeflow-security-network.png) - High-resolution network topology with trust zones
- [Security Network Diagram (Mermaid)](./kubeflow-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./kubeflow-security-network.txt) - Precise text format for SAR submissions with detailed RBAC, Service Mesh, and Secrets documentation
- [RBAC Visualization](./kubeflow-rbac.png) ([mmd](./kubeflow-rbac.mmd)) - RBAC permissions showing ClusterRoles, RoleBindings, and API resource access

## Component Overview

The **Notebook Controller** is a Kubernetes operator that manages Jupyter notebook server lifecycle as custom resources. Key features:

- **Declarative notebook management**: Users create Notebook CRs, controller provisions StatefulSets and Services
- **Idle notebook culling**: CullingReconciler monitors notebook activity and stops idle notebooks to save resources
- **Istio integration**: Optional VirtualService creation for service mesh routing (when `USE_ISTIO=true`)
- **Multi-version CRD support**: Supports v1 (storage), v1beta1 (webhook), v1alpha1 (legacy) with automatic conversion
- **Prometheus metrics**: Exposes notebook lifecycle metrics for monitoring

## Network Architecture Summary

**External Access Flow**:
1. User Browser → Istio Gateway (443/TCP HTTPS TLS1.3)
2. Gateway → VirtualService (mTLS routing)
3. VirtualService → Notebook Service (80/TCP HTTP mTLS)
4. Service → Notebook Pod (8888/TCP HTTP Jupyter)

**Controller Flow**:
1. User creates Notebook CR via kubectl
2. NotebookReconciler watches CR and creates StatefulSet, Service, VirtualService
3. CullingReconciler checks `/api/kernels` endpoint for activity
4. Idle notebooks stopped after `CULL_IDLE_TIME` (default: 1440 minutes)

## Security Highlights

**RBAC**:
- ServiceAccount: `notebook-controller-service-account`
- ClusterRole: `notebook-controller-role` (manages notebooks, statefulsets, services, virtualservices)
- User-facing roles: `kubeflow-notebooks-edit`, `kubeflow-notebooks-view`, `kubeflow-notebooks-admin`

**Service Mesh**:
- mTLS STRICT mode for all notebook services
- Istio Gateway: `kubeflow/kubeflow-gateway` (default)
- VirtualService per Notebook CR with path-based routing

**Authentication**:
- Controller to K8s API: ServiceAccount JWT token
- External access: OAuth2/OIDC (via Istio Gateway)
- Service mesh: mTLS client certificates (Istio-managed)

## Configuration

**Key Environment Variables**:
- `USE_ISTIO`: Enable Istio VirtualService creation (default: false)
- `ENABLE_CULLING`: Enable automatic notebook culling (default: false)
- `CULL_IDLE_TIME`: Idle time before culling in minutes (default: 1440 = 1 day)
- `ADD_FSGROUP`: Add fsGroup:100 to pod security context (default: true, false for OpenShift)

**Deployment Overlays**:
- **OpenShift**: `USE_ISTIO=false`, `ADD_FSGROUP=false`, resource limits configured
- **Service Mesh**: Extends OpenShift, loads Istio config from `ossm.env` ConfigMap
- **Kubeflow**: Vanilla Kubeflow deployment
- **Standalone**: Minimal standalone deployment

## How to Use

### PNG Files (.png files)
**Automatically generated** at 3000px width for high-resolution presentations and documentation.

- **Ready to use**: High-resolution images suitable for presentations, wikis, and documentation
- **Width**: 3000px (height auto-adjusts to content)
- **Use directly**: Include in PowerPoint, Google Slides, Confluence, etc.

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown with ````mermaid` code blocks - renders automatically!
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

**Manual PNG regeneration** (if you edit .mmd files):

1. **Ensure Mermaid CLI is installed**:
   ```bash
   npm install -g @mermaid-js/mermaid-cli
   ```

2. **Regenerate PNG** (3000px width):
   ```bash
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kubeflow-component.mmd -o kubeflow-component.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kubeflow-component.mmd -o kubeflow-component.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i kubeflow-component.mmd -o kubeflow-component.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace kubeflow-c4-context.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Updating Diagrams

To regenerate after architecture changes:
```bash
# Auto-generate diagrams (output to architecture/rhoai-2.16/diagrams/)
cd /path/to/repo
./generate-architecture-diagrams --architecture=architecture/rhoai-2.16/kubeflow.md
```

Or manually run the PNG generation script:
```bash
python scripts/generate_diagram_pngs.py architecture/rhoai-2.16/diagrams --width=3000
```

## Additional Resources

- **Component Architecture**: [../kubeflow.md](../kubeflow.md)
- **Developer Guide**: `components/notebook-controller/developer_guide.md`
- **Kubebuilder Docs**: https://book.kubebuilder.io/
- **Kubeflow Notebooks**: https://www.kubeflow.org/docs/components/notebooks/
- **RHOAI Documentation**: https://access.redhat.com/documentation/en-us/red_hat_openshift_ai/

---

**Generated**: 2026-03-16
**Generator**: Claude Code Architecture Analysis
**Component**: notebook-controller (RHOAI 2.16)
**Source**: architecture/rhoai-2.16/kubeflow.md
