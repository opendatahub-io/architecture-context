workspace {
    model {
        dataEngineer = person "Data Engineer" "Runs API client to fetch and update benchmark data"

        modelsPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Data repository containing ML model benchmark results packaged as a container init image for the RHOAI model-catalog deployment" {
            apiClient = container "API Client" "Python CLI that fetches benchmark data from external REST API, serializes, deduplicates, and writes to local data directory" "Python CLI"
            dataDirectory = container "Data Directory" "NDJSON and JSON files organized by model ID with a manifest.json summary" "Filesystem"
            initContainerImage = container "Init Container Image" "Container image packaging the benchmark data for deployment as an init container" "Container Image"
        }

        externalBenchmarkAPI = softwareSystem "External Benchmark REST API" "Upstream source of ML model performance, evaluation, security, and validation data" "External"
        modelRegistryOperator = softwareSystem "model-registry-operator" "Manages model-catalog deployment lifecycle in opendatahub namespace" "Internal RHOAI"
        modelCatalog = softwareSystem "model-catalog" "Deployment in odh-model-registries namespace that serves model catalog data" "Internal RHOAI"
        containerRegistry = softwareSystem "Container Registry" "Stores built container images" "External"

        # Build-time relationships
        dataEngineer -> apiClient "Runs to fetch benchmark data"
        apiClient -> externalBenchmarkAPI "Fetches paginated data from 7 REST endpoints" "HTTPS"
        apiClient -> dataDirectory "Writes serialized, deduplicated, post-processed data" "NDJSON/JSON"
        dataDirectory -> initContainerImage "Packaged into container image" "Container Build"

        # Runtime relationships
        initContainerImage -> containerRegistry "Pushed to registry" "Container Push"
        containerRegistry -> modelCatalog "Pulled as init container image" "Container Pull"
        modelRegistryOperator -> modelCatalog "Manages deployment lifecycle"
    }

    views {
        systemContext modelsPerfBenchmarkData "SystemContext" {
            include *
            autoLayout
        }

        container modelsPerfBenchmarkData "Containers" {
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
