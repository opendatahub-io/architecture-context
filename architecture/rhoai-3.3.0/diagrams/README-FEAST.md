# Architecture Diagrams for Feast Feature Store

Generated from: `architecture/rhoai-3.3.0/feast.md`  
Date: 2026-03-14  
Component: Feast (Feature Store)

## Available Diagrams

All Mermaid diagrams are available in both `.mmd` (source) and `.png` (3000px width, high-resolution) formats.

### For Developers
- [Component Structure](./feast-component.png) ([mmd](./feast-component.mmd)) - Internal architecture with operator, servers, and storage
- [Data Flows](./feast-dataflow.png) ([mmd](./feast-dataflow.mmd)) - Sequence diagrams for feature retrieval, materialization, and registry management
- [Dependencies](./feast-dependencies.png) ([mmd](./feast-dependencies.mmd)) - External and internal RHOAI dependencies

### For Architects
- [C4 Context](./feast-c4-context.dsl) - System context in Structurizr DSL format
- [Component Overview](./feast-component.png) ([mmd](./feast-component.mmd)) - High-level view of Feast platform

### For Security Teams
- [Security Network Diagram (PNG)](./feast-security-network.png) - High-resolution network topology
- [Security Network Diagram (Mermaid)](./feast-security-network.mmd) - Editable visual network diagram
- [Security Network Diagram (ASCII)](./feast-security-network.txt) - Text format for SAR documentation
- [RBAC Visualization](./feast-rbac.png) ([mmd](./feast-rbac.mmd)) - Role-based access control structure

## Architecture Overview

### What is Feast?

Feast (Feature Store) is a Kubernetes operator that manages ML feature serving infrastructure. It provides:

- **Online Feature Server**: Low-latency real-time feature retrieval (< 100ms) for inference
- **Offline Feature Server**: Historical feature access with point-in-time correctness for training
- **Registry Server**: Centralized feature metadata management (entities, views, schemas)
- **UI Server**: Web-based feature discovery and exploration
- **Automated Materialization**: CronJob-based sync from offline to online stores

### Key Components

1. **Feast Operator** (Go)
   - Manages FeatureStore CR lifecycle
   - Creates and configures deployments, services, routes
   - Integrates with Kubeflow Notebooks (config injection)
   - Namespace: `feast-operator-system`

2. **Online Feature Server** (Python FastAPI)
   - Ports: 6566 (HTTP), 6567 (HTTPS/gRPC), 8000 (metrics)
   - Storage: SQLite (default), PostgreSQL, Redis
   - Auth: Bearer tokens (OIDC), mTLS, Kubernetes RBAC

3. **Offline Feature Server** (Python FastAPI)
   - Ports: 8815 (HTTP), 8816 (HTTPS), 8000 (metrics)
   - Storage: S3/object storage for feature data lakes
   - Point-in-time correct feature retrieval

4. **Registry Server** (Python gRPC/REST)
   - gRPC: 6570 (plain), 6571 (TLS)
   - REST: 6572 (HTTP), 6573 (HTTPS)
   - Storage: SQLite, PostgreSQL, or S3

5. **UI Server** (React/TypeScript)
   - Ports: 8888 (HTTP), 8443 (HTTPS)
   - Feature catalog browsing and exploration

### Storage Backend Options

| Backend | Use Case | Persistence | Performance |
|---------|----------|-------------|-------------|
| **SQLite** | Development, single-node | File-based PVC | Moderate |
| **PostgreSQL** | Production registry & online | Multi-node RDBMS | Good |
| **Redis** | Production online store | In-memory cache | Excellent |
| **S3** | Offline features & registry | Object storage | Scalable |

### Authentication Methods

| Method | Use Case | Configuration |
|--------|----------|---------------|
| **OIDC (JWT)** | Production with SSO | Requires OIDC secret with provider URL, client ID/secret |
| **mTLS** | High-security environments | Requires TLS client/server certificates |
| **Kubernetes RBAC** | Native cluster integration | SubjectAccessReview on FeatureStore resources |
| **None** | Development only | Not recommended for production |

### Network Architecture

**Ingress Layer (DMZ)**
- OpenShift Routes with TLS edge termination (443 → 80/443)
- Routes: `{name}-online`, `{name}-offline`, `{name}-registry`, `{name}-ui`

**Internal Cluster**
- All services use ClusterIP
- Optional TLS 1.2+ for internal communication
- mTLS available for enhanced security

**Egress**
- PostgreSQL: 5432/TCP (TLS 1.2+, password auth)
- Redis: 6379/TCP (TLS 1.2+, password auth)
- S3: 443/TCP (TLS 1.2+, AWS IAM or access keys)
- OIDC Provider: 443/TCP (TLS 1.2+, token validation)

### Data Flows

1. **Real-time Inference** (Flow 1)
   ```
   ML App → Route (HTTPS) → Online Server → Registry (metadata) → Redis/PostgreSQL/SQLite → Response
   ```

2. **Training** (Flow 2)
   ```
   Training Job → Route (HTTPS) → Offline Server → Registry → S3 (historical data) → Response
   ```

3. **Materialization** (Flow 3)
   ```
   CronJob → Online Server → Offline Server (fetch) → Online Store (write)
   ```

4. **Registry Management** (Flow 4)
   ```
   feast CLI/SDK → Registry Server (gRPC/REST) → PostgreSQL/S3 (persist metadata)
   ```

5. **Operator Reconciliation** (Flow 5)
   ```
   Operator watches FeatureStore CR → Creates deployments/services/routes → Updates CR status
   ```

