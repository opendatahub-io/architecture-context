workspace {
    model {
        dataScienceAdmin = person "Data Science Admin" "Manages AI model catalog and platform configuration"
        endUser = person "End User / Data Scientist" "Browses and selects AI models for deployment"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Extracts, enriches, and catalogs metadata for Red Hat AI models and MCP servers from OCI registries and HuggingFace" {
            modelExtractor = container "model-extractor" "Go CLI that processes OCI container images, extracts model cards, enriches metadata from HuggingFace, generates standardized YAML catalogs" "Go 1.24 CLI (build-time only)"
            metadataReport = container "metadata-report" "Go CLI that generates metadata completeness and data source reports from processed catalog data" "Go 1.24 CLI (build-time only)"
            dataContainer = container "Data Container" "Minimal UBI9-minimal container packaging pre-generated catalog YAML files and benchmark data at /app/data/ and /app/benchmarks/" "Container Image (runtime artifact)"
        }

        # External Systems - OCI Registries
        redHatRegistry = softwareSystem "Red Hat Container Registry" "registry.redhat.io - Source of modelcar container images containing model cards and metadata" "External"
        accessRegistry = softwareSystem "Red Hat Access Registry" "registry.access.redhat.com - Public registry for MCP server container images" "External"
        quayRegistry = softwareSystem "Quay.io Registry" "quay.io - OCI artifact registry for architecture detection metadata" "External"

        # External Systems - Enrichment
        huggingFace = softwareSystem "HuggingFace" "huggingface.co - Model metadata enrichment: details, collections, README content, YAML frontmatter" "External"

        # Internal Platform Systems
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI Dashboard - displays model catalog to end users" "Internal RHOAI"
        konfluxCI = softwareSystem "Konflux CI/CD" "Tekton-based build pipeline that builds and pushes the data container image" "Internal RHOAI"

        # Build-time relationships
        modelExtractor -> redHatRegistry "Fetches OCI manifests, layers, config blobs" "HTTPS/443, TLS 1.2+, Registry Auth"
        modelExtractor -> accessRegistry "Fetches MCP server image metadata" "HTTPS/443, TLS 1.2+, Public"
        modelExtractor -> huggingFace "Enriches model metadata (details, README, collections)" "HTTPS/443, TLS 1.2+, Bearer Token"
        modelExtractor -> quayRegistry "Fetches OCI architecture metadata" "HTTPS/443, TLS 1.2+, Registry Auth"
        modelExtractor -> dataContainer "Generates catalog YAML files packaged into container" "File I/O → Docker COPY"
        metadataReport -> dataContainer "Analyzes catalog data for completeness reports" "File I/O"

        # CI/CD relationships
        konfluxCI -> modelMetadataCollection "Builds and pushes data container image" "Tekton Pipeline"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Reads catalog YAML files via volume mount" "Filesystem (init container / sidecar)"
        endUser -> rhoaiDashboard "Browses model catalog" "HTTPS/443"
        dataScienceAdmin -> konfluxCI "Triggers catalog regeneration" "CI/CD Pipeline"
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
