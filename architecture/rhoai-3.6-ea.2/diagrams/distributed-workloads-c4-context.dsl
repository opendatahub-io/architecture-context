workspace {
    model {
        ciRunner = person "CI Runner" "Executes end-to-end test suites against RHOAI cluster"
        dataSci = person "Data Scientist" "Runs distributed training workloads via notebooks and SDKs"

        distributedWorkloads = softwareSystem "Distributed Workloads" "E2E test suite and container image factory for distributed training on RHOAI" {
            testSuites = container "Test Suites" "Go-based E2E tests for KFTO v1, Trainer v2, KubeRay, fms-hf-tuning" "Go / Ginkgo"
            commonSupport = container "Common Support Library" "Shared Kubernetes clients, resource helpers, assertion patterns" "Go Library"
            runtimeTrainingImages = container "Runtime Training Images" "CUDA 13.0 and ROCm 6.4 MPI-based training containers on AIPCC base" "Container Image"
            universalTrainingImages = container "Universal Training Images" "Jupyter + PyTorch + ML stack (CPU/CUDA/ROCm) on workbench base" "Container Image"
            rayImages = container "Ray Cluster Images" "Ray 2.52-2.58 across CPU, CUDA, and ROCm variants" "Container Image"
        }

        kubeflowTrainingOp = softwareSystem "Kubeflow Training Operator" "Manages PyTorchJob CRDs for distributed training" "Internal RHOAI"
        kubeflowTrainerV2 = softwareSystem "Kubeflow Trainer v2" "Manages TrainJob, ClusterTrainingRuntime, JobSet workflows" "Internal RHOAI"
        kuberay = softwareSystem "KubeRay Operator" "Manages RayCluster and RayJob CRDs" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload scheduling with ClusterQueue and ResourceFlavor" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Platform UI and notebook management" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC Base Images" "Secure accelerator base images with RHEL AI PyPI" "Internal RHOAI"
        jupyterWorkbench = softwareSystem "Jupyter Workbench" "Minimal Jupyter notebook base images" "Internal RHOAI"

        k8sApi = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        s3Storage = softwareSystem "S3 Storage" "S3-compatible object storage for training data" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Model and dataset registry" "External"
        prometheus = softwareSystem "Prometheus" "Metrics collection and querying" "External"

        # Relationships
        ciRunner -> distributedWorkloads "Executes test suites"
        dataSci -> universalTrainingImages "Runs interactive training in notebooks"

        testSuites -> commonSupport "Uses shared test infrastructure"
        testSuites -> k8sApi "Creates/watches CRDs and workloads" "HTTPS/6443"
        testSuites -> prometheus "Validates metrics" "HTTPS/9090"
        testSuites -> s3Storage "Uploads/downloads test data" "HTTPS/443"

        distributedWorkloads -> kubeflowTrainingOp "Creates PyTorchJob resources" "CRD Watch"
        distributedWorkloads -> kubeflowTrainerV2 "Creates TrainJob, ClusterTrainingRuntime" "CRD Watch"
        distributedWorkloads -> kuberay "Creates RayCluster, RayJob" "CRD Watch"
        distributedWorkloads -> kueue "Configures workload scheduling" "CRD Watch"
        distributedWorkloads -> dashboard "Tests notebook interactions" "API"

        runtimeTrainingImages -> aipcc "Extends AIPCC base images" "FROM"
        universalTrainingImages -> jupyterWorkbench "Extends Jupyter workbench bases" "FROM"

        runtimeTrainingImages -> s3Storage "Downloads training data" "HTTPS/443"
        universalTrainingImages -> huggingFace "Downloads models" "HTTPS/443"
        rayImages -> s3Storage "Reads/writes training artifacts" "HTTPS/443"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
