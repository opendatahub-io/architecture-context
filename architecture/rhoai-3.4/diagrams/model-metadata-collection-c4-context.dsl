workspace {
    model {
        platformEngineer = person "Platform Engineer" "Maintains RHOAI platform and CI/CD pipelines"
        dataScientist = person "Data Scientist" "Browses AI model catalog via RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Build-time pipeline that generates YAML catalogs of AI model and MCP server metadata, packaged into a data-only container image" {
            modelExtractor = container "model-extractor" "Primary CLI pipeline: discovers HuggingFace collections, extracts OCI modelcards, enriches metadata, generates YAML catalogs for models and MCP servers" "Go CLI"
            metadataReport = container "metadata-report" "Reporting utility: analyzes metadata completeness and data source provenance" "Go CLI"
            dataContainer = container "odh-model-metadata-collection" "Minimal ubi9-micro image containing pre-generated YAML catalog files; runs sleep infinity as a data volume source" "Data Container (ubi9-micro)"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hub for discovering model collections, fetching metadata and README files" "External"
        redhatRegistry = softwareSystem "Red Hat Container Registry" "OCI container registry (registry.redhat.io) for fetching model container images and extracting modelcards" "External"
        konflux = softwareSystem "Konflux CI/CD" "Build pipeline that compiles and packages the data container image" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI that displays model and MCP server information to data scientists" "Internal RHOAI"

        # Relationships - system level
        platformEngineer -> modelMetadataCollection "Triggers catalog generation pipeline"
        dataScientist -> rhoaiDashboard "Browses model catalog"
        modelMetadataCollection -> huggingface "Fetches model collections, metadata, README files" "HTTPS/443"
        modelMetadataCollection -> redhatRegistry "Fetches OCI manifests, container layers for modelcard extraction" "HTTPS/443"
        konflux -> modelMetadataCollection "Builds data container image from catalog files"
        rhoaiDashboard -> modelMetadataCollection "Reads YAML catalog files via volume mount" "File I/O"

        # Relationships - container level
        platformEngineer -> modelExtractor "Runs in CI pipeline or locally"
        modelExtractor -> huggingface "Fetches model collections, metadata, README files" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> redhatRegistry "Fetches OCI manifests, container layers" "HTTPS/443, No auth"
        modelExtractor -> dataContainer "Generated YAML files packaged into image" "Konflux Dockerfile"
        metadataReport -> modelExtractor "Analyzes output from extractor" "File I/O"
        rhoaiDashboard -> dataContainer "Reads catalog YAML files" "Volume mount / File I/O"
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
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Data Container (ubi9-micro)" {
                background #85bb65
                color #ffffff
            }
        }
    }
}
