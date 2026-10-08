workspace {
    model {
        datascientist = person "Data Scientist" "Uses training images for ML model development and fine-tuning"
        mlEngineer = person "ML Engineer" "Configures distributed training jobs"
        qeEngineer = person "QE Engineer" "Runs E2E test suites to validate distributed training"

        distributedWorkloads = softwareSystem "Distributed Workloads" "Universal training container images and E2E test suite for distributed training on RHOAI" {
            cpuImage = container "th-torch-cpu-py312" "CPU universal training image — Jupyter workbench + PyTorch runtime on UBI9" "Container Image"
            cudaImage = container "th-torch-cuda-py312" "CUDA universal training image — GPU training with NCCL, Flash Attention, DeepSpeed, vLLM" "Container Image"
            rocmImage = container "th-torch-rocm-py312" "ROCm universal training image — AMD GPU training with RCCL" "Container Image"
            testSuite = container "E2E Test Suite" "Go-based integration tests for distributed training (kfto, trainer, odh, fms)" "Go"
            testSupport = container "Test Support Library" "Shared K8s client abstractions, resource helpers, test lifecycle management" "Go Library"
        }

        rhoaiWorkbench = softwareSystem "RHOAI Workbench Controller" "Manages notebook workspaces using training images" "Internal RHOAI"
        kfTrainingOp = softwareSystem "Kubeflow Training Operator" "Orchestrates PyTorchJob distributed training" "Internal RHOAI"
        kfTrainerV2 = softwareSystem "Kubeflow Trainer v2" "Orchestrates TrainJob distributed training" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Orchestrates RayCluster and RayJob distributed training" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Job queuing and resource quota management" "Internal RHOAI"
        aipccIndex = softwareSystem "AIPCC PyPI Index" "Secure Python package index for RHOAI supply chain" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Model artifact and training data storage" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and querying" "External"
        konflux = softwareSystem "Konflux" "Hermetic CI/CD build pipeline" "External"

        datascientist -> distributedWorkloads "Uses training images for interactive ML development" "JupyterLab/8888"
        mlEngineer -> distributedWorkloads "Configures distributed training with runtime images"
        qeEngineer -> distributedWorkloads "Executes E2E test suites"

        rhoaiWorkbench -> distributedWorkloads "Consumes training images for notebook workspaces" "Image Pull"
        kfTrainingOp -> distributedWorkloads "Runs training images as PyTorchJob workers"
        kfTrainerV2 -> distributedWorkloads "Runs training images as TrainJob workers"

        distributedWorkloads -> aipccIndex "Downloads Python packages during image build" "HTTPS/443"
        distributedWorkloads -> huggingface "Downloads models and datasets" "HTTPS/443"
        distributedWorkloads -> s3Storage "Reads/writes training data and model artifacts" "HTTPS/443"
        distributedWorkloads -> k8sAPI "E2E tests create and monitor distributed training resources" "HTTPS/6443"
        distributedWorkloads -> prometheus "Queries GPU utilization metrics in tests" "HTTPS/443"

        konflux -> distributedWorkloads "Builds container images with cachi2 prefetch" "Hermetic Build"

        testSuite -> testSupport "uses"
        testSuite -> k8sAPI "creates/watches CRs" "HTTPS/6443"
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
            element "Go" {
                background #f5a623
                color #ffffff
            }
            element "Go Library" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
