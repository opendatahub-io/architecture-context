workspace {
    model {
        platformEngineer = person "Platform Engineer" "Maintains RHOAI platform, runs CI/CD pipelines"
        dataScientist = person "Data Scientist" "Browses model catalog via RHOAI Dashboard"

        modelMetadata = softwareSystem "Model Metadata Collection" "Aggregates, enriches, and catalogs AI model and MCP server metadata from container registries and HuggingFace APIs" {
            modelExtractor = container "model-extractor" "Go CLI pipeline that processes model indexes, fetches metadata from registries/HuggingFace, and generates catalog YAML files" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Generates metadata completeness reports from catalog output" "Go CLI (build-time only)"
            dataContainer = container "odh-model-metadata-collection" "Minimal data-only container (UBI9-minimal) that bundles pre-generated catalog YAML files; runs sleep infinity" "Data Container"
        }

        huggingFace = softwareSystem "HuggingFace API" "AI model hosting and metadata API" "External"
        rhRegistry = softwareSystem "registry.redhat.io" "Red Hat OCI container registry for model images" "External"
        accessRegistry = softwareSystem "registry.access.redhat.com" "Red Hat OCI container registry for MCP server images" "External"
        quayRegistry = softwareSystem "quay.io" "Container image registry for built images" "External"
        konflux = softwareSystem "Konflux" "RHOAI CI/CD pipeline with hermetic builds" "External"
        githubActions = softwareSystem "GitHub Actions" "ODH upstream CI/CD pipeline" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for Red Hat OpenShift AI platform" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "RHOAI platform operator that manages component lifecycle" "Internal RHOAI"

        # Build-time relationships
        platformEngineer -> konflux "Triggers builds"
        konflux -> modelExtractor "Executes during build pipeline"
        modelExtractor -> huggingFace "Fetches model details, README, collections" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> rhRegistry "Fetches OCI image manifests, architectures" "HTTPS/443, No Auth"
        modelExtractor -> accessRegistry "Fetches MCP server container metadata" "HTTPS/443, No Auth"
        modelExtractor -> dataContainer "Generates catalog YAML files bundled into" "File I/O"
        metadataReport -> dataContainer "Analyzes catalog YAML for completeness" "File I/O"
        konflux -> quayRegistry "Pushes built container image" "HTTPS/443"
        githubActions -> quayRegistry "Pushes upstream container image" "HTTPS/443"

        # Runtime relationships
        rhodsOperator -> dataContainer "Deploys alongside consumers"
        dataContainer -> rhoaiDashboard "Provides catalog YAML files via volume mount" "Shared filesystem"
        dataScientist -> rhoaiDashboard "Browses model catalog"
    }

    views {
        systemContext modelMetadata "SystemContext" {
            include *
            autoLayout
        }

        container modelMetadata "Containers" {
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
