workspace {
    model {
        ciEngineer = person "CI/CD Engineer" "Runs integration test suite to validate distributed training stack"
        dataScientist = person "Data Scientist" "Uses universal images for interactive Jupyter and batch training"

        distributedWorkloads = softwareSystem "Distributed Workloads" "Integration test suite, training runtime container images, and reference examples for distributed ML training on RHOAI" {
            testFramework = container "Integration Test Suite" "E2E tests validating distributed training across KFTO v1, Trainer v2, KubeRay, and FMS" "Go / Ginkgo"
            cudaImages = container "CUDA Training Images" "GPU-accelerated Python environments with PyTorch + CUDA 12.1–13.0" "Container Image"
            rocmImages = container "ROCm Training Images" "GPU-accelerated Python environments with PyTorch + ROCm 6.2–6.4" "Container Image"
            openMPIImages = container "OpenMPI Training Images" "MPI-enabled multi-node training runtimes (AIPCC base images)" "Container Image"
            universalImages = container "Universal Training Images" "Dual-mode images: Jupyter workbench + training runtime" "Container Image"
            testRunnerImage = container "Test Runner Image" "Go test binary with OpenShift CLI for CI/CD execution" "Container Image"
            benchmarkImages = container "OSU Benchmark Images" "MPI micro-benchmarks for network performance measurement" "Container Image"
            examples = container "Examples & Workshops" "Jupyter notebooks for LLM fine-tuning, RAG, HPO, and Kueue scheduling" "Notebooks / Manifests"
        }

        kfto = softwareSystem "Kubeflow Training Operator v1" "Manages PyTorchJob CRs for distributed training" "Internal RHOAI"
        trainerV2 = softwareSystem "Kubeflow Trainer v2" "Manages TrainJob CRs with ClusterTrainingRuntime" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Manages RayCluster and RayJob CRs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload admission and fair scheduling" "Internal RHOAI"
        kueueOperator = softwareSystem "Kueue Operator" "Manages Kueue deployment and lifecycle" "Internal RHOAI"
        jobsetController = softwareSystem "JobSet Controller" "Manages JobSet workloads for Trainer v2" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator managing DataScienceCluster lifecycle" "Internal RHOAI"
        olm = softwareSystem "OLM" "Operator Lifecycle Manager" "OpenShift"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics collection" "OpenShift"

        s3 = softwareSystem "S3 Storage" "Training data, model artifacts, checkpoints (MinIO / AWS S3)" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Pre-trained models and datasets" "External"
        nvidiaRepos = softwareSystem "NVIDIA CUDA Repos" "CUDA toolkit packages for image builds" "External"
        rocmRepos = softwareSystem "AMD ROCm Repos" "ROCm runtime packages for image builds" "External"
        mellanoxRepos = softwareSystem "Mellanox OFED Repos" "InfiniBand/RDMA driver packages" "External"

        # Relationships
        ciEngineer -> distributedWorkloads "Runs integration tests"
        dataScientist -> distributedWorkloads "Uses universal images for training"

        testFramework -> kfto "Creates/monitors PyTorchJob CRs" "HTTPS/6443"
        testFramework -> trainerV2 "Creates/monitors TrainJob CRs" "HTTPS/6443"
        testFramework -> kuberay "Creates/monitors RayCluster/RayJob CRs" "HTTPS/6443"
        testFramework -> kueue "Validates workload admission" "HTTPS/6443"
        testFramework -> kueueOperator "Verifies operator readiness" "HTTPS/6443"
        testFramework -> rhoaiOperator "Reads DSC/DSCI for platform state" "HTTPS/6443"
        testFramework -> olm "Queries operator CSV versions" "HTTPS/6443"
        testFramework -> s3 "Uploads/downloads training data" "HTTPS/443"
        testFramework -> prometheus "Queries GPU utilization" "HTTPS/9090"
        testFramework -> huggingface "Downloads models/datasets" "HTTPS/443"

        kfto -> cudaImages "Runs as training pods"
        kfto -> rocmImages "Runs as training pods"
        trainerV2 -> openMPIImages "Runs as MPI training pods"
        trainerV2 -> universalImages "Runs in training mode"

        cudaImages -> nvidiaRepos "Build: CUDA packages" "HTTPS/443"
        rocmImages -> rocmRepos "Build: ROCm packages" "HTTPS/443"
        openMPIImages -> mellanoxRepos "Build: RDMA packages" "HTTPS/443"
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
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
