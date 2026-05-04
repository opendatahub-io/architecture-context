workspace {
    model {
        datascientist = person "Data Scientist" "Creates and uses workbenches for interactive data science, model development, and pipeline authoring"
        mlEngineer = person "ML Engineer" "Deploys and manages ML pipelines that use runtime images"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Container image factory producing pre-built workbench IDEs (Jupyter, RStudio, code-server) and pipeline runtime environments for data science workflows" {
            jupyterImages = container "Jupyter Workbench Images" "Interactive JupyterLab environments with data science libraries (minimal, datascience, pytorch, tensorflow, trustyai, llmcompressor variants)" "Container Images"
            codeserverImage = container "Code-Server Workbench Image" "VS Code-based development environment with nginx proxy" "Container Image"
            rstudioImages = container "RStudio Workbench Images" "RStudio Server IDE for R and Python (CPU and CUDA variants)" "Container Images"
            runtimeImages = container "Pipeline Runtime Images" "Minimal execution environments for Elyra pipeline node execution" "Container Images"
            baseImages = container "Base Images" "Foundation layers providing UBI9, Python 3.12, and accelerator libraries (CPU/CUDA/ROCm)" "Container Images"
            imagestreamManifests = container "ImageStream Manifests" "Kustomize definitions that register images with OpenShift for platform discovery" "Kustomize YAML"
            buildTooling = container "Build Tooling" "Lock file generators, dependency management, Konflux pipeline integration" "Python/Bash/Tekton"
        }

        // Platform components (internal)
        odhNotebookController = softwareSystem "ODH Notebook Controller" "Creates StatefulSets from ImageStream references; manages notebook pod lifecycle" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing data science projects; reads ImageStream annotations to present workbench catalog" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that applies kustomize manifests to create/update ImageStreams on cluster" "Internal RHOAI"
        odhOperator = softwareSystem "opendatahub-operator" "ODH platform operator (upstream equivalent of rhods-operator)" "Internal ODH"
        elyraPipeline = softwareSystem "Elyra Pipeline Engine" "Pipeline execution engine that selects runtime images for notebook node execution" "Internal RHOAI"

        // External systems
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io (RHOAI) and quay.io (ODH) hosting built container images" "External"
        konflux = softwareSystem "Konflux Build System" "CI/CD platform running 102 Tekton PipelineRuns for hermetic multi-arch container builds" "External"
        openshiftAPI = softwareSystem "OpenShift API" "Kubernetes API server for cluster resource management (ImageStreams, StatefulSets)" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data access from notebooks" "External"
        pypi = softwareSystem "PyPI / Package Registries" "Python package index for user-initiated pip install at runtime" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code and notebook repositories cloned by users" "External"

        // Relationships
        datascientist -> odhDashboard "Selects workbench image and creates notebook" "HTTPS/443"
        datascientist -> notebooks "Uses workbench IDE for interactive data science" "HTTPS/443 via platform gateway"
        mlEngineer -> elyraPipeline "Submits pipelines that use runtime images"

        konflux -> notebooks "Builds container images hermetically" "Tekton PipelineRuns"
        konflux -> containerRegistry "Pushes built images" "HTTPS/443"

        rhodsOperator -> notebooks "Applies kustomize manifests" "HTTPS/6443"
        rhodsOperator -> openshiftAPI "Creates ImageStream resources" "HTTPS/6443"
        odhOperator -> notebooks "Applies kustomize manifests (ODH)" "HTTPS/6443"

        odhDashboard -> openshiftAPI "Reads ImageStream annotations for workbench catalog" "HTTPS/6443"
        odhNotebookController -> openshiftAPI "Creates StatefulSets + kube-rbac-proxy sidecars" "HTTPS/6443"
        openshiftAPI -> containerRegistry "Pulls workbench/runtime images" "HTTPS/443"

        elyraPipeline -> notebooks "Uses runtime images for pipeline node execution"

        notebooks -> s3Storage "Data access from notebooks" "HTTPS/443"
        notebooks -> pypi "User-initiated pip install" "HTTPS/443"
        notebooks -> gitRepos "Clone user notebooks and source" "HTTPS/443"

        // Internal container relationships
        baseImages -> jupyterImages "Base layer for"
        baseImages -> codeserverImage "Base layer for"
        baseImages -> rstudioImages "Base layer for"
        baseImages -> runtimeImages "Base layer for"
        buildTooling -> baseImages "Manages dependencies for"
        imagestreamManifests -> jupyterImages "Registers"
        imagestreamManifests -> codeserverImage "Registers"
        imagestreamManifests -> rstudioImages "Registers"
        imagestreamManifests -> runtimeImages "Registers"
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
            element "Internal ODH" {
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #438dd5
                color #ffffff
            }
            element "Container" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
