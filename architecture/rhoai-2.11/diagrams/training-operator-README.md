# Architecture Diagrams for Training Operator

Generated from: `architecture/rhoai-2.11/training-operator.md`
Date: 2026-03-15

**Note**: Diagram filenames use base component name without version (directory is already versioned).

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - Mermaid diagram showing internal components and controllers
- [Data Flows](./training-operator-dataflow.png) ([mmd](./training-operator-dataflow.mmd)) - Sequence diagram of training job submission and execution flows
- [Dependencies](./training-operator-dependencies.png) ([mmd](./training-operator-dependencies.mmd)) - Component dependency graph

### For Architects
- [C4 Context](./training-operator-c4-context.dsl) - System context in C4 format (Structurizr)
- [Component Overview](./training-operator-component.png) ([mmd](./training-operator-component.mmd)) - High-level component view

### For Security Teams
- [Security Network Diagram (PNG)](./training-operator-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./training-operator-security-network.mmd) - Visual network topology (editable)
- [Security Network Diagram (ASCII)](./training-operator-security-network.txt) - Precise text format for SAR submissions
- [RBAC Visualization](./training-operator-rbac.png) ([mmd](./training-operator-rbac.mmd)) - RBAC permissions and bindings

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
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.png -w 3000
   ```

3. **Alternative formats** (if needed):
   ```bash
   # SVG (vector, scales perfectly)
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.svg

   # PDF
   PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome mmdc -i diagram.mmd -o diagram.pdf
   ```

**Note**: If `google-chrome` is not found, try `chromium` or `which google-chrome` to locate it

### C4 Diagrams (.dsl files)
- **Structurizr Lite**: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- **CLI export**: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt files)
- View in any text editor
- Include in documentation as-is
- Perfect for security reviews (precise technical details)

## Diagram Descriptions

### training-operator-component.mmd / .png
Shows the internal structure of the Training Operator including:
- Six framework-specific controllers (PyTorch, TensorFlow, MPI, XGBoost, MXNet, Paddle)
- Metrics and health probe endpoints
- Custom Resource Definitions (CRDs) for each framework
- Training job pods and their relationships
- Optional dependencies (Volcano, Scheduler Plugins, HPA)

### training-operator-dataflow.mmd / .png
Sequence diagram showing three key flows:
1. **Training Job Submission**: User creates PyTorchJob CR → Operator watches → Creates pods/services
2. **Distributed Training Execution**: Master and worker pod communication (TCP/23456)
3. **Metrics Collection**: Prometheus scraping operator metrics

### training-operator-security-network.mmd / .png / .txt
Comprehensive network topology diagram with trust zones:
- **External**: User/SDK interactions via Kubernetes API
- **Kubernetes Control Plane**: API server with RBAC enforcement
- **Opendatahub Namespace**: Training operator deployment with metrics/health endpoints
- **User Namespaces**: Training job pods (PyTorch example with master/worker communication)
- **External Services**: Container registry, object storage
- **Optional Components**: Gang scheduling (Volcano, Scheduler Plugins)

Includes detailed security information:
- Port numbers (8080/TCP metrics, 8081/TCP health, 23456/TCP training)
- Protocols (HTTP, HTTPS, TCP)
- Encryption status (TLS 1.2+, plaintext warnings)
- Authentication mechanisms (ServiceAccount tokens, user credentials, pull secrets)
- RBAC summary and permissions
- Security considerations (unencrypted metrics, plaintext pod-to-pod communication)

### training-operator-dependencies.mmd / .png
Dependency graph showing:
- **Required external dependencies**: Kubernetes 1.25+, controller-runtime v0.14.0
- **Optional external dependencies**: Volcano, Scheduler Plugins, Prometheus, HPA
- **Internal ODH dependencies**: opendatahub-operator (deployment), Prometheus ODH (monitoring)
- **CRDs managed**: Six training job types (PyTorchJob, TFJob, MPIJob, XGBoostJob, MXJob, PaddleJob)
- **Integration points**: Kubernetes API, container registry, object storage

### training-operator-rbac.mmd / .png
Visual representation of RBAC permissions:
- **Service Account**: training-operator (opendatahub namespace)
- **ClusterRole**: training-operator with permissions for:
  - Core API resources (configmaps, events, pods, services, serviceaccounts)
  - kubeflow.org resources (all training job CRDs with full lifecycle permissions)
  - autoscaling (horizontalpodautoscalers)
  - rbac.authorization.k8s.io (roles, rolebindings)
  - Gang scheduling (PodGroups for Volcano and Scheduler Plugins)
- **User-facing roles**: training-edit (full access), training-view (read-only)

### training-operator-c4-context.dsl
C4 architecture diagram showing:
- **Actors**: Data Scientist (creates jobs), Platform Admin (monitors operator)
- **System context**: Training Operator in broader ecosystem
- **External systems**: Kubernetes API, Prometheus, container registry, object storage, gang schedulers
- **Internal ODH systems**: opendatahub-operator, Prometheus ODH
- **Interactions**: Job creation, metrics collection, pod orchestration

## Key Features Illustrated

### Multi-Framework Support
The component diagram shows six independent controllers, each managing a different ML framework:
- PyTorch (elastic training with HPA)
- TensorFlow (Parameter Server architecture)
- MPI (Launcher/Worker pattern)
- XGBoost (distributed gradient boosting)
- Apache MXNet
- PaddlePaddle

### Gang Scheduling
The dependency and security diagrams show optional integration with:
- Volcano Scheduler (scheduling.volcano.sh/v1beta1 PodGroups)
- Scheduler Plugins (scheduling.x-k8s.io/v1alpha1 PodGroups)

Used for all-or-nothing scheduling of distributed training jobs.

### Security Considerations

#### ⚠️ Plaintext Communication
- **Metrics endpoint** (8080/TCP): No TLS, no authentication (internal only)
- **Training job pods** (23456/TCP): Unencrypted TCP communication between master/workers
- **Mitigation**: Use NetworkPolicies, consider enabling Istio for sensitive workloads

#### 🔒 Encrypted Communication
- **Kubernetes API**: TLS 1.2+ with ServiceAccount token authentication
- **Container Registry**: HTTPS/443 with pull secrets
- **Object Storage**: HTTPS/443 with user-provided credentials

#### Multi-Tenancy
- Training jobs run in user namespaces (RBAC isolation)
- Operator runs in opendatahub namespace with minimal permissions
- Resource quotas recommended per namespace

## Updating Diagrams

To regenerate after architecture changes:
```bash
cd /path/to/kahowell.rhoai-architecture-diagrams
# Regenerate diagrams from updated architecture file
python scripts/generate_diagram_pngs.py architecture/rhoai-2.11/diagrams --width=3000 --force
```

## Training Job Communication Patterns

### PyTorch Jobs
- Default port: **23456/TCP**
- Communication: Master coordinates workers via torchrun
- Elastic training: Dynamic worker scaling with rendezvous
- No encryption by default (plaintext TCP)

### TensorFlow Jobs
- Ports: User-configurable per replica type
- Patterns: Parameter Server or AllReduce
- Communication: Workers ↔ Parameter Server for gradient exchange

### MPI Jobs
- Pattern: Launcher/Worker
- Communication: SSH between pods (init container sets up keys)
- Launcher executes mpirun to coordinate workers

### XGBoost Jobs
- Uses Rabit (Reliable Allreduce and Broadcast Interface)
- Configurable tracker service port

## Observability

### Metrics (Port 8080)
- Job reconciliation duration
- Job creation/deletion counts
- Job status transitions
- Controller queue depth
- API call latencies

### Events
Kubernetes events generated for:
- Job creation/deletion
- Pod creation/failure
- Status changes (Running, Succeeded, Failed)
- Validation errors

### Health Checks (Port 8081)
- `/healthz`: Liveness probe (15s initial delay, 20s period)
- `/readyz`: Readiness probe (10s initial delay, 15s period)

## Related Documentation

- Architecture file: [training-operator.md](../training-operator.md)
- Upstream documentation: https://github.com/kubeflow/training-operator
- RHOAI documentation: https://docs.redhat.com/en/documentation/red_hat_openshift_ai_self-managed/2.11
