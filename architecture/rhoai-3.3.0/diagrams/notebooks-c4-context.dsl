workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and experiments with ML models using interactive notebooks"
        admin = person "Platform Admin" "Manages notebook images and platform configuration"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Provides containerized IDE environments (Jupyter, RStudio, CodeServer) for data science workloads" {
            jupyterWorkbenches = container "Jupyter Workbenches" "Interactive notebook environments with ML frameworks" "Container Images (Jupyter, PyTorch, TensorFlow, etc.)" {
                jupyterMinimal = component "Jupyter Minimal" "Lightweight JupyterLab with Python 3.12" "Container Image"
                jupyterDataScience = component "Jupyter DataScience" "JupyterLab with pandas, sklearn, numpy" "Container Image"
                jupyterPyTorch = component "Jupyter PyTorch" "JupyterLab with PyTorch for CUDA/ROCM" "Container Image"
                jupyterTensorFlow = component "Jupyter TensorFlow" "JupyterLab with TensorFlow for CUDA/ROCM" "Container Image"
            }

            otherIDEs = container "Other IDE Workbenches" "Alternative development environments" "Container Images" {
                codeServer = component "CodeServer" "VS Code in browser for data science" "Container Image"
                rstudio = component "RStudio" "RStudio IDE for R development" "Container Image"
            }

            runtimeImages = container "Runtime Images" "Headless containers for pipeline execution (no IDE)" "Container Images (Elyra)" {
                runtimeMinimal = component "Runtime Minimal" "Lightweight Python runtime" "Container Image"
                runtimePyTorch = component "Runtime PyTorch" "PyTorch for pipeline nodes" "Container Image"
                runtimeTensorFlow = component "Runtime TensorFlow" "TensorFlow for pipeline nodes" "Container Image"
            }

            buildInfra = container "Build Infrastructure" "CI/CD for image builds" "Konflux Tekton Pipelines" {
                konflux = component "Konflux Pipelines" "Automated multi-arch builds, scanning, signing" "Tekton"
                baseImages = component "Base Images" "Foundation images with accelerator libs" "Container Build Stage"
            }

            deploymentArtifacts = container "Deployment Artifacts" "Kubernetes manifests for image discovery" "Kustomize" {
                imageStreams = component "ImageStream Manifests" "OpenShift ImageStream definitions" "YAML"
            }
        }

        # External Systems
        notebookController = softwareSystem "odh-notebook-controller" "Kubernetes operator that deploys user workbenches" "ODH Component"
        dashboard = softwareSystem "ODH Dashboard" "Web UI for users to browse and launch workbenches" "ODH Component"
        oauthProxy = softwareSystem "OAuth Proxy" "Sidecar container for OpenShift OAuth authentication" "ODH Component"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "Executes Elyra pipeline nodes in runtime containers" "ODH Component"
        persistentStorage = softwareSystem "Persistent Storage" "Stores user notebooks and data across pod restarts" "OpenShift PVC"
        openshiftRoutes = softwareSystem "OpenShift Routes" "Exposes workbenches externally via HTTPS" "OpenShift Ingress"

        # External Services
        pypi = softwareSystem "pypi.org" "Python package repository for pip/uv installations" "External"
        s3Storage = softwareSystem "S3-compatible Storage" "Object storage for datasets and model artifacts" "External"
        k8sAPI = softwareSystem "Kubernetes API Server" "Cluster management and resource orchestration" "OpenShift"
        quayIO = softwareSystem "quay.io/opendatahub" "Container registry for ODH images" "External"
        redhatRegistry = softwareSystem "registry.redhat.io" "Red Hat container registry for RHOAI images" "External"

        # Relationships - User interactions
        dataScientist -> dashboard "Browses available workbench images"
        dataScientist -> notebookController "Creates workbench via dashboard" "HTTPS"
        dataScientist -> notebooks "Accesses Jupyter/RStudio/CodeServer via browser" "HTTPS/443"
        admin -> konflux "Configures build pipelines"
        admin -> imageStreams "Updates ImageStream manifests"

        # Relationships - Component interactions
        dashboard -> imageStreams "Reads available images" "Kubernetes API"
        notebookController -> jupyterWorkbenches "Deploys workbench pods using images" "Kubernetes API"
        notebookController -> otherIDEs "Deploys RStudio/CodeServer pods" "Kubernetes API"
        notebookController -> oauthProxy "Creates OAuth proxy sidecar" "Kubernetes API"
        notebookController -> openshiftRoutes "Creates HTTPS routes" "Kubernetes API"
        notebookController -> persistentStorage "Attaches PVCs to workbench pods" "Kubernetes API"

        oauthProxy -> jupyterWorkbenches "Protects access with OpenShift OAuth" "HTTP/8888"
        openshiftRoutes -> oauthProxy "Routes external traffic" "HTTPS/8443"

        jupyterWorkbenches -> pypi "Installs Python packages at runtime" "HTTPS/443"
        jupyterWorkbenches -> s3Storage "Loads/saves datasets and models" "HTTPS/443"
        jupyterWorkbenches -> k8sAPI "Runs kubectl/oc commands from terminal" "HTTPS/6443"
        jupyterWorkbenches -> kubeflowPipelines "Submits Elyra pipelines" "HTTP"
        jupyterWorkbenches -> persistentStorage "Stores notebooks and data" "Volume mount"

        kubeflowPipelines -> runtimeImages "Executes pipeline nodes" "Kubernetes API"
        runtimeImages -> s3Storage "Loads/saves pipeline artifacts" "HTTPS/443"

        # Build relationships
        konflux -> baseImages "Builds foundation images" "Buildah"
        baseImages -> jupyterWorkbenches "Base for workbench builds"
        baseImages -> runtimeImages "Base for runtime builds"
        konflux -> quayIO "Publishes ODH images" "HTTPS/443"
        konflux -> redhatRegistry "Publishes RHOAI images" "HTTPS/443"
        konflux -> imageStreams "Updates image digests" "Kubernetes API"

        # External dependencies for builds
        konflux -> redhatRegistry "Pulls UBI9 base images" "HTTPS/443"
    }

    views {
        systemContext notebooks "NotebooksSystemContext" {
            include *
            autoLayout
        }

        container notebooks "NotebooksContainers" {
            include *
            autoLayout
        }

        component jupyterWorkbenches "JupyterWorkbenchesComponents" {
            include *
            autoLayout
        }

        component runtimeImages "RuntimeImagesComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "ODH Component" {
                background #7ed321
                color #000000
            }
            element "OpenShift" {
                background #ee0000
                color #ffffff
            }
            element "Container Image" {
                background #4a90e2
                color #ffffff
            }
            element "Tekton" {
                background #f5a623
                color #000000
            }
        }
    }
}
