workspace {
    model {
        developer = person "Platform Engineer" "Configures model/MCP/agent indexes and runs the extraction pipeline"
        datascientist = person "Data Scientist" "Browses available AI models, MCP servers, and agents via RHOAI Dashboard"

        modelMetadata = softwareSystem "model-metadata-collection" "CLI tool and data container that collects, enriches, and catalogs AI model metadata, MCP server metadata, and agent metadata" {
            extractor = container "model-extractor" "Primary pipeline: extracts modelcard metadata from OCI registries, enriches with HuggingFace data, generates catalogs" "Go CLI"
            reporter = container "metadata-report" "Generates metadata completeness reports from catalog output" "Go CLI"
            dataContainer = container "odh-model-metadata-collection" "Serves pre-generated YAML catalogs as a volume mount for platform consumers" "UBI9-minimal Data Container"
        }

        registryRedHat = softwareSystem "registry.redhat.io" "Red Hat OCI container registry hosting modelcar images" "External"
        quay = softwareSystem "quay.io" "Quay OCI container registry for image architectures and publishing" "External"
        huggingface = softwareSystem "HuggingFace" "AI model hub providing model metadata, collections, and README content" "External"
        github = softwareSystem "GitHub" "Source code hosting for agent metadata and README content" "External"
        modelcars = softwareSystem "Red Hat AI Modelcars" "OCI images with annotated modelcard layers" "External"

        dashboard = softwareSystem "RHOAI Dashboard" "Red Hat OpenShift AI user interface" "Internal RHOAI"
        konflux = softwareSystem "Konflux CI/CD" "Build pipeline for multi-arch container images" "Internal Platform"

        developer -> modelMetadata "Configures indexes and triggers pipeline"
        datascientist -> dashboard "Browses model catalog"

        extractor -> registryRedHat "Fetches OCI manifests and modelcard layers" "HTTPS/443"
        extractor -> quay "Fetches image architectures and timestamps" "HTTPS/443"
        extractor -> huggingface "Fetches model details, collections, READMEs" "HTTPS/443"
        extractor -> github "Fetches agent.yaml and README content" "HTTPS/443"
        extractor -> modelcars "Extracts modelcard content from annotated layers" "HTTPS/443"
        extractor -> dataContainer "Generates catalog YAML files" "File I/O"

        reporter -> dataContainer "Reads catalog data for reporting" "File I/O"

        konflux -> dataContainer "Builds multi-arch container image" "Tekton PipelineRun"
        dashboard -> dataContainer "Consumes catalog YAML via volume mount" "Filesystem"
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
            element "Internal Platform" {
                background #f5a623
                color #ffffff
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
