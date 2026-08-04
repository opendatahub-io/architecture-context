# Analyzer Synthesis Context: distributed-workloads

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (observed)**: 3 services facts extracted [source: examples/hpo-raytune/resources/setup-minio.yaml:108, examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:96, workshops/kueue/nfs/nfs_deployment.yaml:96]
- **ingress (observed)**: 4 ingress facts extracted [source: examples/hpo-raytune/resources/setup-minio.yaml:131, examples/hpo-raytune/resources/setup-minio.yaml:147, examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:118, examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:138]
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authorization

- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `examples/stable-diffusion-dreambooth/yaml/distributed/rolebinding.yaml`:1 (edit)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload identity receives this role and where is it used?
  **Expected signal:** service account or subject-to-workload binding
  **Candidate:** `workshops/kueue/nfs/nfs_deployment.yaml`:20 (nfs-server-sa-anyuid, system:openshift:scc:anyuid)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/runtime/examples/ray-data-docling/Dockerfile`:13 (images/runtime/examples/ray-data-docling/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/runtime/examples/ray-data-rag/Dockerfile`:27 (images/runtime/examples/ray-data-rag/Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/runtime/training/py312-cuda130-torch210-openmpi41/Dockerfile`:202 (images/runtime/training/py312-cuda130-torch210-openmpi41/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/runtime/training/py312-cuda130-torch210-openmpi41/Dockerfile.konflux`:88 (images/runtime/training/py312-cuda130-torch210-openmpi41/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/runtime/training/py312-rocm64-torch29-openmpi41/Dockerfile.konflux`:94 (images/runtime/training/py312-rocm64-torch29-openmpi41/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/tests/Dockerfile`:32 (images/tests/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/universal/training/th-torch-cpu-py312/Dockerfile`:111 (images/universal/training/th-torch-cpu-py312/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/universal/training/th-torch-cpu-py312/Dockerfile.konflux`:114 (images/universal/training/th-torch-cpu-py312/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/universal/training/th-torch-cuda-py312/Dockerfile`:155 (images/universal/training/th-torch-cuda-py312/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/universal/training/th-torch-cuda-py312/Dockerfile.konflux`:158 (images/universal/training/th-torch-cuda-py312/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/universal/training/th-torch-rocm-py312/Dockerfile`:137 (images/universal/training/th-torch-rocm-py312/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `images/universal/training/th-torch-rocm-py312/Dockerfile.konflux`:140 (images/universal/training/th-torch-rocm-py312/Dockerfile.konflux:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** Where is this external connection made and how are TLS/authentication configured?
  **Expected signal:** request/client construction, endpoint, TLS, or credential use
  **Candidate:** `go.mod` (Kubernetes API, Kubernetes resource operations)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `examples/hpo-raytune/resources/setup-minio.yaml`:24 (minio)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `examples/hpo-raytune/resources/setup-minio.yaml`:108 (minio, minio-service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml`:12 (minio)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml`:96 (minio)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which container listener, probe, and service mapping expose this workload?
  **Expected signal:** container port, probe, service account, or lifecycle configuration
  **Candidate:** `workshops/kueue/nfs/nfs_deployment.yaml`:48 (nfs-server, nfs-server-sa)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `workshops/kueue/nfs/nfs_deployment.yaml`:96 (nfs-server)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### services

- minio port=9000 target=http protocol=TCP encryption= auth= [source: examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:96]
- minio port=9001 target=console protocol=TCP encryption= auth= [source: examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:96]
- minio-service port=9000 target=9000 protocol=TCP encryption= auth= [source: examples/hpo-raytune/resources/setup-minio.yaml:108]
- minio-service port=9090 target=9090 protocol=TCP encryption= auth= [source: examples/hpo-raytune/resources/setup-minio.yaml:108]
- nfs-server port=111 target=111 protocol=UDP encryption= auth= [source: workshops/kueue/nfs/nfs_deployment.yaml:96]
- nfs-server port=2049 target=2049 protocol=TCP encryption= auth= [source: workshops/kueue/nfs/nfs_deployment.yaml:96]
### serving_runtime_definitions

- ServingRuntime stable-diffusion formats=pytorch:1 (autoSelect) images=kserve-container=pytorch/torchserve-kfs:0.11.0-gpu builtInAdapter= [source: examples/stable-diffusion-dreambooth/yaml/distributed/serving-runtime.yaml:1]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Deployment workload minio uses service account  and 1 container(s) [source: examples/hpo-raytune/resources/setup-minio.yaml:24]
- **observed**: Deployment workload nfs-server uses service account nfs-server-sa and 1 container(s) [source: workshops/kueue/nfs/nfs_deployment.yaml:48]
- **observed**: Service minio targets minio with 2 port(s) [source: examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:96]
- **observed**: Service minio-service targets minio with 2 port(s) [source: examples/hpo-raytune/resources/setup-minio.yaml:108]
- **observed**: Service nfs-server targets nfs-server with 2 port(s) [source: workshops/kueue/nfs/nfs_deployment.yaml:96]
- **observed**: StatefulSet workload minio uses service account  and 1 container(s) [source: examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:12]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **observed**: Route minio serves host  via TLS; backend=minio; transport=HTTPS [source: examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:138]
- **observed**: Route minio-api serves host  via TLS; backend=minio-service; transport=HTTPS [source: examples/hpo-raytune/resources/setup-minio.yaml:131]
- **observed**: Route minio-console serves host  via TLS; backend=minio; transport=HTTPS [source: examples/stable-diffusion-dreambooth/yaml/distributed/minio.yaml:118]
- **observed**: Route minio-ui serves host  via TLS; backend=minio-service; transport=HTTPS [source: examples/hpo-raytune/resources/setup-minio.yaml:147]
### security

- **dependency-signal**: auth-middleware targets pyjwt: JWT/OAuth authentication library dependency [source: images/universal/training/th-torch-cuda-py312/requirements.txt:817]
- **dependency-signal**: rbac-ref targets kubernetes: Kubernetes client library (RBAC capable) [source: images/runtime/training/py312-rocm64-torch29-openmpi41/requirements.txt:255]
- **dependency-signal**: tls-config targets cryptography: TLS/cryptography library dependency [source: images/runtime/training/py312-cuda130-torch210-openmpi41/requirements.txt:86]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