### RBAC Summary

**Operator Service Account** (`controller-manager`)
- ClusterRole: `manager-role`
- Permissions:
  - FeatureStore CR: full CRUD + status/finalizers
  - Deployments, Services, ConfigMaps, PVCs, ServiceAccounts: full CRUD
  - CronJobs: full CRUD
  - OpenShift Routes: full CRUD
  - Kubeflow Notebooks: get, list, watch
  - Secrets, Pods: get, list, watch (read-only)
  - TokenReviews, SubjectAccessReviews: create

**User Roles**
- `featurestore-editor-role`: Full CRUD on FeatureStore CRs
- `featurestore-viewer-role`: Read-only access to FeatureStore CRs

### Security Features

**Encryption**
- TLS 1.2+ for all external connections
- Optional mTLS for service-to-service communication
- At-rest encryption via PVC for SQLite storage

**Secrets Management**
- `{name}-client-tls`: mTLS client certificates
- `{name}-server-tls`: Server TLS certificates
- `{name}-oidc`: OIDC provider credentials
- `{name}-db-secret`: PostgreSQL credentials
- `{name}-redis-secret`: Redis password
- `{name}-s3-secret`: S3 access keys
- `{name}-git-token`: Git repository access (for feature sync)

**Network Isolation**
- Namespace-scoped deployments
- Recommended NetworkPolicies for ingress/egress control
- Service mesh integration optional (Istio compatible)

### Dependencies

**External (Required)**
- Kubernetes 1.11.3+
- Python 3.11 (runtime)
- Go 1.22+ (build)

**External (Optional)**
- PostgreSQL 9.6+
- Redis 5.0+
- S3-compatible storage
- OpenShift 4.17+

**Internal RHOAI/ODH**
- OpenShift Routes (external access)
- Kubeflow Notebooks (config injection)
- Prometheus (metrics)
- cert-manager (TLS certificates, optional)
- OpenShift OAuth / OIDC (authentication, optional)

**Integration Points**
- RHOAI Dashboard (feature store UI integration)
- Data Science Notebooks (automatic feast client configuration)
- ML Pipelines (feature retrieval in training workflows)
- KServe/ModelMesh (online features for model serving)

### Known Limitations

1. **Single-instance online server**: Horizontal scaling requires external load balancer
2. **SQLite constraints**: Single-node only; use PostgreSQL/Redis for multi-node
3. **Materialization latency**: CronJob-based, may have delays with large datasets
4. **Manual TLS setup**: Requires cert-manager or manual certificate provisioning
5. **Namespace isolation**: Cross-namespace feature access not supported

### Resource Requirements

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit |
|-----------|-------------|-----------|----------------|--------------|
| Operator | 10m | 1000m | 64Mi | 256Mi |
| Online Server | 100m | 1000m | 128Mi | 512Mi |
| Offline Server | 100m | 1000m | 128Mi | 512Mi |
| Registry | 100m | 1000m | 128Mi | 512Mi |
| UI Server | 100m | 1000m | 128Mi | 512Mi |

**Storage**
- Registry PVC: 5Gi (SQLite)
- Online Store PVC: 5Gi (SQLite)
- Offline Store PVC: 20Gi (optional)

### Observability

**Prometheus Metrics** (Port 8000 for servers, 8443 for operator)
- `feast_server_requests_total`: Request count
- `feast_server_request_duration_seconds`: Latency histogram
- `feast_server_features_served_total`: Feature count
- `feast_server_errors_total`: Error count
- `controller_runtime_reconcile_total`: Operator reconciliations
- `controller_runtime_reconcile_errors_total`: Operator errors

**Health Probes**
- Online/Offline/UI: `/health` (HTTP)
- Registry: TCP check (gRPC), `/health` (REST)
- Operator: `/healthz` (liveness), `/readyz` (readiness)

## How to Use

### PNG Files
- **3000px width**, auto-height for high-resolution
- Ready for PowerPoint, Google Slides, Confluence, documentation
- No additional tools needed

### Mermaid Files (.mmd)
- Paste into GitHub/GitLab markdown with ` ```mermaid ` code blocks
- Edit at https://mermaid.live
- Regenerate PNG: `mmdc -i diagram.mmd -o diagram.png -w 3000`

### C4 Diagrams (.dsl)
- View with Structurizr Lite: `docker run -p 8080:8080 -v .:/usr/local/structurizr structurizr/lite`
- Export: `structurizr-cli export -workspace diagram.dsl -format png`

### ASCII Diagrams (.txt)
- View in any text editor
- Use for Security Architecture Review (SAR) submissions
- Includes RBAC summary, secrets inventory, auth matrix

## Regenerating Diagrams

After updating `architecture/rhoai-3.3.0/feast.md`:

```bash
# Regenerate PNGs from Mermaid source
python scripts/generate_diagram_pngs.py architecture/rhoai-3.3.0/diagrams --width=3000
```

## Related Documentation

- [Feast Architecture Specification](../feast.md) - Source markdown documentation
- [Feast Upstream Docs](https://docs.feast.dev/) - Official Feast documentation
- [RHOAI Documentation](https://access.redhat.com/documentation/en-us/red_hat_openshift_ai_self-managed/)

## Questions?

1. Review source: `architecture/rhoai-3.3.0/feast.md`
2. Check upstream: https://github.com/red-hat-data-services/feast (rhoai-3.3 branch)
3. Contact RHOAI architecture team
