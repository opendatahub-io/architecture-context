workspace {
    model {
        dataEngineer = person "Data Engineer" "Runs data ingestion tools to populate benchmark data"
        developer = person "Developer" "Commits updated data/ directory to repository"
        endUser = person "End User" "Views model performance data in RHOAI Dashboard"

        modelsPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Data-only init container providing static benchmark data for model catalog" {
            dataContainer = container "Data Container Image" "UBI9-minimal init container with JSON/NDJSON benchmark files at /app/benchmarks" "Container (Init Container)"
            kafkaProcessor = container "kafka-processor" "Consumes model benchmark data from Kafka topics and writes JSON/NDJSON files" "Python 3.12 CLI" "Dev Tool"
            apiClient = container "api-client" "Fetches model benchmark data from REST API and writes JSON/NDJSON files" "Python 3.12 CLI" "Dev Tool"
            coldStartVramData = container "cold-start-vram-data" "Enriches model metadata with cold-start time, VRAM, and modelcar size data" "Python Script" "Dev Tool"
            dataDirectory = container "data/ directory" "Git-tracked JSON/NDJSON files organized by provider/model" "Filesystem"
        }

        modelCatalog = softwareSystem "model-catalog" "Service that displays model performance data in the RHOAI dashboard" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "model-registry-operator" "Manages model-catalog Deployment spec including init container reference" "Internal RHOAI"
        kafkaBroker = softwareSystem "Kafka Broker" "Message broker hosting dev.aihub-public-* topics with model benchmark data" "External"
        modelValidationHub = softwareSystem "model-validation-hub" "REST API providing model benchmark, evaluation, and validation data" "External"
        konflux = softwareSystem "Konflux" "Build system that creates container images from Dockerfile.konflux" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores and serves container images (quay.io / registry.redhat.io)" "External"

        # Dev tool flows
        dataEngineer -> kafkaProcessor "Runs data ingestion"
        dataEngineer -> apiClient "Runs data ingestion (alternative)"
        kafkaProcessor -> kafkaBroker "Consumes CDC messages" "Kafka/9096 SASL_SSL SCRAM-SHA-512"
        apiClient -> modelValidationHub "Fetches benchmark data" "HTTPS/443 TLS"
        kafkaProcessor -> dataDirectory "Writes JSON/NDJSON files"
        apiClient -> dataDirectory "Writes JSON/NDJSON files"
        coldStartVramData -> dataDirectory "Enriches metadata.json files"

        # Build flow
        developer -> dataDirectory "Commits updated data/ to git"
        dataDirectory -> konflux "Build triggered"
        konflux -> dataContainer "Builds image (COPY data/ to /app/benchmarks)"
        konflux -> containerRegistry "Pushes container image" "HTTPS/443"

        # Runtime flow
        containerRegistry -> dataContainer "Image pull" "HTTPS/443"
        dataContainer -> modelCatalog "Provides benchmark data via shared emptyDir volume" "Filesystem"
        modelRegistryOperator -> modelCatalog "Manages Deployment spec" "Kubernetes API"
        endUser -> modelCatalog "Views model performance data"
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
                background #4a90e2
                color #ffffff
            }
            element "Dev Tool" {
                background #7ed321
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
