workspace {
    model {
        dataScientist = person "Data Scientist" "Creates and runs ML experiments in interactive workbenches"
        mlEngineer = person "ML Engineer" "Builds automated ML pipelines using runtime images"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Container image repository providing JupyterLab, VS Code, and RStudio workbench environments plus Kubeflow Pipelines runtime images for RHOAI" {
            workbenchImages = container "Workbench Images" "Interactive development environments" "Container Images" {
                jupyterImages = component "Jupyter Workbenches" "JupyterLab 4.4 environments with various ML frameworks"
                codeServerImages = component "Code Server Workbenches" "VS Code-based development environments"
                rstudioImages = component "RStudio Workbenches" "RStudio Server for R-based workflows"
            }

            runtimeImages = container "Runtime Images" "Lightweight execution environments" "Container Images" {
                runtimeCPU = component "Runtime CPU" "Minimal Python runtime for pipelines"
                runtimeGPU = component "Runtime GPU" "GPU-enabled runtime for ML training"
            }

            buildSystem = container "Build System" "Multi-arch image building" "Konflux Tekton" {
                buildPipelines = component "Tekton Pipelines" "Multi-arch container builds"
                kustomizeManifests = component "Kustomize Manifests" "ImageStream definitions"
            }
        }

        notebookController = softwareSystem "ODH Notebook Controller" "Launches workbench pods using container images" "Internal ODH"
        odhDashboard = softwareSystem "ODH Dashboard" "Web UI for managing workbenches" "Internal ODH"
        kubeflowPipelines = softwareSystem "Kubeflow Pipelines" "ML pipeline orchestration platform" "Internal ODH"
        modelMesh = softwareSystem "Model Mesh" "Multi-model serving platform" "Internal ODH"

        s3Storage = softwareSystem "S3 Storage" "Object storage for data and models" "External"
        quayIO = softwareSystem "Quay.io Registry" "Container image registry" "External"
        redhatRegistry = softwareSystem "Red Hat Registry" "UBI base images and RHEL packages" "External"
        jupyterLab = softwareSystem "JupyterLab" "Interactive notebook interface" "External"
        pytorch = softwareSystem "PyTorch" "Deep learning framework" "External"
        tensorflow = softwareSystem "TensorFlow" "Deep learning framework" "External"
        openShiftRouter = softwareSystem "OpenShift Router" "Ingress controller with TLS termination" "Platform"
        openShiftImageStreams = softwareSystem "OpenShift ImageStreams" "Image reference management" "Platform"
        konfluxPlatform = softwareSystem "Konflux Platform" "Red Hat CI/CD build platform" "Platform"

        # User relationships
        dataScientist -> odhDashboard "Selects workbench image and launches notebook"
        dataScientist -> openShiftRouter "Accesses Jupyter/RStudio/VS Code via HTTPS/443"
        mlEngineer -> kubeflowPipelines "Creates pipelines using runtime images"

        # Notebook controller relationships
        notebookController -> openShiftImageStreams "Queries available workbench images"
        notebookController -> workbenchImages "Launches pods using images"
        notebookController -> openShiftRouter "Creates Routes with OAuth proxy"

        # Dashboard relationships
        odhDashboard -> openShiftImageStreams "Lists available workbench images" "HTTPS/6443"
        odhDashboard -> notebookController "Triggers notebook creation"

        # Kubeflow relationships
        kubeflowPipelines -> runtimeImages "Executes pipeline tasks in containers"
        kubeflowPipelines -> s3Storage "Stores/retrieves artifacts" "HTTPS/443"

        # Model Mesh relationships
        modelMesh -> runtimeImages "Uses for model serving initialization"

        # Workbench runtime relationships
        jupyterImages -> s3Storage "Reads/writes data and models" "HTTPS/443 AWS SigV4"
        runtimeImages -> s3Storage "Loads/saves artifacts" "HTTPS/443 AWS SigV4"
        runtimeImages -> kubeflowPipelines "Reports task status and metrics" "HTTPS/443"

        # Router relationships
        openShiftRouter -> notebookController "Routes traffic to OAuth proxy sidecars" "HTTPS/8443"

        # ImageStream relationships
        openShiftImageStreams -> quayIO "Pulls image metadata" "HTTPS/443"

        # Build system relationships
        buildPipelines -> konfluxPlatform "Executes on Konflux CI/CD"
        buildPipelines -> redhatRegistry "Pulls UBI9 base images" "HTTPS/443"
        buildPipelines -> pytorch "Installs ML framework" "pip install"
        buildPipelines -> tensorflow "Installs ML framework" "pip install"
        buildPipelines -> jupyterLab "Installs notebook interface" "pip install"
        buildPipelines -> quayIO "Pushes built images" "HTTPS/443"
        kustomizeManifests -> openShiftImageStreams "Defines image references"

        # External dependencies
        workbenchImages -> jupyterLab "Includes JupyterLab 4.4"
        workbenchImages -> pytorch "Includes PyTorch 2.x (GPU variants)"
        workbenchImages -> tensorflow "Includes TensorFlow 2.x (GPU variants)"
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

        component workbenchImages "WorkbenchImages" {
            include *
            autoLayout
        }

        component runtimeImages "RuntimeImages" {
            include *
            autoLayout
        }

        component buildSystem "BuildSystem" {
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
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Container Images" {
                background #f5a623
                color #000000
            }
        }

        theme default
    }
}
