workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, runs experiments, and builds ML pipelines"

        notebooks = softwareSystem "Notebooks" "Container image factory producing Jupyter, Code-Server, and Elyra runtime images for RHOAI workbenches" {
            jupyterImages = container "Jupyter Images" "JupyterLab workbench images (minimal, datascience, pytorch, tensorflow, trustyai, llmcompressor)" "Container Images"
            codeserverImages = container "Code-Server Images" "VS Code in browser workbench images with idle culling support" "Container Images"
            runtimeImages = container "Runtime Images" "Elyra pipeline runtime images for executing notebook pipeline nodes" "Container Images"
            buildTools = container "Build Tools" "buildinputs (CI caching) and check-payload (FIPS validation)" "Go CLI"
            manifests = container "Deployment Manifests" "Kustomize-based ImageStream definitions with digest-pinned image refs" "Kustomize"
        }

        aipccBase = softwareSystem "AIPCC Base Images" "Pre-configured RHEL 9.8 base images with CPU/CUDA/ROCm support" "External"
        odhOperator = softwareSystem "ODH Operator" "Deploys ImageStream manifests to the cluster" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Discovers workbench images via ImageStream annotations for user selection" "Internal RHOAI"
        notebookController = softwareSystem "ODH Notebook Controller" "Injects OAuth proxy, CA bundles, and ConfigMaps into workbench pods" "Internal RHOAI"
        dspa = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines API for pipeline execution" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data and model artifacts" "External"
        huggingface = softwareSystem "HuggingFace Hub" "Model and dataset repository" "External"
        konflux = softwareSystem "Konflux Build System" "CI/CD system with Hermeto/Cachi2 prefetching" "External"
        registry = softwareSystem "Container Registry" "registry.redhat.io/rhoai/ for published images" "External"

        # Build-time relationships
        aipccBase -> notebooks "Provides base images (CPU, CUDA 13.0, ROCm 7.14)"
        konflux -> notebooks "Builds images with hermetic prefetching"
        notebooks -> registry "Publishes container images"

        # Deployment relationships
        odhOperator -> notebooks "Deploys ImageStream manifests via kustomize"
        odhDashboard -> notebooks "Reads ImageStream annotations for workbench picker"
        notebookController -> notebooks "Injects sidecars and config into workbench pods"

        # Runtime relationships (when images are running as workbenches)
        dataScientist -> notebooks "Uses Jupyter/Code-Server workbenches"
        notebooks -> dspa "Submits pipelines via Elyra" "HTTPS/443"
        notebooks -> s3Storage "Stores/retrieves data artifacts" "HTTPS/443"
        notebooks -> huggingface "Downloads models" "HTTPS/443"
    }

    views {
        systemContext notebooks "SystemContext" {
            include *
            autoLayout
        }

        container notebooks "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
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
        }
    }
}
