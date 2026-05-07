workspace {
    model {
        dataEngineer = person "Data Engineer / CI Operator" "Triggers CI/CD pipeline to rebuild model catalogs"
        dataScientist = person "Data Scientist" "Browses model catalog in RHOAI Dashboard"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Build-time pipeline that collects, enriches, and packages AI model metadata and MCP server catalogs into a static data container image" {
            modelExtractor = container "model-extractor" "CLI tool that discovers models, extracts metadata from OCI registries, enriches with HuggingFace data, generates catalog YAML" "Go 1.24 CLI"
            metadataReport = container "metadata-report" "CLI tool that audits metadata quality and generates completeness reports" "Go 1.24 CLI"
            dataContainer = container "Data Container" "Minimal container (ubi9-minimal) serving pre-generated YAML catalog files via volume mount. Runs sleep infinity." "Container Image"
        }

        huggingFace = softwareSystem "HuggingFace" "AI model hosting platform with collections, model details, and metadata APIs" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "registry.redhat.io - hosts modelcar container images with embedded model metadata" "External"
        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for Red Hat OpenShift AI platform, displays model and MCP server catalogs" "Internal RHOAI"
        konflux = softwareSystem "Konflux CI/CD" "Tekton-based build pipeline for multi-arch container images" "Internal Platform"
        kubernetesAPI = softwareSystem "Kubernetes API" "Cluster API server for pod lifecycle management" "Infrastructure"

        # Build-time relationships
        dataEngineer -> konflux "Triggers pipeline rebuild"
        konflux -> modelMetadataCollection "Builds multi-arch container image"
        modelExtractor -> huggingFace "Discovers model collections, fetches details and READMEs" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> ociRegistry "Pulls modelcar manifests, extracts modelcard layers" "HTTPS/443, OCI Distribution v2"
        modelExtractor -> metadataReport "Catalog output feeds report generation"

        # Runtime relationships
        dataScientist -> dashboard "Browses model catalog"
        dashboard -> dataContainer "Mounts /app/data/ volume to read catalog YAML" "Filesystem (volume mount)"
        kubernetesAPI -> dataContainer "Schedules and manages pod lifecycle" "HTTPS/443"
    }

    views {
        systemContext modelMetadataCollection "SystemContext" {
            include *
            autoLayout
            description "System context for Model Metadata Collection showing build-time and runtime interactions"
        }

        container modelMetadataCollection "Containers" {
            include *
            autoLayout
            description "Container view showing build-time CLI tools and the shipped data container"
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
            element "Internal Platform" {
                background #f5a623
                color #ffffff
            }
            element "Infrastructure" {
                background #e8e8e8
                color #333333
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
