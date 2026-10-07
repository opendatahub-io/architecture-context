workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and uses workbench environments for ML/AI development"
        mlEngineer = person "ML Engineer" "Builds and runs ML pipelines using runtime images"

        notebooksDownstream = softwareSystem "Notebooks Downstream" "Container image factory producing ~35 workbench and runtime images for RHOAI" {
            jupyterImages = container "Jupyter Workbench Images" "JupyterLab with variants: minimal, datascience, pytorch, tensorflow, trustyai" "Container Images (Python)"
            codeServerImage = container "Code Server Image" "VS Code browser IDE (code-server v4.98.0) with NGINX reverse proxy" "Container Image (Python/TypeScript)"
            rstudioImage = container "RStudio Image" "RStudio Server 2024.12.1 with R 4.4.3" "Container Image (R/Python)"
            runtimeImages = container "Pipeline Runtime Images" "Stripped-down execution environments for KFP/Elyra pipeline steps" "Container Images (Python)"
            imageStreamManifests = container "ImageStream Manifests" "Kustomize manifests defining OpenShift ImageStreams with 6 version history" "Kustomize YAML"
            buildinputsTool = container "buildinputs" "Go CLI tool analyzing Dockerfile COPY/ADD for minimal build contexts" "Go CLI"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Creates and manages workbench Pods, injects kube-rbac-proxy sidecar" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Deploys ImageStream manifests and manages platform lifecycle" "Internal RHOAI"
        kubeRbacProxy = softwareSystem "kube-rbac-proxy" "Authentication sidecar injected into each workbench Pod" "Internal RHOAI"
        odhDashboard = softwareSystem "OpenDataHub Dashboard" "UI for selecting and launching workbenches" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline orchestration using runtime images" "Internal RHOAI"
        elyra = softwareSystem "Elyra" "Notebook-to-pipeline execution" "Internal RHOAI"
        openShiftGateway = softwareSystem "OpenShift Gateway" "Envoy-based ingress gateway for traffic routing" "External"
        openShiftOAuth = softwareSystem "OpenShift OAuth / OIDC" "User authentication provider" "External"
        konflux = softwareSystem "Konflux" "CI/CD platform building multi-arch images via Tekton" "External"
        quayIO = softwareSystem "quay.io" "Container image registry" "External"
        nvidiaRepo = softwareSystem "NVIDIA CUDA Repository" "CUDA toolkit and cuDNN packages" "External"
        amdROCm = softwareSystem "AMD ROCm Repository" "ROCm GPU compute packages" "External"
        pypi = softwareSystem "PyPI" "Python package index" "External"
        s3 = softwareSystem "S3 / Object Storage" "Model artifact and dataset storage" "External"

        dataScientist -> odhDashboard "Selects workbench type and version"
        dataScientist -> notebooksDownstream "Uses workbench images for interactive development"
        mlEngineer -> kfp "Submits ML pipelines"

        odhDashboard -> notebookController "Creates Notebook CR" "Kubernetes API"
        notebookController -> notebooksDownstream "Creates Pods from workbench images"
        notebookController -> kubeRbacProxy "Injects auth sidecar into workbench Pods"
        rhodsOperator -> imageStreamManifests "Deploys ImageStream definitions" "Kubernetes API"

        openShiftGateway -> kubeRbacProxy "Routes user traffic" "HTTPS/8443"
        kubeRbacProxy -> jupyterImages "Proxies authenticated requests" "HTTP/8888"
        kubeRbacProxy -> codeServerImage "Proxies authenticated requests" "HTTP/8787"
        kubeRbacProxy -> rstudioImage "Proxies authenticated requests" "HTTP/8787"
        openShiftOAuth -> kubeRbacProxy "Provides OIDC tokens for validation"

        kfp -> runtimeImages "Executes pipeline steps"
        elyra -> runtimeImages "Executes notebook pipelines"
        runtimeImages -> s3 "Downloads/uploads data and models" "HTTPS/443"

        konflux -> notebooksDownstream "Builds multi-arch container images" "Tekton pipelines"
        konflux -> quayIO "Pushes built images" "HTTPS/443"
        buildinputsTool -> jupyterImages "Computes minimal build contexts"

        notebooksDownstream -> nvidiaRepo "Downloads CUDA packages (build-time)" "HTTPS/443"
        notebooksDownstream -> amdROCm "Downloads ROCm packages (build-time)" "HTTPS/443"
        notebooksDownstream -> pypi "Downloads Python packages (build-time)" "HTTPS/443"
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #357abd
                color #ffffff
            }
        }
    }
}
