workspace {
    model {
        datascientist = person "Data Scientist" "Uses AI model catalog to discover and deploy models"
        platformeng = person "Platform Engineer" "Manages RHOAI platform components"

        modelMetadata = softwareSystem "Model Metadata Collection" "Aggregates, enriches, and catalogs AI model and MCP server metadata from container registries and HuggingFace APIs" {
            modelExtractor = container "model-extractor" "Go CLI tool that processes model indexes, fetches metadata from registries and HuggingFace, and generates catalog YAML files" "Go CLI (build-time only)"
            metadataReport = container "metadata-report" "Go CLI tool that generates metadata completeness reports from catalog output" "Go CLI (build-time only)"
            dataContainer = container "odh-model-metadata-collection" "Minimal data-only container (UBI9-minimal) that bundles pre-generated catalog YAML files; runs sleep infinity" "Data Container (UBI9-minimal)"
        }

        huggingface = softwareSystem "HuggingFace API" "AI model hosting platform providing model details, README content, and collections" "External"
        registryRedhat = softwareSystem "registry.redhat.io" "Red Hat OCI container registry for model container images" "External"
        registryAccess = softwareSystem "registry.access.redhat.com" "Red Hat OCI container registry for MCP server images" "External"
        quay = softwareSystem "Quay.io" "Container image registry for distribution" "External"

        dashboard = softwareSystem "RHOAI Dashboard" "Web UI for model catalog browsing and management" "Internal ODH"
        rhodsOperator = softwareSystem "rhods-operator" "Platform operator that orchestrates RHOAI component deployment" "Internal ODH"
        konflux = softwareSystem "Konflux" "CI/CD pipeline for hermetic multi-arch container builds" "Internal"
        githubActions = softwareSystem "GitHub Actions" "CI/CD pipeline for upstream ODH builds" "External"

        # Build-time relationships
        modelExtractor -> huggingface "Fetches model details, README, collections" "HTTPS/443, Bearer Token (optional)"
        modelExtractor -> registryRedhat "Fetches OCI image manifests, architectures, timestamps" "HTTPS/443, OCI Registry v2"
        modelExtractor -> registryAccess "Fetches MCP server container image metadata" "HTTPS/443, OCI Registry v2"
        modelExtractor -> dataContainer "Generates catalog YAML files bundled into" "File I/O (build-time)"
        metadataReport -> modelExtractor "Analyzes output from" "File I/O"

        # CI/CD relationships
        konflux -> modelMetadata "Builds hermetic multi-arch container image" "Tekton Pipeline"
        konflux -> quay "Pushes RHOAI container image" "HTTPS/443"
        githubActions -> quay "Pushes ODH upstream container image" "HTTPS/443"

        # Runtime relationships
        dashboard -> dataContainer "Reads catalog YAML files via volume mount" "Shared filesystem (/app/data)"
        rhodsOperator -> dataContainer "Deploys and manages lifecycle" "Kubernetes API"
        datascientist -> dashboard "Browses model catalog" "HTTPS"
        platformeng -> rhodsOperator "Manages platform" "kubectl/oc"
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
            element "Internal ODH" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
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
            element "Person" {
                background #08427b
                color #ffffff
                shape person
            }
        }
    }
}
