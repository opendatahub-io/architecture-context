workspace {
    model {
        developer = person "Developer / CI Pipeline" "Runs model-extractor during CI/CD to produce catalog artifacts"
        platformAdmin = person "Platform Admin" "Deploys and manages RHOAI platform"
        dataScientist = person "Data Scientist" "Browses model catalog via RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Build-time data pipeline that extracts, enriches, and catalogs metadata from AI model container images and MCP servers" {
            modelExtractor = container "model-extractor" "Go CLI — orchestrates metadata extraction, enrichment, and catalog generation" "Go CLI"
            metadataReport = container "metadata-report" "Go CLI — analyzes metadata completeness and data source provenance" "Go CLI"
            dataContainer = container "odh-model-metadata-collection" "Minimal UBI9 container shipping pre-generated YAML catalogs as volume mount source" "Data Container (ubi9-minimal)"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hub — provides model collections, metadata, README files" "External"
        redhatRegistry = softwareSystem "Red Hat Container Registry" "OCI container registry — provides manifests, configs, layer blobs" "External"
        konflux = softwareSystem "Konflux CI/CD" "Tekton-based CI/CD pipeline that builds the container image" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for browsing and deploying AI models" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator — deploys and manages components" "Internal RHOAI"

        # Build-time relationships
        developer -> modelExtractor "Executes during CI/CD build"
        modelExtractor -> huggingface "Fetches model collections, details, README files" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> redhatRegistry "Fetches OCI manifests, layer blobs, image configs" "HTTPS/443, Anonymous"
        modelExtractor -> dataContainer "Produces YAML catalogs COPY'd into image" "Build context"
        developer -> metadataReport "Runs for catalog quality analysis"
        metadataReport -> dataContainer "Reads catalog YAML files" "Filesystem"
        konflux -> dataContainer "Builds container image via Tekton pipeline" "Tekton PipelineRun"

        # Runtime relationships
        rhodsOperator -> dataContainer "Deploys as init container/sidecar" "Kubernetes API"
        dataContainer -> rhoaiDashboard "Provides catalog data via volume mount" "Filesystem (/app/data/*.yaml)"
        dataScientist -> rhoaiDashboard "Browses model catalog" "HTTPS"
        platformAdmin -> rhodsOperator "Manages RHOAI deployment" "CLI / Console"
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
            element "Software System" {
                background #438dd5
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Data Container (ubi9-minimal)" {
                shape cylinder
                background #7ed321
                color #ffffff
            }
        }
    }
}
