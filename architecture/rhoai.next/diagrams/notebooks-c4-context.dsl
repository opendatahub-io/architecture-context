workspace {
    model {
        dataScientist = person "Data Scientist" "Creates notebooks, trains models, builds pipelines in workbench environments"
        mlEngineer = person "ML Engineer" "Deploys models and orchestrates pipeline workflows"

        notebooks = softwareSystem "Notebooks" "Container image factory producing Jupyter, Code-Server, and Elyra pipeline-runtime images for RHOAI" {
            jupyterImages = container "Jupyter Workbench Images" "JupyterLab 4.6 with data science libraries, CPU/CUDA/ROCm variants" "Container Image"
            codeserverImages = container "Code-Server Workbench Images" "VS Code in browser with data science stack, built from source" "Container Image"
            runtimeImages = container "Pipeline Runtime Images" "Headless Python environments for KFP pipeline step execution" "Container Image"
            baseImages = container "Base Images" "CentOS Stream 9 / RHEL 9.8 with Python 3.12, AIPCC config, PQ crypto" "Container Image"
            imagestreams = container "ImageStream Manifests" "Kustomize manifests with image digests and version tags (N through N-3)" "YAML/Kustomize"
            buildTooling = container "Build Tooling" "buildinputs (Dockerfile parser) and check-payload (FIPS scanner)" "Go CLI"
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Manages workbench pod lifecycle, deploys OAuth proxy sidecars" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Displays available workbench types to users" "Internal RHOAI"
        dsPipelines = softwareSystem "Data Science Pipelines" "Orchestrates ML pipeline workflows using runtime images" "Internal RHOAI"
        rhelAIPyPI = softwareSystem "RHEL AI Python Package Index" "Provides Python wheels via packages.redhat.com AIPCC channels" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "Container image registry for built images" "External"
        konfluxCI = softwareSystem "Konflux CI" "Build pipeline with Cachi2 hermetic prefetch" "External"
        s3Storage = softwareSystem "S3 Object Storage" "Data and model artifact storage" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Pre-trained model downloads" "External"

        # Build-time relationships
        konfluxCI -> notebooks "Builds images via hermetic Dockerfiles"
        notebooks -> rhelAIPyPI "Prefetches Python wheels" "HTTPS/443"
        notebooks -> quayRegistry "Pushes built images" "HTTPS/443"

        # Internal integration
        baseImages -> jupyterImages "Provides BASE_IMAGE foundation"
        baseImages -> codeserverImages "Provides BASE_IMAGE foundation"
        baseImages -> runtimeImages "Provides BASE_IMAGE foundation"
        jupyterImages -> imagestreams "Referenced by digest"
        codeserverImages -> imagestreams "Referenced by digest"
        runtimeImages -> imagestreams "Referenced by digest"

        # Consumer relationships
        notebookController -> imagestreams "Reads ImageStream manifests to discover workbench images" "Kubernetes API"
        dashboard -> imagestreams "Reads annotations for workbench catalog" "Kubernetes API"
        dsPipelines -> runtimeImages "Pulls runtime images for pipeline step execution" "Container Runtime"

        # User relationships
        dataScientist -> notebooks "Uses workbench images for interactive development"
        mlEngineer -> notebooks "Uses runtime images for pipeline execution"

        # Runtime relationships
        jupyterImages -> s3Storage "Accesses data and model artifacts" "HTTPS/443"
        jupyterImages -> huggingFace "Downloads pre-trained models" "HTTPS/443"
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
                background #7ed321
                color #ffffff
            }
            element "Container Image" {
                background #4a90e2
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
