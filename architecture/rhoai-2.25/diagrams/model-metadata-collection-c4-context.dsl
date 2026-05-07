workspace {
    model {
        dataSteward = person "Data Steward / Release Engineer" "Maintains the models-index.yaml and triggers metadata collection pipeline"

        modelMetadataCollection = softwareSystem "Model Metadata Collection" "Build-time data pipeline that extracts, enriches, and catalogs AI/ML model metadata from OCI registries and HuggingFace, packaging results into a data-only container image" {
            modelExtractor = container "model-extractor" "Main CLI pipeline: reads models-index.yaml, pulls OCI images, extracts model cards, enriches via HuggingFace, generates unified catalog" "Go 1.24 CLI"
            metadataReport = container "metadata-report" "Generates metadata completeness reports in Markdown and YAML formats" "Go 1.24 CLI"
            dataContainer = container "odh-model-metadata-collection-rhel9" "Data-only container (ubi9-micro base, CMD sleep infinity) packaging pre-generated catalog YAML files" "Data Container"
        }

        registryRedHat = softwareSystem "registry.redhat.io" "Red Hat container registry hosting modelcar OCI images with embedded model cards" "External"
        huggingFace = softwareSystem "HuggingFace" "ML model hub providing model metadata, collections, and README files via REST API" "External"
        konflux = softwareSystem "Konflux CI/CD" "Tekton-based CI/CD pipeline that builds and publishes container images (hermetic builds)" "External"
        quay = softwareSystem "Quay.io" "Container image registry for RHOAI component images" "External"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "Web UI for managing and displaying validated AI/ML models" "Internal RHOAI"

        dataSteward -> modelMetadataCollection "Updates models-index.yaml and triggers pipeline"
        modelExtractor -> registryRedHat "Pulls OCI images to extract model card metadata" "HTTPS/443 OCI v2, TLS 1.2+, Registry credentials"
        modelExtractor -> huggingFace "Fetches model details, collections, READMEs" "HTTPS/443 REST, TLS 1.2+, Public (no auth)"
        modelExtractor -> metadataReport "Provides catalog and enrichment data"
        konflux -> modelMetadataCollection "Builds data container image from catalog artifacts" "Tekton Pipeline"
        modelMetadataCollection -> quay "Publishes multi-arch data container image" "HTTPS/443 OCI, TLS 1.2+"
        rhoaiDashboard -> dataContainer "Reads models-catalog.yaml via volume mount" "File I/O (no network)"
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
