workspace {
    model {
        dataEngineer = person "Data Engineer / CI Pipeline" "Runs model-extractor to generate catalog data"
        dashboardUser = person "Data Scientist" "Browses model catalog in RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Build-time data pipeline that extracts, enriches, and catalogs metadata for Red Hat AI models and MCP servers" {
            modelExtractor = container "model-extractor" "Extracts metadata from OCI containers, enriches with HuggingFace data, generates YAML catalogs" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Generates metadata completeness reports from catalog output" "Go CLI (build-time only)"
            dataContainer = container "odh-model-metadata-collection" "Minimal data container holding pre-generated catalog YAML files for volume mounting" "ubi9-minimal Container (sleep infinity)"
        }

        huggingFaceAPI = softwareSystem "HuggingFace API" "Model metadata, collections, README frontmatter" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "registry.redhat.io - Model container images with manifests and layers" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "UI for browsing and deploying AI models" "Internal RHOAI"
        konfluxBuild = softwareSystem "Konflux Build System" "Tekton-based CI/CD pipeline for building container images" "Internal"
        githubActionsCI = softwareSystem "GitHub Actions CI" "Lint, test, and push container images to quay.io" "External"

        # Build-time relationships
        dataEngineer -> modelExtractor "Runs via CI/CD or locally"
        modelExtractor -> huggingFaceAPI "Fetches model collections, details, README YAML frontmatter" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> ociRegistry "Fetches container manifests, layers, config blobs" "HTTPS/443"
        modelExtractor -> dataContainer "Generated YAML files copied into container image" "File copy at build time"
        metadataReport -> modelExtractor "Reads catalog output to generate completeness reports" "File I/O"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Reads model catalog YAML from mounted volume" "Volume Mount"
        dashboardUser -> rhoaiDashboard "Browses model catalog"

        # CI/CD relationships
        konfluxBuild -> dataContainer "Builds container image via Tekton PipelineRun" "Dockerfile.konflux"
        githubActionsCI -> dataContainer "Builds and pushes to quay.io" "Dockerfile"
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
            element "Internal" {
                background #e8e8e8
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
