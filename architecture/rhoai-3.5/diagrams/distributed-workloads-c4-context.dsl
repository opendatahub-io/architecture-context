workspace {
    model {
        dataScientist = person "Data Scientist" "Submits distributed training workloads on RHOAI"
        platformEngineer = person "Platform Engineer" "Manages RHOAI cluster and GPU resources"

        distributedWorkloads = softwareSystem "Distributed Workloads" "E2E test suite and container image collection for distributed training on RHOAI" {
            testSuite = container "E2E Test Suite" "Integration tests for KFTO, Trainer v2, KubeRay, and FMS workloads" "Go Test Framework"
            supportLib = container "Test Support Library" "Shared K8s client abstractions (13 API clients), resource helpers, lifecycle management" "Go Library"
            runtimeImages = container "Runtime Training Images" "10 Konflux-built PyTorch training images (CUDA 12.1-13.0, ROCm 6.2-6.4)" "Container Images"
            universalImages = container "Universal Training Images" "3 dual-mode (Workbench + Training) images with Training Hub (CPU/CUDA/ROCm)" "Container Images"
            rayImages = container "Ray Runtime Images" "6 KubeRay-compatible images with Ray + PyTorch" "Container Images"
            benchmarks = container "Benchmark Suite" "MPI DDP SFT and OSU micro-benchmarks via Trainer v2" "Kubernetes Manifests + Python"
            notebooks = container "Example Notebooks" "Reference implementations for distributed training patterns" "Jupyter Notebooks"
            testRunnerImage = container "Test Runner Image" "Go test execution with OpenShift CLI" "Container Image"
            minioCLI = container "MinIO CLI Image" "Lightweight S3 operations utility" "Container Image"
        }

        # Internal RHOAI Platform Dependencies
        rhodsOperator = softwareSystem "rhods-operator" "Resolves training image references via RELATED_IMAGE_* env vars" "Internal RHOAI"
        kfto = softwareSystem "Kubeflow Training Operator" "Orchestrates PyTorch distributed training jobs (PyTorchJob CRD)" "Internal RHOAI"
        trainerV2 = softwareSystem "Kubeflow Trainer v2" "Modern training job orchestration with JobSet (TrainJob CRD)" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay Operator" "Manages Ray clusters for distributed training (RayJob, RayCluster CRDs)" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job scheduling, admission control, resource quotas" "Internal RHOAI"
        jobSetController = softwareSystem "JobSet Controller" "Multi-job coordination for Trainer v2" "Internal RHOAI"
        dataScienceCluster = softwareSystem "DataScienceCluster" "RHOAI platform component state management (DSC, DSCI CRDs)" "Internal RHOAI"

        # External Dependencies
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for CRD operations" "External"
        huggingFaceHub = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3Storage = softwareSystem "S3 Storage" "AWS-compatible object storage for datasets and models" "External"
        konflux = softwareSystem "Konflux" "CI/CD build system with Tekton pipelines" "External"
        openShiftPrometheus = softwareSystem "OpenShift Prometheus" "Cluster monitoring for GPU utilization metrics" "External"
        aipccInfra = softwareSystem "AIPCC Infrastructure" "AI Platform Continuous Certification base images and PyPI indexes" "External"

        # Relationships - Data Scientist perspective
        dataScientist -> runtimeImages "Uses as training container image"
        dataScientist -> universalImages "Uses as workbench or training image"
        dataScientist -> notebooks "References for training patterns"

        # Relationships - Platform Engineer perspective
        platformEngineer -> testSuite "Runs E2E validation"

        # Internal relationships
        testSuite -> supportLib "Uses for K8s operations"
        testSuite -> testRunnerImage "Packaged as"

        # Test suite validates operators
        testSuite -> kfto "Creates PyTorchJob CRDs" "Kubernetes API / HTTPS 6443"
        testSuite -> trainerV2 "Creates TrainJob CRDs" "Kubernetes API / HTTPS 6443"
        testSuite -> kubeRay "Creates RayJob CRDs" "Kubernetes API / HTTPS 6443"
        testSuite -> kueue "Creates ClusterQueue CRDs" "Kubernetes API / HTTPS 6443"
        testSuite -> dataScienceCluster "Reads DSC/DSCI state" "Kubernetes API / HTTPS 6443"

        # Operator resolves images
        rhodsOperator -> runtimeImages "Resolves via RELATED_IMAGE_*"
        rhodsOperator -> universalImages "Resolves via RELATED_IMAGE_*"

        # Training workload egress
        runtimeImages -> huggingFaceHub "Downloads models/datasets" "HTTPS/443"
        runtimeImages -> s3Storage "Uploads/downloads training data" "HTTPS/443"
        universalImages -> huggingFaceHub "Downloads models/datasets" "HTTPS/443"

        # Build system
        konflux -> runtimeImages "Builds via Tekton pipelines"
        konflux -> universalImages "Builds via Tekton pipelines"
        universalImages -> aipccInfra "Uses base images and PyPI indexes" "HTTPS/443"

        # Monitoring
        testSuite -> openShiftPrometheus "Queries GPU metrics (DCGM_FI_DEV_GPU_UTIL)" "HTTPS/9091"
    }

    views {
        systemContext distributedWorkloads "SystemContext" {
            include *
            autoLayout
        }

        container distributedWorkloads "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
