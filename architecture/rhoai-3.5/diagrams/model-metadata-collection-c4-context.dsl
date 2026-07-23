workspace {
    model {
        dataScienceEngineer = person "Data Science Engineer" "Configures model catalogs and MCP server entries"
        ciPipeline = person "CI/CD Pipeline" "Triggers catalog generation on schedule or commit"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Go CLI that extracts, enriches, and catalogs metadata from AI container images; produces YAML catalogs packaged in a data container" {
            modelExtractor = container "model-extractor" "Main pipeline: discovers models from HuggingFace, extracts OCI model cards, enriches metadata, generates YAML catalogs" "Go CLI"
            metadataReport = container "metadata-report" "Analyzes catalog completeness and tracks data source provenance per metadata field" "Go CLI"
            dataContainer = container "Data Container" "Minimal ubi9-minimal image packaging pre-generated YAML catalogs and benchmark data; runs sleep infinity" "Container Image (ubi9-minimal)"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hosting platform with collections, model details, and README content" "External"
        githubApi = softwareSystem "GitHub" "Source code hosting; provides agent.yaml and README files for agentic starter kits" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "registry.redhat.io; hosts AI model container images with OCI manifests and model card layers" "External"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing AI/ML workloads; consumes model and MCP catalogs" "Internal RHOAI"
        modelRegistry = softwareSystem "Model Registry" "Stores model metadata in MetadataStringValue format; consumes catalog data" "Internal RHOAI"

        # Build-time relationships
        ciPipeline -> modelMetadataCollection "Triggers catalog generation" "CI/CD workflow"
        dataScienceEngineer -> modelMetadataCollection "Maintains input catalog YAML and MCP server definitions"

        modelExtractor -> huggingface "Fetches model collections, details, README content" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> githubApi "Validates branches, fetches agent.yaml and README files" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> ociRegistry "Fetches image manifests, config blobs, model card layers" "HTTPS/443, Docker credentials"
        modelExtractor -> dataContainer "Generates YAML catalogs packaged into image" "File copy (Dockerfile)"
        metadataReport -> dataContainer "Analyzes catalog completeness" "File I/O"

        # Runtime relationships (data container consumed by platform)
        dataContainer -> dashboard "Provides model catalogs, MCP server catalogs, agent catalogs" "Volume mount (file-based)"
        dataContainer -> modelRegistry "Provides catalog metadata in CatalogMetadata schema" "Volume mount (file-based)"
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
