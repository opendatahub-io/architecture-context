workspace {
    model {
        datascientist = person "Data Scientist" "Browses model catalogs and deploys ML models via the RHOAI dashboard"
        platformadmin = person "Platform Admin" "Manages RHOAI platform configuration and serving runtimes"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Build-time data pipeline that generates YAML catalogs of AI models, MCP servers, agents, and serving runtimes; ships as a data-only container image" {
            modelExtractor = container "model-extractor" "Main pipeline: discovers models, extracts metadata from OCI layers, enriches from multiple sources, generates YAML catalogs" "Go CLI (build-time)"
            metadataReport = container "metadata-report" "Generates metadata completeness and quality reports" "Go CLI (build-time)"
            servingRuntimeCatalog = container "serving-runtime-catalog" "Generates serving runtime catalog from reviewed input YAML files" "Go CLI (build-time)"
            dataContainer = container "Data Container" "UBI-minimal-pqc image carrying pre-generated YAML catalogs under /app/data/; runs sleep infinity as UID 1001" "Container Image (runtime)"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hub providing model collections, metadata, and YAML frontmatter" "External"
        containerRegistry = softwareSystem "Container Registry" "Red Hat container registry (registry.redhat.io) for OCI manifest and layer fetching" "External"
        githubAPI = softwareSystem "GitHub API" "Source for agent metadata and README files" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for browsing model catalogs, MCP servers, and agent starter kits" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Manages model serving lifecycle using serving runtime templates" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform; serves models using ServingRuntime definitions" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "CI/CD build system running Tekton pipelines with hermetic builds" "External"

        # Build-time relationships
        modelExtractor -> huggingface "Fetches model collections and metadata" "HTTPS/443, Bearer HF_TOKEN (optional)"
        modelExtractor -> containerRegistry "Fetches OCI manifests and layers" "HTTPS/443, Docker auth"
        modelExtractor -> githubAPI "Fetches agent metadata and READMEs" "HTTPS/443, Bearer GITHUB_TOKEN (optional)"
        modelExtractor -> dataContainer "Catalog YAML files copied into image" "Dockerfile COPY"
        servingRuntimeCatalog -> dataContainer "Serving runtime YAML copied into image" "Dockerfile COPY"
        konflux -> modelMetadataCollection "Builds container image hermetically" "Tekton Pipeline"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Reads model, MCP server, and agent catalogs" "Volume mount"
        odhModelController -> dataContainer "Reads serving runtime template definitions" "Volume mount"
        odhModelController -> kserve "Creates ServingRuntime resources" "Kubernetes API"

        # User relationships
        datascientist -> rhoaiDashboard "Browses model catalogs"
        platformadmin -> rhoaiDashboard "Manages serving runtimes and agents"
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
