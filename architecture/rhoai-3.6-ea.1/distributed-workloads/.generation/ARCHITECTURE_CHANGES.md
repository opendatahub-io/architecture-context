# Architecture Changes: distributed-workloads

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | AIPCC base images | * | <empty> | <empty> | Runtime training images are built FROM AIPCC base images providing CUDA, Python, and FIPS-compatible OpenSSL | images/runtime/training/py312-cuda130-torch210-openmpi41/Dockerfile.konflux:1 |
| add | internal_dependencies | odh-workbench-jupyter-minimal | * | <empty> | <empty> | Universal training images are built FROM ODH workbench base images for dual workbench/training mode | images/universal/training/th-torch-cpu-py312/Dockerfile.konflux:16 |
| add | internal_dependencies | Kubeflow Training Operator | * | <empty> | <empty> | Orchestrates multi-node training jobs using runtime training images via PyTorchJob CRDs; test dependency in go.mod confirms integration | go.mod:10 |
| add | internal_dependencies | Kubeflow Trainer V2 | * | <empty> | <empty> | Orchestrates TrainJob-based training workflows using distributed-workloads images; direct Go module dependency | go.mod:9 |
| add | internal_dependencies | KubeRay | * | <empty> | <empty> | Manages Ray clusters that use distributed-workloads images for Ray-based training; Go module dependency on ray-operator | go.mod:21 |
| add | internal_dependencies | Kueue | * | <empty> | <empty> | Schedules and queues distributed training workloads submitted to the platform; Go module dependency | go.mod:27 |
