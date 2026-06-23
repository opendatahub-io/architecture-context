workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs interactive notebooks, trains ML models, builds pipelines"
        mlEngineer = person "ML Engineer" "Deploys models, runs pipelines, manages workbenches"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform, configures workbench images"

        notebooks = softwareSystem "Notebooks (Workbench & Runtime Images)" "Container image factory producing 18+ JupyterLab, VS Code, and pipeline runtime images for RHOAI" {
            baseImages = container "Base Images" "CentOS Stream 9 base images with Python 3.12, AIPCC packages, accelerator drivers (CPU/CUDA/ROCm)" "Dockerfile"
            jupyterWorkbenches = container "Jupyter Workbenches" "JupyterLab-based interactive workbench images: minimal, datascience, pytorch, tensorflow, trustyai, llmcompressor" "Python/JupyterLab"
            codeServerWorkbench = container "code-server Workbench" "VS Code (code-server v4.106.3) workbench with nginx proxy" "TypeScript/Node.js"
            pipelineRuntimes = container "Pipeline Runtimes" "Headless runtime images with Elyra bootstrapper for Data Science Pipeline steps" "Python"
            kustomizeManifests = container "Kustomize Manifests" "OpenShift ImageStream definitions with SHA256-pinned image refs and kustomize replacements" "YAML/Kustomize"
            mongocliBuild = container "mongocli Build Stage" "FIPS-compliant MongoDB CLI binary built from Go source" "Go"
        }

        odhNotebookController = softwareSystem "ODH Notebook Controller" "Launches workbench pods using ImageStream tags, injects kube-rbac-proxy sidecar" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Applies ImageStream manifests to cluster, manages RHOAI lifecycle" "Internal RHOAI"
        dsp = softwareSystem "Data Science Pipelines" "Orchestrates ML pipeline execution using runtime images" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User-facing UI for selecting and launching workbenches" "Internal RHOAI"
        kubeRBACProxy = softwareSystem "kube-rbac-proxy" "OAuth2/OIDC authentication sidecar injected into workbench pods" "Internal RHOAI"

        konflux = softwareSystem "Konflux / Tekton" "CI/CD platform with hermetic build pipelines and Cachi2 prefetch" "External"
        aipccIndex = softwareSystem "AIPCC PyPI Index" "Red Hat AI Python Package Index at packages.redhat.com" "External"
        containerRegistry = softwareSystem "Container Registry" "quay.io (ODH) / registry.redhat.io (RHOAI) for image storage" "External"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for resource management" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for data access from notebooks" "External"
        gitRepos = softwareSystem "Git Repositories" "Source code repositories accessed from notebooks" "External"

        # User interactions
        dataScientist -> rhoaiDashboard "Selects workbench image via UI"
        dataScientist -> jupyterWorkbenches "Runs notebooks, trains models" "HTTPS/443 via Gateway"
        dataScientist -> codeServerWorkbench "Develops code in VS Code" "HTTPS/443 via Gateway"
        mlEngineer -> dsp "Submits pipeline runs using runtime images"
        platformAdmin -> rhodsOperator "Configures RHOAI platform"

        # Build-time relationships
        konflux -> notebooks "Builds container images via 85 Tekton pipelines" "HTTPS/443"
        baseImages -> jupyterWorkbenches "FROM (layered inheritance)"
        baseImages -> codeServerWorkbench "FROM (layered inheritance)"
        baseImages -> pipelineRuntimes "FROM (layered inheritance)"
        mongocliBuild -> jupyterWorkbenches "Embeds mongocli binary (datascience/pytorch)"
        notebooks -> aipccIndex "Fetches Python wheels during prefetch" "HTTPS/443"
        notebooks -> containerRegistry "Pushes built images" "HTTPS/443"

        # Runtime relationships
        rhodsOperator -> kustomizeManifests "Reads and applies ImageStream manifests"
        rhodsOperator -> kubernetesAPI "Creates ImageStream resources" "HTTPS/443"
        odhNotebookController -> jupyterWorkbenches "Launches workbench pods from ImageStream tags"
        odhNotebookController -> codeServerWorkbench "Launches workbench pods from ImageStream tags"
        odhNotebookController -> kubeRBACProxy "Injects as auth sidecar" "8443/TCP"
        dsp -> pipelineRuntimes "Runs pipeline steps using runtime images"
        rhoaiDashboard -> kubernetesAPI "Queries ImageStream API for available images" "HTTPS/443"
        jupyterWorkbenches -> kubernetesAPI "Pipeline submission, K8s ops" "HTTPS/443"
        jupyterWorkbenches -> s3Storage "Data access (user-configured)" "HTTPS/443"
        jupyterWorkbenches -> gitRepos "Source code access" "HTTPS/443"
        codeServerWorkbench -> kubernetesAPI "K8s operations" "HTTPS/443"
        codeServerWorkbench -> s3Storage "Data access" "HTTPS/443"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
