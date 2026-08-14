workspace {
    model {
        user = person "Data Scientist" "Creates and deploys distributed training workloads"

        distributedWorkloads = softwareSystem "distributed-workloads" "Training runtime container images and E2E test suite for RHOAI distributed training" {
            runtimeImages = container "Runtime Training Images" "OpenMPI-based distributed training containers (CUDA, ROCm)" "Container Image"
            universalImages = container "Universal Training Hub Images" "Dual-mode images: Jupyter workbench + headless training (CUDA, ROCm, CPU)" "Container Image"
            entrypoint = container "entrypoint-universal.sh" "Dual-mode entrypoint: routes to workbench or training based on NOTEBOOK_ARGS" "Shell Script"
            testSuite = container "E2E Test Suite" "Go-based integration tests validating ClusterTrainingRuntime registration and workload execution" "Go Test"
        }

        kubeflowTrainer = softwareSystem "Kubeflow Trainer" "Registers ClusterTrainingRuntimes and manages TrainJob lifecycle" "Internal RHOAI"
        kueue = softwareSystem "Kueue" "Workload admission and quota management via LocalQueue/ClusterQueue" "Internal RHOAI"
        kubeRay = softwareSystem "KubeRay" "Ray cluster management for distributed Ray workloads" "Internal RHOAI"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster orchestration and resource management" "External"
        aipccBase = softwareSystem "AIPCC Base Images" "CUDA/ROCm accelerator base images with FIPS-friendly OpenSSL" "Internal RHOAI"
        ubi9Base = softwareSystem "UBI9 Workbench Base" "Red Hat Universal Base Image for CPU workloads" "External"
        workbenchCtrl = softwareSystem "OpenShift Workbench Controller" "Injects NOTEBOOK_ARGS for Jupyter workbench mode" "Internal RHOAI"

        user -> kubeflowTrainer "Submits TrainJob CR referencing ClusterTrainingRuntime"
        kubeflowTrainer -> distributedWorkloads "Resolves runtime to container image"
        kubeflowTrainer -> k8sAPI "Creates training pods" "HTTPS/6443"
        kueue -> kubeflowTrainer "Admits workloads via quota"
        kubeRay -> distributedWorkloads "Manages Ray clusters using runtime images"
        aipccBase -> distributedWorkloads "Provides CUDA/ROCm base layers"
        ubi9Base -> distributedWorkloads "Provides CPU base layer"
        workbenchCtrl -> distributedWorkloads "Sets NOTEBOOK_ARGS for workbench mode"
        distributedWorkloads -> k8sAPI "Training pods access cluster resources" "HTTPS/6443"
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
            element "Go Test" {
                background #e8d5f5
                color #333333
            }
            element "Shell Script" {
                background #d5e8d4
                color #333333
            }
        }
    }
}
