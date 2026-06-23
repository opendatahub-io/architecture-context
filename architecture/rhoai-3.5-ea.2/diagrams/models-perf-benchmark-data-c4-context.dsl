workspace {
    model {
        developer = person "Developer / CI" "Runs data ingestion tools to populate benchmark data"
        datascientist = person "Data Scientist" "Consumes model benchmark data through model-catalog UI"

        modelsPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Data container packaging pre-built model performance benchmark data for model-catalog consumption" {
            dataContainer = container "odh-model-performance-data" "UBI 9 minimal init container that copies benchmark data files to a shared volume" "Docker Container (data-only)"
            apiClient = container "api-client" "Fetches benchmark data from model-validation REST API and writes JSON/NDJSON files" "Python 3.12 CLI"
            kafkaProcessor = container "kafka-processor" "Consumes CDC events from Kafka topics and writes JSON/NDJSON files" "Python 3.12 CLI"
            coldStartEnrichment = container "cold-start-vram-data" "Enriches model metadata with cold-start times and VRAM requirements" "Python Script"
        }

        modelCatalog = softwareSystem "Model Catalog" "Serves model benchmark data to users via model-catalog API" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages model-catalog Deployment that references the init container" "Internal RHOAI"
        modelValidationAPI = softwareSystem "Model Validation API" "REST API providing model benchmark data (providers, models, evaluations, performances, validations, variant-groups)" "Internal"
        kafkaBroker = softwareSystem "Kafka / Redpanda" "Message broker providing CDC events for model benchmark data" "External"
        containerRegistry = softwareSystem "Container Registry" "Stores built container images" "External"
        openshiftRegistry = softwareSystem "OpenShift Image Registry" "Internal registry serving container images to pods" "External"
        konflux = softwareSystem "Konflux" "Build system for container images" "External"

        # Developer/CI flows
        developer -> apiClient "Runs data ingestion"
        developer -> kafkaProcessor "Runs Kafka ingestion"
        apiClient -> modelValidationAPI "GET /api/v1/* (HTTPS, TLS configurable)"
        kafkaProcessor -> kafkaBroker "Consumes CDC events (Kafka/9092, SSL/SASL optional)"
        apiClient -> dataContainer "Writes data files (File I/O)"
        kafkaProcessor -> dataContainer "Writes data files (File I/O)"
        coldStartEnrichment -> dataContainer "Enriches model metadata (File I/O)"

        # Build flow
        konflux -> dataContainer "Builds UBI 9 image with data/ directory"
        konflux -> containerRegistry "Pushes image (HTTPS/443)"

        # Runtime flow
        dataContainer -> modelCatalog "Copies benchmark data via shared emptyDir volume (File I/O)"
        modelRegistryOperator -> modelCatalog "Manages Deployment referencing init container"
        openshiftRegistry -> dataContainer "Serves container image (HTTPS/5000)"

        # User consumption
        datascientist -> modelCatalog "Browses model benchmarks"
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
            element "Internal" {
                background #f5a623
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
                shape RoundedBox
            }
            element "Container" {
                shape RoundedBox
            }
        }
    }
}
