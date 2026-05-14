workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses workbenches for interactive data science workflows"
        mlEngineer = person "ML Engineer" "Builds and runs ML pipelines using runtime images"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and deploys components"

        notebooks = softwareSystem "Notebooks (Image Factory)" "Produces pre-built container images for interactive workbenches and pipeline runtimes" {
            jupyterImages = container "Jupyter Workbench Images" "JupyterLab environments: minimal, datascience, pytorch, tensorflow, trustyai, llmcompressor (CPU/CUDA/ROCm variants)" "Container Images"
            codeserverImage = container "code-server Workbench Image" "VS Code-based development environment with nginx proxy" "Container Image"
            rstudioImages = container "RStudio Workbench Images" "RStudio Server IDE for R and Python (CPU/CUDA)" "Container Images"
            runtimeImages = container "Pipeline Runtime Images" "Minimal execution environments for Elyra pipeline nodes" "Container Images"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize manifests defining OpenShift ImageStream resources" "Kustomize YAML"
        }

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Creates StatefulSets from ImageStream references; injects kube-rbac-proxy sidecar" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Reads ImageStream annotations to present workbench image catalog to users" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Applies kustomize manifests to create ImageStream resources on cluster" "Internal RHOAI"
        elyra = softwareSystem "Elyra Pipeline Engine" "Uses runtime ImageStream annotations for pipeline node execution" "Internal RHOAI"
        openshiftImageStream = softwareSystem "OpenShift ImageStream" "Tracks container image references and tags on cluster" "OpenShift Platform"

        konflux = softwareSystem "Konflux Build System" "Hermetic CI/CD with 102 Tekton PipelineRuns, cachi2 prefetching" "External"
        containerRegistry = softwareSystem "Container Registry" "registry.redhat.io / quay.io for image storage and distribution" "External"
        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API for cluster resource management" "OpenShift Platform"
        pypi = softwareSystem "PyPI / Package Registries" "Python package repositories for user-initiated installs" "External"
        s3 = softwareSystem "S3-Compatible Storage" "Object storage for data access from notebooks" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code and notebook repositories" "External"
        mongodb = softwareSystem "MongoDB" "Database connectivity via mongocli" "External"

        # Relationships - Users
        dataScientist -> odhDashboard "Selects workbench image" "HTTPS/443"
        dataScientist -> notebooks "Uses workbench for interactive work" "HTTPS/443 via platform gateway"
        mlEngineer -> elyra "Runs pipelines using runtime images" "HTTPS/443"
        platformAdmin -> rhodsOperator "Manages platform deployment" "HTTPS/443"

        # Relationships - Build & Deploy
        konflux -> containerRegistry "Pushes hermetically-built images" "HTTPS/443"
        rhodsOperator -> openshiftAPI "Applies ImageStream manifests" "HTTPS/6443"
        rhodsOperator -> imageStreamManifests "Reads kustomize manifests" ""
        odhDashboard -> openshiftAPI "Reads ImageStream annotations" "HTTPS/6443"
        odhNotebookController -> openshiftAPI "Creates StatefulSets + injects kube-rbac-proxy" "HTTPS/6443"
        openshiftAPI -> containerRegistry "kubelet pulls workbench images" "HTTPS/443"
        openshiftAPI -> openshiftImageStream "Manages ImageStream resources" ""

        # Relationships - Runtime
        jupyterImages -> pypi "User pip install" "HTTPS/443"
        jupyterImages -> s3 "Data access" "HTTPS/443"
        jupyterImages -> gitRepos "Clone repos" "HTTPS/443"
        jupyterImages -> mongodb "Database queries" "TCP/27017"

        # Relationships - Internal Integration
        odhDashboard -> odhNotebookController "Triggers workbench creation" ""
        elyra -> runtimeImages "Selects runtime for pipeline nodes" ""
        odhNotebookController -> jupyterImages "Creates pods from image references" ""
        odhNotebookController -> codeserverImage "Creates pods from image references" ""
        odhNotebookController -> rstudioImages "Creates pods from image references" ""
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
            element "OpenShift Platform" {
                background #cc0000
                color #ffffff
            }
            element "Container Images" {
                background #4a90e2
                color #ffffff
            }
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "Kustomize YAML" {
                background #f5a623
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
