workspace {
    model {
        datascientist = person "Data Scientist" "Develops and trains ML models using distributed training"
        mlEngineer = person "ML Engineer" "Configures and manages distributed training workflows"

        distributedWorkloads = softwareSystem "distributed-workloads" "Container image factory producing runtime and universal training images for distributed ML workloads on RHOAI" {
            runtimeImages = container "Runtime Training Images" "CUDA/ROCm + OpenMPI + SSH for multi-node training via Kubeflow Training Operator" "Container Image (Python 3.12)"
            universalImages = container "Universal Training Images" "Dual-mode images: Jupyter workbench (NOTEBOOK_ARGS) or headless training (entrypoint override)" "Container Image (Python 3.12)"
            goTests = container "Go Integration Tests" "Platform-level tests exercising Kueue, KubeRay, Kubeflow Training Operator, Trainer V2" "Go 1.25 Test Suite"
            exampleManifests = container "Example Manifests" "Workshop demos: Stable Diffusion fine-tuning, HPO with Ray Tune, MinIO/NFS setup" "Kubernetes YAML"
        }

        aipccBaseImages = softwareSystem "AIPCC Base Images" "UBI9 base images with CUDA, Python, and FIPS-compatible OpenSSL" "External"
        odhWorkbenchBase = softwareSystem "ODH Workbench Base Images" "Jupyter Minimal workbench base images on UBI9" "Internal ODH"
        konflux = softwareSystem "Konflux" "Hermetic container build pipeline with hermeto/cachi2 prefetch" "External"
        containerRegistry = softwareSystem "Container Registry" "quay.io image storage and distribution" "External"

        kubeflowTrainingOp = softwareSystem "Kubeflow Training Operator" "Orchestrates multi-node training via PyTorchJob CRDs" "Internal ODH"
        kubeflowTrainerV2 = softwareSystem "Kubeflow Trainer V2" "Orchestrates TrainJob-based training workflows" "Internal ODH"
        kubeRay = softwareSystem "KubeRay" "Manages Ray clusters for distributed training" "Internal ODH"
        kueue = softwareSystem "Kueue" "Schedules and queues distributed training workloads" "Internal ODH"
        workbenchController = softwareSystem "Workbench Controller" "Manages Jupyter workbench pod lifecycle on OpenShift" "Internal ODH"

        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource operations" "External"

        # Build-time relationships
        aipccBaseImages -> runtimeImages "Provides base image (FROM)" "Container Image"
        odhWorkbenchBase -> universalImages "Provides base image (FROM)" "Container Image"
        konflux -> distributedWorkloads "Builds container images" "Hermetic Build"
        distributedWorkloads -> containerRegistry "Pushes built images" "HTTPS/TLS"

        # Runtime consumption relationships
        kubeflowTrainingOp -> runtimeImages "Launches PyTorchJob pods using" "Pod Spec"
        kubeflowTrainerV2 -> universalImages "Launches TrainJob pods using" "Pod Spec"
        kubeRay -> universalImages "Creates Ray cluster pods using" "Pod Spec"
        workbenchController -> universalImages "Creates workbench pods with NOTEBOOK_ARGS" "Pod Spec"
        kueue -> distributedWorkloads "Schedules and queues workloads" "Admission"

        # User relationships
        datascientist -> workbenchController "Opens Jupyter workbench" "Browser/HTTPS"
        mlEngineer -> kubeflowTrainingOp "Submits PyTorchJob" "kubectl/HTTPS"
        mlEngineer -> kubeflowTrainerV2 "Submits TrainJob" "kubectl/HTTPS"

        # Test relationships
        goTests -> kubernetesAPI "Exercises platform flows" "HTTPS/6443"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Person" {
                shape person
                background #4a90e2
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
        }
    }
}
