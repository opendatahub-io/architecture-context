workspace {
    model {
        dataScienceAdmin = person "Data Science Admin" "Manages AI model catalog and platform configuration"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Aggregates, enriches, and catalogs AI model and MCP server metadata from registries and HuggingFace" {
            modelExtractor = container "model-extractor" "Go CLI that processes model indexes, fetches registry/HuggingFace metadata, enriches model cards, and generates catalog YAML files" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Generates metadata completeness reports from catalog output" "Go CLI (build-time only)"
            dataContainer = container "odh-model-metadata-collection" "Minimal data-only container (UBI9-minimal) that bundles pre-generated catalog YAML files for consumption by platform components" "Data Container"
        }

        huggingface = softwareSystem "HuggingFace API" "Model metadata, README content, collection discovery, validated model lists" "External"
        registryRedHat = softwareSystem "registry.redhat.io" "OCI container registry for Red Hat model images" "External"
        registryAccess = softwareSystem "registry.access.redhat.com" "OCI container registry for MCP server images" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI that renders model catalog for users" "Internal RHOAI"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that orchestrates component deployment" "Internal RHOAI"
        konflux = softwareSystem "Konflux" "RHOAI CI/CD pipeline with hermetic builds" "Internal Build"
        githubActions = softwareSystem "GitHub Actions" "ODH upstream CI/CD pipeline" "Internal Build"
        quay = softwareSystem "Quay.io" "Container image registry for built images" "External"

        modelExtractor -> huggingface "Fetches model details, README, collections" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> registryRedHat "Fetches OCI image manifests, architectures, timestamps" "HTTPS/443, Registry API v2"
        modelExtractor -> registryAccess "Fetches MCP server container image metadata" "HTTPS/443, Registry API v2"
        modelExtractor -> dataContainer "Generates catalog YAML files" "File I/O (build-time)"
        metadataReport -> dataContainer "Analyzes catalog completeness" "File I/O"
        rhoaiDashboard -> dataContainer "Reads catalog YAML files" "Volume mount (/app/data)"
        rhodsOperator -> dataContainer "Deploys and manages lifecycle" "Kubernetes API"
        konflux -> quay "Pushes container image (RHOAI)" "HTTPS/443, Quay credentials"
        githubActions -> quay "Pushes container image (ODH)" "HTTPS/443, Quay credentials"
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
            element "Internal Build" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
                shape Person
            }
        }
    }
}
