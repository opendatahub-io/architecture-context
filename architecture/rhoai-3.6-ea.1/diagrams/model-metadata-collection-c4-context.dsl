workspace {
    model {
        platformEngineer = person "Platform Engineer" "Builds and deploys RHOAI platform"
        dataScientist = person "Data Scientist" "Browses available models via RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Data container packaging pre-generated YAML catalogs of Red Hat AI model metadata, MCP server metadata, and agent metadata for volume-mount consumption" {
            extractorCLI = container "model-extractor" "Collects metadata from HuggingFace, GitHub, and OCI registries; generates YAML catalog files" "Go CLI (CI/build-time only)"
            reportCLI = container "metadata-report" "Generates completeness reports from extracted catalog data" "Go CLI (CI/build-time only)"
            dataContainer = container "Data Container" "UBI9-micro image running sleep infinity; serves /app/data/ as volume mount point" "Container (UBI9-micro)"
        }

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web-based management interface for Red Hat OpenShift AI" "Internal RHOAI"
        otherComponents = softwareSystem "Other RHOAI Components" "Platform components that consume model catalog data" "Internal RHOAI"

        huggingface = softwareSystem "HuggingFace" "ML model hosting platform and API" "External"
        github = softwareSystem "GitHub" "Source code hosting and API" "External"
        ociRegistries = softwareSystem "OCI Container Registries" "Container image registries" "External"
        ciPipeline = softwareSystem "CI/CD Pipeline" "Konflux/Tekton build pipeline" "Infrastructure"

        # CI/build-time relationships
        ciPipeline -> extractorCLI "Executes during build"
        extractorCLI -> huggingface "Fetches model collection metadata" "HTTPS/443, Bearer HF_TOKEN (optional)"
        extractorCLI -> github "Fetches agent metadata and READMEs" "HTTPS/443, Bearer GITHUB_TOKEN (optional)"
        extractorCLI -> ociRegistries "Queries image manifests" "HTTPS/443, registry auth"
        extractorCLI -> dataContainer "Generated YAML catalogs copied into image" "Dockerfile COPY"
        reportCLI -> dataContainer "Reads catalog files for reporting"

        # Runtime relationships (volume mount, no network)
        rhoaiDashboard -> dataContainer "Mounts /app/data/ volume" "Filesystem (no network)"
        otherComponents -> dataContainer "Mounts /app/data/ volume" "Filesystem (no network)"
        dataScientist -> rhoaiDashboard "Browses available models"
        platformEngineer -> ciPipeline "Triggers builds"
    }

    views {
        systemContext modelMetadataCollection "SystemContext" {
            include *
            autoLayout
        }

        container modelMetadataCollection "Containers" {
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
            }
            element "Infrastructure" {
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
