workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs distributed training jobs and interactive notebooks"
        mlEngineer = person "ML Engineer" "Builds training pipelines and manages model deployments"

        distributedWorkloads = softwareSystem "Distributed Workloads" "GPU-accelerated training runtime container images, Ray runtime images, and E2E integration tests for RHOAI" {
            runtimeTrainingCUDA = container "Runtime Training (CUDA)" "PyTorch training images with NVIDIA CUDA 12.1-13.0" "Container Image"
            runtimeTrainingROCm = container "Runtime Training (ROCm)" "PyTorch training images with AMD ROCm 6.2-6.4" "Container Image"
            runtimeTrainingOpenMPI = container "OpenMPI Training" "Multi-node MPI training with SSH (port 2222) on AIPCC base" "Container Image"
            universalTraining = container "Universal Training (TH06)" "Dual-mode Jupyter workbench + training runtime images" "Container Image"
            rayRuntime = container "Ray Runtime" "Ray head/worker images for CPU, CUDA, ROCm" "Container Image"
            e2eTestSuite = container "E2E Test Suite" "Go integration tests for distributed workloads stack" "Go Test Harness"
        }

        trainingOperator = softwareSystem "Training Operator (KFTO v1)" "Orchestrates PyTorchJob distributed training" "Internal RHOAI"
        kubeflowTrainerV2 = softwareSystem "Kubeflow Trainer v2" "Orchestrates TrainJob and MPI training workloads" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay Operator" "Orchestrates Ray clusters and Ray jobs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing and resource quota management" "Internal RHOAI"
        notebooksController = softwareSystem "Notebooks Controller" "Deploys and manages Jupyter workbenches" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Model artifact metadata storage" "Internal RHOAI"

        aipccBaseImages = softwareSystem "AIPCC Base Images" "CUDA/ROCm runtime base images from Ecosystems" "Internal Platform"
        rhoaiWorkbenchBase = softwareSystem "RHOAI Workbench Base" "Jupyter minimal workbench base images" "Internal Platform"

        huggingFace = softwareSystem "HuggingFace Hub" "ML model and dataset repository" "External"
        s3Storage = softwareSystem "S3 Storage" "Model checkpoints and dataset storage" "External"
        mlflow = softwareSystem "MLflow" "Experiment tracking and model management" "External"
        nvidiaRepos = softwareSystem "NVIDIA CUDA Repos" "CUDA toolkit package repository" "External Build-time"
        amdRepos = softwareSystem "AMD ROCm Repos" "ROCm SDK package repository" "External Build-time"
        mellanoxRepos = softwareSystem "Mellanox OFED Repos" "InfiniBand/RDMA package repository" "External Build-time"
        rhelAIPyPI = softwareSystem "RHEL AI PyPI" "Red Hat AI Python package index" "External Build-time"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"

        # User interactions
        dataScientist -> distributedWorkloads "Creates training jobs and notebooks using"
        mlEngineer -> distributedWorkloads "Builds training pipelines using"

        # Operators consume images
        trainingOperator -> distributedWorkloads "References training images in PyTorchJob CRs"
        kubeflowTrainerV2 -> distributedWorkloads "References training/OpenMPI images in TrainJob CRs"
        kubeRay -> distributedWorkloads "References Ray images in RayCluster/RayJob CRs"
        notebooksController -> distributedWorkloads "References universal images in Notebook CRs"
        kueue -> trainingOperator "Manages job queuing for"
        kueue -> kubeflowTrainerV2 "Manages job queuing for"
        kueue -> kubeRay "Manages job queuing for"

        # Base image dependencies
        aipccBaseImages -> runtimeTrainingOpenMPI "Provides CUDA/ROCm runtime base"
        rhoaiWorkbenchBase -> universalTraining "Provides Jupyter workbench base"

        # Runtime egress
        distributedWorkloads -> huggingFace "Downloads models and datasets" "HTTPS/443"
        distributedWorkloads -> s3Storage "Stores/reads model checkpoints" "HTTPS/443"
        distributedWorkloads -> mlflow "Logs experiments and metrics" "HTTP(S)/5000"
        distributedWorkloads -> modelRegistry "Registers trained models" "Python SDK"

        # Build-time egress
        distributedWorkloads -> nvidiaRepos "Downloads CUDA toolkit (build-time)" "HTTPS/443"
        distributedWorkloads -> amdRepos "Downloads ROCm SDK (build-time)" "HTTPS/443"
        distributedWorkloads -> mellanoxRepos "Downloads InfiniBand packages (build-time)" "HTTPS/443"
        distributedWorkloads -> rhelAIPyPI "Downloads Python packages (build-time)" "HTTPS/443"

        # Operator → K8s API
        trainingOperator -> kubernetesAPI "Creates/manages training pods" "HTTPS/443"
        kubeflowTrainerV2 -> kubernetesAPI "Creates/manages training pods + secrets" "HTTPS/443"
        kubeRay -> kubernetesAPI "Creates/manages Ray cluster pods" "HTTPS/443"

        # E2E tests validate
        e2eTestSuite -> trainingOperator "Validates PyTorchJob workflows"
        e2eTestSuite -> kubeflowTrainerV2 "Validates TrainJob workflows"
        e2eTestSuite -> kubeRay "Validates RayCluster/RayJob workflows"
        e2eTestSuite -> kueue "Validates job queuing"
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
            element "External Build-time" {
                background #cccccc
                color #333333
                shape RoundedBox
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
