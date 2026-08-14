workspace {
    model {
        user = person "Data Scientist" "Creates and runs ML workbenches for interactive development"

        notebooks = softwareSystem "Notebooks" "Multi-variant container image build repository producing JupyterLab and code-server workbench images for RHOAI" {
            jupyterlab = container "JupyterLab Server" "Interactive notebook IDE with ML framework stacks (PyTorch, TensorFlow, LLMCompressor)" "Python / UBI9"
            codeserver = container "code-server" "VS Code-based IDE with nginx proxy and culling shim" "Node.js + Python / UBI9"
            startNotebook = container "start-notebook.sh" "Entrypoint that configures JupyterLab ServerApp from platform env vars" "Shell Script"
            runCodeServer = container "run-code-server.sh" "Entrypoint that starts code-server with nginx reverse proxy" "Shell Script"
            cullingShim = container "Culling Shim" "httpd CGI that translates code-server heartbeat to kernel-compatible JSON for idle detection" "httpd + CGI"
            buildinputs = container "buildinputs" "Build pipeline tool generating dependency metadata" "Go" "Build Tool"
            checkPayload = container "check-payload" "Build pipeline tool validating FIPS compliance" "Go" "Build Tool"
        }

        notebookController = softwareSystem "odh-notebook-controller" "Manages workbench StatefulSet lifecycle, injects oauth-proxy sidecar and environment variables" "Internal RHOAI"
        oauthProxy = softwareSystem "oauth-proxy" "Sidecar container providing OpenShift OAuth authentication" "Internal RHOAI"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform (kfp SDK v2.17.0 bundled)" "Internal RHOAI"
        codeflare = softwareSystem "CodeFlare" "Distributed training framework (codeflare-sdk v0.38.2 bundled)" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "CI/CD pipeline for hermetic container image builds" "External"
        k8sAPI = softwareSystem "Kubernetes API" "Cluster API server for workload management" "External"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for model artifacts and datasets" "External"
        openshiftOAuth = softwareSystem "OpenShift OAuth" "Platform identity and authentication provider" "External"

        user -> notebooks "Develops ML models via workbench UI"
        user -> jupyterlab "Writes and executes notebooks"
        user -> codeserver "Writes code in VS Code IDE"

        notebookController -> notebooks "Creates StatefulSets, injects sidecars, polls idle status"
        oauthProxy -> jupyterlab "Forwards authenticated requests" "HTTP/8888"
        oauthProxy -> codeserver "Forwards authenticated requests" "HTTP/8787"
        notebookController -> oauthProxy "Injects as sidecar container"

        startNotebook -> jupyterlab "Configures and launches ServerApp"
        runCodeServer -> codeserver "Starts code-server with nginx"
        notebookController -> cullingShim "Polls /api/kernels/ for idle detection"

        jupyterlab -> k8sAPI "User-authored automation" "HTTPS/443"
        jupyterlab -> s3Storage "Model and data access" "HTTPS/443"
        codeserver -> k8sAPI "User-authored automation" "HTTPS/443"
        codeserver -> s3Storage "Model and data access" "HTTPS/443"

        jupyterlab -> kubeflowPipelines "Pipeline authoring via kfp SDK" "SDK"
        jupyterlab -> codeflare "Distributed training job submission" "SDK"

        konflux -> buildinputs "Runs during image build"
        konflux -> checkPayload "Runs during image build"

        oauthProxy -> openshiftOAuth "Validates OAuth tokens" "HTTPS"
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
            element "Build Tool" {
                background #f5a623
                color #ffffff
            }
            element "Person" {
                background #4a90e2
                color #ffffff
                shape person
            }
        }
    }
}
