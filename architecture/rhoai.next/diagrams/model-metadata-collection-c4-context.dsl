workspace {
    model {
        maintainer = person "Platform Engineer" "Maintains model catalog data and pipeline configuration"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Build-time data pipeline that extracts, enriches, and catalogs AI model metadata and MCP server metadata into YAML catalogs shipped as a static data container" {
            modelExtractor = container "model-extractor" "Main pipeline: extracts model metadata from OCI registries, enriches with HuggingFace data, generates YAML catalogs" "Go 1.24 CLI Tool"
            metadataReport = container "metadata-report" "Generates metadata completeness reports analyzing data source coverage" "Go 1.24 CLI Tool"
            dataContainer = container "odh-model-metadata-collection" "Static data container shipping pre-generated YAML catalog files at /app/data/ for volume mounting" "ubi9-minimal Container" "Data Container"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hosting platform providing model metadata, collections, and README content" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "Container registries (registry.redhat.io) hosting modelcar images with embedded metadata" "External"
        quay = softwareSystem "Quay.io" "Container image registry for published artifacts" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI Dashboard that displays model catalogs to users" "Internal RHOAI"
        konflux = softwareSystem "Konflux CI/CD" "Tekton-based build pipeline for container image creation and publishing" "Internal Platform"
        githubCI = softwareSystem "GitHub Actions CI" "Continuous integration for linting, testing, and image building" "External"

        # Build-time relationships
        maintainer -> modelMetadataCollection "Configures model indexes, triggers pipeline runs"
        modelExtractor -> huggingface "Fetches model collections, details, READMEs" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> ociRegistry "Fetches container manifests, layer blobs, modelcards" "HTTPS/443, Public (no auth)"
        modelExtractor -> metadataReport "Provides enrichment data for completeness reporting" "File I/O"

        # Build pipeline relationships
        konflux -> modelMetadataCollection "Builds and publishes data container image" "Tekton Pipeline"
        githubCI -> modelMetadataCollection "Runs lint, tests; builds and pushes image on main" "GitHub Actions"
        modelMetadataCollection -> quay "Publishes odh-model-metadata-collection image" "HTTPS/443, Registry credentials"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Reads /app/data/*.yaml catalog files" "Volume Mount (File I/O)"
    }

    views {
        systemContext modelMetadataCollection "SystemContext" {
            include *
            autoLayout
            description "System context showing model-metadata-collection in the RHOAI ecosystem"
        }

        container modelMetadataCollection "Containers" {
            include *
            autoLayout
            description "Internal components: build-time CLI tools and shipped data container"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Data Container" {
                background #9b59b6
                color #ffffff
                shape RoundedBox
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
