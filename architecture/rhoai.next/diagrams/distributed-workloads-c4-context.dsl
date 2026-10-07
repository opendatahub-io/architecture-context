workspace {
    model {
        testEngineer = person "Test Engineer" "Runs E2E test suites to validate distributed training"
        mlEngineer = person "ML Engineer" "Uses Universal Training Images for model training"

        distributedWorkloads = softwareSystem "Distributed Workloads" "E2E test suite and Universal Training Image repository for RHOAI distributed training" {
            testSuiteKFTO = container "KFTO Test Suite" "E2E tests for PyTorchJob-based distributed training" "Go (Ginkgo)"
            testSuiteTrainer = container "Trainer Test Suite" "E2E tests for TrainJob/JobSet distributed training" "Go (Ginkgo)"
            testSuiteODH = container "KubeRay Test Suite" "E2E tests for RayCluster and RayJob" "Go (Ginkgo)"
            testSuiteFMS = container "FMS Test Suite" "E2E tests for fms-hf-tuning fine-tuning" "Go (Ginkgo)"
            commonSupport = container "Common Support Library" "Shared test infrastructure, multi-client abstractions" "Go Library"
            cpuImage = container "th-torch-cpu-py312" "CPU Universal Training Image" "Container Image (UBI9 + PyTorch)"
            cudaImage = container "th-torch-cuda-py312" "CUDA Universal Training Image" "Container Image (UBI9 + CUDA + PyTorch)"
            rocmImage = container "th-torch-rocm-py312" "ROCm Universal Training Image" "Container Image (UBI9 + ROCm + PyTorch)"
        }

        kubeflowTrainingOperator = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob CRDs for distributed training" "Internal RHOAI"
        kubeflowTrainerV2 = softwareSystem "Kubeflow Trainer v2" "Manages TrainJob and ClusterTrainingRuntime CRDs" "Internal RHOAI"
        kuberayOperator = softwareSystem "KubeRay Operator" "Manages RayCluster and RayJob CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload queue management and admission control" "Internal RHOAI"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        prometheus = softwareSystem "Prometheus" "Monitoring and metrics" "External"
        huggingfaceHub = softwareSystem "HuggingFace Hub" "Model and dataset registry" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for models and training data" "External"
        workbenchController = softwareSystem "OpenShift Workbench Controller" "Manages Jupyter workbench lifecycle" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "CI/CD pipeline for image builds" "External"
        aipccPyPI = softwareSystem "AIPCC PyPI Index" "Private Python package index" "External"

        testEngineer -> distributedWorkloads "Runs test suites"
        mlEngineer -> cpuImage "Uses for CPU training"
        mlEngineer -> cudaImage "Uses for GPU training (NVIDIA)"
        mlEngineer -> rocmImage "Uses for GPU training (AMD)"

        testSuiteKFTO -> commonSupport "Imports shared test utilities"
        testSuiteTrainer -> commonSupport "Imports shared test utilities"
        testSuiteODH -> commonSupport "Imports shared test utilities"
        testSuiteFMS -> commonSupport "Imports shared test utilities"

        commonSupport -> kubernetesAPI "Creates/watches/deletes CRs" "HTTPS/6443"
        kubernetesAPI -> kubeflowTrainingOperator "CRD watch triggers"
        kubernetesAPI -> kubeflowTrainerV2 "CRD watch triggers"
        kubernetesAPI -> kuberayOperator "CRD watch triggers"
        kubernetesAPI -> kueue "CRD watch triggers"

        kubeflowTrainingOperator -> cpuImage "Launches PyTorchJob workers"
        kubeflowTrainingOperator -> cudaImage "Launches PyTorchJob workers"
        kubeflowTrainerV2 -> cpuImage "Launches TrainJob workers"
        kubeflowTrainerV2 -> cudaImage "Launches TrainJob workers"
        kuberayOperator -> cpuImage "Launches Ray workers"

        cpuImage -> s3Storage "Downloads/uploads models" "HTTPS/443"
        cudaImage -> s3Storage "Downloads/uploads models" "HTTPS/443"
        cpuImage -> huggingfaceHub "Downloads models/datasets" "HTTPS/443"
        cudaImage -> huggingfaceHub "Downloads models/datasets" "HTTPS/443"

        workbenchController -> cpuImage "Injects NOTEBOOK_ARGS for Jupyter mode"
        workbenchController -> cudaImage "Injects NOTEBOOK_ARGS for Jupyter mode"
        workbenchController -> rocmImage "Injects NOTEBOOK_ARGS for Jupyter mode"

        commonSupport -> prometheus "Queries GPU utilization metrics" "HTTPS/443"

        konflux -> cpuImage "Builds hermetic image" "Konflux Pipeline"
        konflux -> cudaImage "Builds hermetic image" "Konflux Pipeline"
        konflux -> rocmImage "Builds hermetic image" "Konflux Pipeline"
        konflux -> aipccPyPI "Prefetches Python dependencies" "HTTPS/443"
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
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
        }
    }
}
