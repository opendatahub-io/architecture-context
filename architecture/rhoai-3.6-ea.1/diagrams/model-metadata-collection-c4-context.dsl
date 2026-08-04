workspace {
    model {
        platformEngineer = person "Platform Engineer" "Manages RHOAI platform deployment and configuration"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Data container shipping pre-generated YAML catalogs of Red Hat AI models, MCP servers, and agents" {
            dataContainer = container "Data Container" "ubi9-minimal running sleep infinity, serves YAML catalogs via volume mount at /app/data" "Container (data-only)"
            modelExtractor = container "model-extractor" "Go CLI that fetches metadata from HuggingFace, GitHub, and container registries to generate YAML catalogs" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Go CLI for generating metadata reports from catalog data" "Go CLI (build-time only)"
        }

        huggingFace = softwareSystem "HuggingFace" "AI model hosting platform — provides model collections and metadata" "External"
        gitHub = softwareSystem "GitHub" "Source code and metadata hosting — provides agent metadata and READMEs" "External"
        containerRegistries = softwareSystem "Container Registries" "OCI registries (e.g. quay.io) — provides image architectures and OCI metadata" "External"
        cicd = softwareSystem "CI/CD Pipeline" "Runs model-extractor to generate catalog YAML files" "External"

        rhoaiPlatform = softwareSystem "RHOAI Platform Components" "Platform components that consume model catalog data via volume mounts" "Internal RHOAI"

        # Build-time relationships
        cicd -> modelExtractor "Executes during build pipeline"
        modelExtractor -> huggingFace "Fetches model collections and metadata" "HTTPS/443, Bearer token"
        modelExtractor -> gitHub "Fetches agent metadata and README files" "HTTPS/443, Bearer token"
        modelExtractor -> containerRegistries "Fetches image architectures and OCI metadata" "HTTPS/443, System creds"
        modelExtractor -> dataContainer "Generated YAML files copied into image" "Dockerfile COPY"

        # Runtime relationships
        rhoaiPlatform -> dataContainer "Reads YAML catalog files" "Volume mount /app/data (filesystem)"
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
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
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
