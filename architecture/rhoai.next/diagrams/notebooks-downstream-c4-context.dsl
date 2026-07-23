workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses interactive workbenches for ML development"
        mlEngineer = person "ML Engineer" "Builds and runs ML pipelines using runtime images"

        notebooksDownstream = softwareSystem "notebooks-downstream" "Container image factory producing ~35 workbench and pipeline runtime images for RHOAI" {
            jupyterWorkbenches = container "Jupyter Workbenches" "Interactive JupyterLab environments (Minimal, DataScience, PyTorch, TensorFlow, TrustyAI)" "Container Images"
            ideWorkbenches = container "IDE Workbenches" "Code Server (VS Code) and RStudio Server browser-based IDEs" "Container Images"
            pipelineRuntimes = container "Pipeline Runtimes" "Stripped-down execution environments for Elyra and KFP pipeline steps" "Container Images"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize-based OpenShift ImageStream definitions with 6 version history (N through N-5)" "Kustomize Manifests"
            buildinputs = container "buildinputs" "Go CLI tool that analyzes Dockerfile COPY/ADD directives to create minimal build contexts" "Go CLI"
        }

        odhNotebookController = softwareSystem "odh-notebook-controller" "Creates and manages workbench Pods from container images when users create Notebook CRs" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests and platform Gateway configuration" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Auth sidecar injected into each workbench Pod for OIDC/Bearer token authentication" "Internal RHOAI"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI that reads ImageStream annotations to present workbench options to users" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration that uses runtime images as execution environments" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "Notebook-to-pipeline execution using runtime images" "Internal RHOAI"

        openshiftGateway = softwareSystem "OpenShift Gateway (Envoy)" "Routes external HTTPS traffic to workbench Pods via HTTPRoute" "External"
        konflux = softwareSystem "Konflux (AppStudio)" "Builds multi-arch container images via Tekton pipelines" "External"
        quayRegistry = softwareSystem "quay.io" "Container image registry for built workbench and runtime images" "External"
        pypi = softwareSystem "PyPI" "Python Package Index for Python dependency installation" "External"
        nvidiaRepo = softwareSystem "NVIDIA CUDA Repository" "CUDA toolkit and cuDNN libraries for GPU acceleration" "External"
        amdRepo = softwareSystem "AMD ROCm Repository" "ROCm compute runtime for AMD GPU acceleration" "External"
        s3Storage = softwareSystem "S3 Storage" "Object storage for ML model artifacts and training data" "External"
        github = softwareSystem "GitHub" "Source code hosting and PR-triggered CI via PipelinesAsCode" "External"

        # User interactions
        dataScientist -> notebooksDownstream "Uses workbench images for interactive ML development"
        mlEngineer -> notebooksDownstream "Uses runtime images for pipeline execution"

        # Internal RHOAI integrations
        odhNotebookController -> notebooksDownstream "Creates Pods from container images" "Kubernetes API / TLS"
        rhodsOperator -> notebooksDownstream "Deploys ImageStream manifests" "Kubernetes API / TLS"
        kubeRbacProxy -> notebooksDownstream "Auth sidecar in each workbench Pod" "HTTPS/8443"
        odhDashboard -> notebooksDownstream "Reads ImageStream annotations" "Kubernetes API"
        kfp -> notebooksDownstream "Uses runtime images for pipeline steps" "Kubernetes API / TLS"
        elyra -> notebooksDownstream "Uses runtime images for notebook-to-pipeline" "Kubernetes API / TLS"

        # External integrations
        openshiftGateway -> notebooksDownstream "Routes user traffic to workbenches" "HTTPS/443"
        konflux -> notebooksDownstream "Builds container images" "Tekton pipelines"
        notebooksDownstream -> quayRegistry "Publishes built images" "HTTPS/443"
        notebooksDownstream -> pypi "Downloads Python packages at build time" "HTTPS/443"
        notebooksDownstream -> nvidiaRepo "Downloads CUDA toolkit at build time" "HTTPS/443"
        notebooksDownstream -> amdRepo "Downloads ROCm packages at build time" "HTTPS/443"
        notebooksDownstream -> s3Storage "Accesses data at runtime (pipeline execution)" "HTTPS/443"
        github -> konflux "PR webhook triggers image builds" "HTTPS/443"
    }

    views {
        systemContext notebooksDownstream "SystemContext" {
            include *
            autoLayout
        }

        container notebooksDownstream "Containers" {
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
