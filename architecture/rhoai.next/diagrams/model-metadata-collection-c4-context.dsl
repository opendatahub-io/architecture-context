workspace {
    model {
        developer = person "Developer / CI Pipeline" "Runs model-extractor CLI during build to generate catalog data"
        dashboardUser = person "Data Scientist" "Views model catalog in RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Extracts, enriches, and catalogs metadata for Red Hat AI models and MCP servers" {
            modelExtractor = container "model-extractor" "Primary pipeline binary that extracts model metadata from OCI registries, enriches with HuggingFace data, generates catalog YAML files" "Go 1.24 CLI"
            metadataReport = container "metadata-report" "Generates metadata completeness reports from catalog output" "Go 1.24 CLI"
            dataContainer = container "odh-model-metadata-collection" "Static data container holding pre-generated catalog YAML files for volume mounting" "ubi9-minimal Container" "Data Container"
        }

        huggingFace = softwareSystem "HuggingFace" "Model hosting platform providing metadata, collections, and README frontmatter" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "registry.redhat.io - Stores OCI container images with model artifacts and modelcards" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI Dashboard that displays model catalog to users" "Internal RHOAI"
        konflux = softwareSystem "Konflux Build System" "Tekton-based CI/CD pipeline that builds container images" "Internal"
        githubActions = softwareSystem "GitHub Actions" "CI workflow for lint, test, and image push to quay.io" "External"

        # Build-time relationships
        developer -> modelExtractor "Invokes during CI/CD build"
        modelExtractor -> huggingFace "Fetches model collections, details, README frontmatter" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> ociRegistry "Fetches container manifests, layer blobs, config blobs" "HTTPS/443, OCI Distribution v2"
        modelExtractor -> dataContainer "Generated YAML files copied into container via Dockerfile" "File Copy"
        metadataReport -> modelExtractor "Reads extraction output to generate completeness reports" "File I/O"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Mounts /app/data/ volume to read model catalogs" "Volume Mount"
        dashboardUser -> rhoaiDashboard "Views model catalog, selects models for deployment"

        # CI/CD relationships
        konflux -> dataContainer "Builds container image via Tekton PipelineRun" "Tekton Pipeline"
        githubActions -> modelExtractor "Runs lint, test, build workflows" "GitHub Workflow"
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
            }
            element "Internal" {
                background #7ed321
            }
            element "Data Container" {
                background #e1d5e7
                shape Cylinder
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
