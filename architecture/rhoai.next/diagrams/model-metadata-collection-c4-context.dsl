workspace {
    model {
        dataSteward = person "Data Steward / Release Engineer" "Maintains model catalog definitions and triggers pipeline runs"
        dataScientist = person "Data Scientist" "Browses model catalog in RHOAI Dashboard to discover available models"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Build-time ETL pipeline that extracts, enriches, and catalogs AI model metadata from OCI registries and HuggingFace" {
            modelExtractor = container "model-extractor" "Primary pipeline CLI: discovery, extraction, enrichment, catalog generation" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Generates metadata completeness and provenance reports" "Go CLI (build-time only)"
            dataContainer = container "odh-model-metadata-collection" "Minimal data container shipping pre-generated YAML catalogs via volume mount" "ubi9-minimal Container (sleep infinity)"
        }

        huggingFace = softwareSystem "HuggingFace" "AI model hosting platform with collections, model cards, and metadata APIs" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "registry.redhat.io - hosts modelcar container images with model cards" "External"
        ociRegistryMCP = softwareSystem "OCI Registries (MCP)" "Various registries hosting MCP server container images" "External"
        quay = softwareSystem "Quay.io" "Container image registry for built images" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI Dashboard - model catalog UI" "Internal RHOAI"
        konflux = softwareSystem "Konflux / Tekton" "CI/CD pipeline platform for building and pushing container images" "Internal Platform"
        githubActions = softwareSystem "GitHub Actions" "CI/CD for upstream builds and testing" "External"

        # Build-time relationships
        dataSteward -> modelMetadataCollection "Updates models-index.yaml and triggers builds"
        modelExtractor -> huggingFace "Fetches collections, model details, READMEs" "HTTPS/443 TLS 1.2+ Bearer Token (optional)"
        modelExtractor -> ociRegistry "Pulls manifests, config blobs, model card layers" "HTTPS/443 TLS 1.2+ OCI Distribution v2"
        modelExtractor -> ociRegistryMCP "Inspects MCP server images for architecture data" "HTTPS/443 TLS 1.2+"
        modelExtractor -> dataContainer "Produces YAML catalog files copied into image" "Filesystem (COPY in Dockerfile)"
        metadataReport -> modelExtractor "Reads catalog output for completeness analysis" "Filesystem"

        # CI/CD relationships
        konflux -> dataContainer "Builds and pushes container image" "Tekton PipelineRun"
        githubActions -> dataContainer "Builds and pushes container image (upstream)" "GitHub Actions workflow"
        dataContainer -> quay "Pushed as odh-model-metadata-collection" "HTTPS/443 Registry Push Auth"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Mounts /app/data volume to read catalog YAMLs" "Volume mount (no network)"
        dataScientist -> rhoaiDashboard "Browses model catalog UI"
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
            element "Internal Platform" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
