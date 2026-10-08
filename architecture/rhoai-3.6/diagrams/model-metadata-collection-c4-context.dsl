workspace {
    model {
        dataScienceAdmin = person "Data Science Admin" "Manages RHOAI platform, browses model catalogs via dashboard"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Build-time pipeline that extracts AI model metadata from OCI images, HuggingFace, and GitHub, producing structured YAML catalogs packaged in a data-only container" {
            modelExtractor = container "model-extractor" "Main pipeline CLI — discovers collections, extracts OCI metadata, enriches with HuggingFace/vLLM data, generates catalogs" "Go CLI"
            metadataReport = container "metadata-report" "Generates completeness and quality reports from catalog output" "Go CLI"
            servingRuntimeCatalog = container "serving-runtime-catalog" "Generates normalized serving runtime catalog from reviewed KServe ServingRuntime input files" "Go CLI"
            dataContainer = container "Data Container" "UBI9-minimal-pqc data-only container shipping pre-generated YAML catalog files at /app/data/ for volume-mount consumption" "Docker Container"
        }

        huggingface = softwareSystem "HuggingFace" "AI model hub — collections API and model READMEs" "External"
        githubAPI = softwareSystem "GitHub" "Source code hosting — agent metadata and READMEs" "External"
        ociRegistries = softwareSystem "OCI Container Registries" "registry.redhat.io, quay.io — ModelCar container images with modelcard layers" "External"
        konflux = softwareSystem "Konflux" "CI/CD build system — runs pipeline and builds data container image" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing AI/ML workloads — consumes catalog data for model/MCP/agent display" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Kubernetes controller that provisions ServingRuntime resources from catalog definitions" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Serverless ML inference platform — ServingRuntime API referenced in catalog data" "Internal RHOAI"

        # Build-time relationships
        modelExtractor -> huggingface "Discovers model collections and fetches READMEs" "HTTPS/443, Bearer token (optional)"
        modelExtractor -> githubAPI "Fetches agent metadata and READMEs" "HTTPS/443, Bearer token (optional)"
        modelExtractor -> ociRegistries "Fetches OCI manifests and modelcard layers" "HTTPS/443, Docker config auth"
        modelExtractor -> dataContainer "Generated catalogs copied into image" "Filesystem (build step)"
        servingRuntimeCatalog -> dataContainer "Generated serving runtime catalog copied into image" "Filesystem (build step)"
        konflux -> modelMetadataCollection "Runs build pipeline and packages data container" "CI/CD"

        # Runtime relationships
        rhoaiDashboard -> dataContainer "Reads catalog YAML files" "Volume mount (filesystem)"
        odhModelController -> dataContainer "Reads serving runtime catalog" "Data reference (filesystem)"
        odhModelController -> kserve "Provisions ServingRuntime CRs from catalog definitions" "Kubernetes API"

        dataScienceAdmin -> rhoaiDashboard "Browses model catalogs, MCP servers, agents" "HTTPS"
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
