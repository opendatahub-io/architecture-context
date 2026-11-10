# Architecture Diagrams for workbenches

Generated from: `architecture/rhoai-3.7-ea.1/workbenches.md`
Date: 2026-11-10

**Note**: Diagram filenames use the base component name without a version, because the directory is already versioned. This index is named `workbenches-README.md` so it does not overwrite the shared platform `README.md` in this directory.

**Scope**: `workbenches` is the Kubeflow Notebooks v2 "Workspaces" controller. It reconciles `Workspace` and `WorkspaceKind` (`kubeflow.org/v1beta1`) into per-user IDE StatefulSets. In RHOAI's Gateway API mode, each workspace is exposed through an HTTPRoute on `data-science-gateway`, with a kube-rbac-proxy sidecar in front of it. Only the controller is built downstream (`quay.io/rhoai/odh-workbenches-controller-rhel9`). The backend and frontend are upstream-only and appear as dashed/grey elements.

## Available Diagrams

Mermaid diagrams are available as `.mmd` source files. Use GitHub/GitLab's built-in Mermaid rendering, or https://mermaid.live to view and edit.

### For Developers
- [Component Structure](./workbenches-component.mmd) - Manager, both reconcilers, both webhooks, TLS ProfileWatcher, activity prober, and the per-Workspace resources the controller creates
- [Data Flows](./workbenches-dataflow.mmd) - Sequence diagram: IDE access via the Gateway and kube-rbac-proxy, Workspace creation and admission, activity probe and auto-pause, metrics scrape
- [Dependencies](./workbenches-dependencies.mmd) - Go libraries, kube-rbac-proxy image, platform dependencies (workbenches-operator, data-science-gateway, Service CA, APIServer config, monitoring)

### For Architects
- [C4 Context](./workbenches-c4-context.dsl) - System context and containers in C4 format (Structurizr)
- [Component Overview](./workbenches-component.mmd) - High-level component view

### For Security Teams
- [Security Network Diagram (Mermaid)](./workbenches-security-network.mmd) - Trust zones: external, openshift-ingress, controller namespace, user namespace, control plane, monitoring
- [Security Network Diagram (ASCII)](./workbenches-security-network.txt) - Precise text format for SAR submissions, with services, RBAC, auth, secrets, TLS/FIPS and risks
- [RBAC Visualization](./workbenches-rbac.mmd) - Controller ClusterRoles and bindings, per-Workspace auth-delegator bindings, user-facing aggregated roles

## Key Security Points
- Access to a workspace is controlled by Kubernetes RBAC on the Workspace object. kube-rbac-proxy runs a SubjectAccessReview for `get workspaces.kubeflow.org/<name>`.
- The controller ServiceAccount is high-value. It has cluster-wide `pods/exec create`, ClusterRoleBinding CRUD, `bind` on `system:auth-delegator` and cluster-wide ConfigMap CRUD.
- The controller creates no NetworkPolicy for workspace pods. The IDE app port is reachable unauthenticated on the pod network.
- The controller's Jupyter activity probe uses plaintext HTTP to the pod IP and bypasses the sidecar.
- TLS follows the OpenShift APIServer profile. The kube-rbac-proxy path is FIPS-filtered; the in-process path still lists ChaCha20 suites, and the "Old" profile allows TLS 1.0.
- There is one cluster-scoped auth-delegator ClusterRoleBinding per Workspace.

## How to Use

### Mermaid Source Files (.mmd files)
- **In GitHub/GitLab**: Paste into markdown inside ```` ```mermaid ```` code blocks. They render automatically.
- **Live editor**: https://mermaid.live (paste code, edit, export)
- **Editable**: Modify and regenerate if needed

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
- Include in documentation as-is
- Suited to security reviews because it records precise technical details

## Updating Diagrams

To regenerate after architecture changes:
```bash
/generate-architecture-diagrams --architecture=architecture/rhoai-3.7-ea.1/workbenches.md --output-dir=architecture/rhoai-3.7-ea.1/diagrams
```
