workspace {
    model {
        dataScientist = person "Data Scientist" "Develops and submits distributed ML training jobs"
        mlEngineer = person "ML Engineer" "Manages training infrastructure and container images"
        ciPipeline = person "CI Pipeline" "Automated testing via Konflux/GitHub Actions"

        distributedWorkloads = softwareSystem "Distributed Workloads" "E2E test suite and container image collection for distributed ML training on RHOAI" {
            testFramework = container "E2E Test Framework" "Go-based test suite validating distributed training across KFTO, Trainer v2, KubeRay, and Kueue" "Go 1.25"
            runtimeCUDA = container "Runtime Training Images (CUDA)" "5 PyTorch training containers with NVIDIA CUDA 12.1-13.0 acceleration" "Python, Dockerfile"
            runtimeROCm = container "Runtime Training Images (ROCm)" "5 PyTorch training containers with AMD ROCm 6.2-6.4 acceleration" "Python, Dockerfile"
            universalImages = container "Universal Training Images" "3 dual-purpose images: JupyterLab workbench + training runtime (CPU, CUDA, ROCm)" "Python, Dockerfile"
            osuBenchmarks = container "OSU Benchmark Images" "MPI micro-benchmark runners for interconnect performance testing" "C/C++, Dockerfile"
            testRunnerImage = container "Test Runner Image" "Containerized Go test runner with oc CLI for CI pipelines" "Go, Dockerfile"
        }

        kfto = softwareSystem "Kubeflow Training Operator v1" "Manages PyTorchJob CRs for distributed training" "Internal RHOAI"
        trainerV2 = softwareSystem "Kubeflow Trainer v2" "Manages TrainJob CRs for next-gen distributed training" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Manages RayJob and RayCluster CRs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Queue-based resource management for batch workloads" "Internal RHOAI"
        jobset = softwareSystem "JobSet Controller" "Coordinates multi-job execution" "Internal RHOAI"
        rhoaiOperator = softwareSystem "RHOAI Operator" "Platform operator providing image discovery via RELATED_IMAGE env vars" "Internal RHOAI"
        notebooks = softwareSystem "Notebooks (Workbenches)" "Kubeflow Notebook CRs for interactive development" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Monitoring for GPU utilization metrics" "Internal RHOAI"

        s3 = softwareSystem "S3-compatible Storage" "Training data, models, datasets, checkpoints" "External"
        hfHub = softwareSystem "HuggingFace Hub" "Pre-trained model and dataset repository" "External"
        aipcc = softwareSystem "AIPCC Ecosystems" "Base container images and private PyPI index for hermetic builds" "Internal Red Hat"
        openshift = softwareSystem "OpenShift Platform" "Container orchestration with Routes, OAuth, Machine API" "External"
        pypi = softwareSystem "PyPI (public)" "Public Python package index" "External"
        nvidiaPypi = softwareSystem "NVIDIA PyPI" "CUDA libraries (NCCL, cuDNN)" "External"

        # Relationships - Test Framework
        ciPipeline -> distributedWorkloads "Runs E2E test suites"
        dataScientist -> universalImages "Uses for interactive development and training"
        mlEngineer -> distributedWorkloads "Manages container images and test suites"

        testFramework -> kfto "Creates/monitors PyTorchJob CRs" "HTTPS/6443"
        testFramework -> trainerV2 "Creates/monitors TrainJob CRs" "HTTPS/6443"
        testFramework -> kuberay "Creates/monitors RayJob/RayCluster CRs" "HTTPS/6443"
        testFramework -> kueue "Configures ClusterQueue/LocalQueue/ResourceFlavor" "HTTPS/6443"
        testFramework -> jobset "Validates JobSet execution" "HTTPS/6443"
        testFramework -> rhoaiOperator "Reads RELATED_IMAGE env vars for image discovery" "HTTPS/6443"
        testFramework -> notebooks "Creates Notebook CRs for SDK testing" "HTTPS/6443"
        testFramework -> prometheus "Queries GPU utilization metrics" "HTTP/9090"

        # Relationships - Runtime Images
        runtimeCUDA -> s3 "Downloads/uploads training data and models" "HTTPS/443"
        runtimeROCm -> s3 "Downloads/uploads training data and models" "HTTPS/443"
        universalImages -> s3 "Downloads/uploads training data and models" "HTTPS/443"
        universalImages -> hfHub "Downloads pre-trained models" "HTTPS/443"

        # Relationships - Build
        runtimeCUDA -> aipcc "Built from AIPCC base images (2 of 5)" "HTTPS/443"
        runtimeROCm -> aipcc "Built from AIPCC base images (2 of 5)" "HTTPS/443"
        universalImages -> aipcc "Built from AIPCC base images and PyPI index" "HTTPS/443"
        runtimeCUDA -> pypi "pip install (non-AIPCC images, build-time)" "HTTPS/443"
        runtimeCUDA -> nvidiaPypi "CUDA library wheels (build-time)" "HTTPS/443"

        # Relationships - Platform
        distributedWorkloads -> openshift "Deploys training pods, uses Routes and OAuth" "HTTPS/6443"
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
            element "Internal Red Hat" {
                background #cc0000
                color #ffffff
            }
            element "Person" {
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
                background #438dd5
                color #ffffff
            }
        }
    }
}
