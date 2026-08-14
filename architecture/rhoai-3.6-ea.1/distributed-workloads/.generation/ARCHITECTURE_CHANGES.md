# Architecture Changes: distributed-workloads

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Kubeflow Trainer | * | <empty> | <empty> | Training runtime images are registered as ClusterTrainingRuntime resources by the Trainer component; test utilities define default runtime mappings | go.mod:9, tests/trainer/utils/utils_runtimes.go:36-57 |
| add | internal_dependencies | Kueue | * | <empty> | <empty> | Training workloads are scheduled through Kueue LocalQueue/ClusterQueue admission; Go test suite validates Kueue integration | go.mod:27, go.mod:17 |
| add | internal_dependencies | KubeRay | * | <empty> | <empty> | Ray-based distributed workloads use RayCluster/RayJob resources for cluster management; Go dependencies include kuberay/ray-operator | go.mod:22 |
