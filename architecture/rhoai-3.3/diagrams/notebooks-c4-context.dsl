workspace {
    model {
        user = person "Data Scientist" "Creates ML models, runs experiments, trains models in interactive notebooks"

        notebooks = softwareSystem "Notebooks (Workbench Images)" "Provides containerized IDE environments (Jupyter, RStudio, CodeServer) for data science development" {
            controller = container "odh-notebook-controller" "Manages workbench lifecycle (creates StatefulSets, Services, Routes)" "Go Operator"
            workbenchImages = container "Workbench Images" "Pre-built container images with Jupyter, PyTorch, TensorFlow, RStudio, CodeServer" "Container Images"
            runtimeImages = container "Runtime Images" "Lightweight headless images for Elyra pipeline execution" "Container Images"
            oauthProxy = container "OAuth Proxy" "Authenticates users via OpenShift OAuth before allowing workbench access" "Go Sidecar"
        }

        dashboard = softwareSystem "ODH Dashboard" "Web UI for browsing and launching workbenches" "Internal RHOAI"
        pipelines = softwareSystem "Kubeflow Pipelines (Elyra)" "Orchestrates ML pipeline execution using runtime images" "Internal RHOAI"
        openshift = softwareSystem "OpenShift Platform" "Kubernetes platform with Routes, OAuth, and storage" "Platform"
        pypi = softwareSystem "PyPI (pypi.org)" "Python package index for installing libraries at runtime" "External"
        quay = softwareSystem "Quay.io" "Container registry for publishing workbench images" "External"
        redhat = softwareSystem "Red Hat Registry" "Registry for RHEL base images (UBI9)" "External"
        s3 = softwareSystem "S3 Storage" "Object storage for model artifacts and datasets" "External"
        git = softwareSystem "Git Repositories" "Source code repositories (GitHub, GitLab)" "External"

        %% User interactions
        user -> dashboard "Browses available workbench images and launches workbenches"
        user -> notebooks "Develops ML models, runs notebooks, trains models via browser" "HTTPS/443 (OAuth)"
        user -> git "Clones repositories, pushes code" "via workbench terminal"

        %% Dashboard integration
        dashboard -> notebooks "Creates workbench by calling Kubernetes API to trigger controller" "HTTPS/6443"

        %% Notebook dependencies
        notebooks -> openshift "Uses Routes for ingress, OAuth for auth, PVCs for storage" "HTTPS/6443"
        notebooks -> pypi "Installs Python packages at runtime (pip/uv)" "HTTPS/443"
        notebooks -> s3 "Reads/writes model artifacts and datasets" "HTTPS/443 (AWS IAM)"
        notebooks -> git "Clones repositories, pushes commits" "HTTPS/443 (SSH/PAT)"

        %% Pipeline integration
        pipelines -> notebooks "Launches runtime images for pipeline node execution" "Kubernetes API"
        notebooks -> pipelines "Submits Elyra pipelines from Jupyter notebooks" "HTTP/8888"

        %% Build and deployment
        quay -> notebooks "Hosts published workbench images" "Pull images"
        redhat -> notebooks "Provides RHEL base images (UBI9)" "Pull base images"

        %% Container relationships
        controller -> workbenchImages "Deploys as StatefulSets with PVCs"
        controller -> oauthProxy "Injects as sidecar container in workbench pods"
        pipelines -> runtimeImages "Launches as pods for pipeline execution"
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
                color #000000
            }
            element "Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }

    configuration {
        scope softwaresystem
    }
}
