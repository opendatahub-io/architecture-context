workspace {
    model {
        dataScientist = person "Data Scientist" "Browses available models, MCP servers, and agents via RHOAI Dashboard"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform and component deployments"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Build-time pipeline that generates YAML catalogs of AI models, MCP servers, and agents; runtime data sidecar serving catalogs via volume mount" {
            modelExtractor = container "model-extractor" "Go CLI that discovers models from HuggingFace, extracts model cards from OCI containers, enriches metadata, and generates YAML catalogs" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Go CLI that generates metadata completeness reports from generated catalogs" "Go CLI (build-time only)"
            dataSidecar = container "Data Sidecar Container" "Minimal UBI 9 container running sleep infinity; serves YAML catalogs via volume mount at /app/data" "UBI 9 minimal-pqc Container"
        }

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing OpenShift AI resources" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Standardized serverless ML inference platform" "Internal RHOAI"
        huggingFace = softwareSystem "HuggingFace" "ML model hub and API for model collections and metadata" "External"
        containerRegistries = softwareSystem "Container Registries" "OCI registries (registry.redhat.io, quay.io) for container images" "External"
        gitHub = softwareSystem "GitHub" "Source code hosting and API for agent metadata" "External"
        konflux = softwareSystem "Konflux" "CI/CD build system using Tekton pipelines" "External"

        # Build-time relationships
        modelExtractor -> huggingFace "Discovers model collections and fetches metadata" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> containerRegistries "Pulls OCI manifests and model card layers" "HTTPS/443, Docker auth"
        modelExtractor -> gitHub "Fetches agent metadata and READMEs" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> dataSidecar "Generates YAML catalogs copied into container" "File I/O → COPY"
        metadataReport -> modelExtractor "Reads generated catalogs for completeness reporting" "File I/O"

        # Build infrastructure
        konflux -> modelMetadataCollection "Builds hermetic multi-arch container image" "Tekton Pipeline"

        # Runtime relationships
        rhoaiDashboard -> dataSidecar "Reads model, MCP server, and agent catalogs" "Volume mount /app/data"
        dataSidecar -> kserve "Catalog data references KServe serving runtime configurations" "Data reference (serving.kserve.io)"

        # User relationships
        dataScientist -> rhoaiDashboard "Browses models and MCP servers" "Web Browser"
        platformAdmin -> konflux "Triggers pipeline builds" "CI/CD"
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
