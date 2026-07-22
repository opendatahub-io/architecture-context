workspace {
    model {
        dataScienceUser = person "Data Scientist / Platform Admin" "Uses RHOAI Dashboard to browse model, MCP server, and agent catalogs"

        modelMetadataCollection = softwareSystem "model-metadata-collection" "Batch ETL pipeline that extracts, enriches, and packages model/MCP/agent catalog metadata into a data container image" {
            modelExtractor = container "model-extractor" "Main CLI pipeline: extracts model metadata from OCI registries, enriches from HuggingFace/GitHub, generates catalog YAML" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Generates metadata completeness and data-source provenance reports" "Go CLI (build-time only)"
            dataContainer = container "Data Container Image" "UBI9-minimal container packaging pre-generated catalog YAML at /app/data, runs sleep infinity" "Container (runtime)"
        }

        huggingFace = softwareSystem "HuggingFace" "ML model hosting platform providing model metadata, collections, tags, and README files" "External"
        githubAPI = softwareSystem "GitHub" "Source code hosting platform providing agent starter kit metadata (agent.yaml, README)" "External"
        ociRegistry = softwareSystem "OCI Container Registry" "registry.redhat.io -- hosts modelcar images with model card metadata layers" "External"
        ociRegistryOther = softwareSystem "OCI Registries (other)" "Various registries hosting MCP server container images" "External"

        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI web dashboard displaying model and tool catalogs" "Internal RHOAI"

        konfluxCI = softwareSystem "Konflux CI/CD" "Build pipeline that packages data files into multi-arch container image" "Internal"
        githubActionsCI = softwareSystem "GitHub Actions CI" "Runs model-extractor pipeline and commits generated catalog files" "External"

        # Build-time relationships
        modelExtractor -> huggingFace "Fetches model collections, details, tags, READMEs" "HTTPS/443, Bearer HF_TOKEN (optional)"
        modelExtractor -> githubAPI "Fetches agent.yaml and README.md from starter kits" "HTTPS/443, Bearer GITHUB_TOKEN (optional)"
        modelExtractor -> ociRegistry "Pulls modelcar manifests, layers, config blobs" "HTTPS/443 Docker Registry v2"
        modelExtractor -> ociRegistryOther "Inspects MCP server images for architectures" "HTTPS/443 Docker Registry v2"

        # Report
        metadataReport -> modelExtractor "Reads generated catalog and enrichment YAML" "File I/O"

        # CI/CD
        githubActionsCI -> modelExtractor "Triggers make process and commits outputs" "CI workflow"
        konfluxCI -> dataContainer "Builds multi-arch image from Dockerfile.konflux" "Tekton Pipeline"

        # Runtime consumption
        rhoaiDashboard -> dataContainer "Mounts /app/data volume to read catalog YAML files" "Volume Mount"
        dataScienceUser -> rhoaiDashboard "Browses model, MCP server, and agent catalogs" "HTTPS"
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
                background #438DD5
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
            element "Internal" {
                background #85bbf0
                color #ffffff
            }
            element "Container" {
                background #438DD5
                color #ffffff
            }
            element "Person" {
                background #08427B
                color #ffffff
                shape person
            }
        }
    }
}
