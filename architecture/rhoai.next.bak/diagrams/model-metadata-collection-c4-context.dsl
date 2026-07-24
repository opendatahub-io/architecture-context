workspace {
    model {
        developer = person "Developer / CI Pipeline" "Runs model-extractor to generate catalog data"
        dashboardUser = person "Data Scientist" "Browses model catalog in RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Offline data pipeline that produces AI model and MCP server catalog YAML files for the RHOAI Dashboard" {
            modelExtractor = container "model-extractor" "Multi-stage enrichment pipeline: OCI registry -> HuggingFace -> vLLM configs -> YAML catalogs" "Go CLI"
            metadataReport = container "metadata-report" "Generates metadata completeness and data source provenance reports" "Go CLI"
            dataContainer = container "odh-model-metadata-collection" "Minimal UBI9 container that serves pre-generated YAML catalog files via volume mount" "Data Container"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hub with collections, model details, README content, YAML frontmatter" "External"
        registryRedHat = softwareSystem "registry.redhat.io" "Red Hat container registry hosting modelcar images with model card layers" "External"
        quayIO = softwareSystem "quay.io" "Container registry hosting MCP server and model images" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI Dashboard that displays model and MCP server catalogs" "Internal RHOAI"
        konfluxCI = softwareSystem "Konflux / Tekton" "CI/CD pipeline that builds and pushes container images for RHOAI downstream" "Internal"
        githubActionsCI = softwareSystem "GitHub Actions" "CI pipeline that builds and pushes container images for ODH upstream" "External"

        # Build-time relationships
        developer -> modelExtractor "Runs during CI/CD"
        modelExtractor -> huggingface "Fetches collections, model details, README" "HTTPS/443"
        modelExtractor -> registryRedHat "Pulls modelcar manifests, extracts model card layers" "HTTPS/443"
        modelExtractor -> quayIO "Pulls MCP server image metadata" "HTTPS/443"
        modelExtractor -> dataContainer "Generated YAML catalogs committed to Git, copied into image"
        developer -> metadataReport "Runs for audit/diagnostics"
        metadataReport -> dataContainer "Reads generated catalog files"

        # Runtime relationships
        dataContainer -> rhoaiDashboard "Provides catalog YAML files" "Volume mount"
        dashboardUser -> rhoaiDashboard "Browses model catalog"

        # CI/CD relationships
        konfluxCI -> dataContainer "Builds and pushes container image" "Tekton Pipeline"
        githubActionsCI -> dataContainer "Builds multi-arch image" "GitHub Actions"
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
