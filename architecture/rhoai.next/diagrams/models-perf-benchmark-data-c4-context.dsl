workspace {
    model {
        ciEngineer = person "CI/Build Engineer" "Runs data ingestion and triggers container builds"
        dataSciUser = person "Data Scientist / Platform User" "Consumes model benchmark data via RHOAI Dashboard"

        modelPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Data-only container packaging model performance benchmark data for the RHOAI model catalog" {
            initContainer = container "odh-model-performance-data" "Data-only init container (UBI9-minimal) holding JSON/NDJSON benchmark files at /app/benchmarks" "Container Image"
            kafkaProcessor = container "kafka-processor" "Consumes CDC messages from Kafka topics and writes structured benchmark data files" "Python 3.12 CLI"
            apiClient = container "api-client" "Fetches benchmark data from model-validation-hub REST API and writes structured data files" "Python 3.12 CLI"
            enrichScript = container "enrich_models.py" "Merges cold-start, VRAM, and image-size data into model metadata" "Python Script"
            dataDirectory = container "data/ directory" "Structured benchmark data: provider/model hierarchy with JSON/NDJSON files" "Filesystem"
        }

        kafkaBrokers = softwareSystem "Kafka Brokers" "CDC message broker for model benchmark data (dev.aihub-public-* topics)" "External"
        modelValidationHub = softwareSystem "model-validation-hub" "REST API providing model benchmark data" "External"
        modelCatalog = softwareSystem "model-catalog" "Serves model benchmark data to the RHOAI Dashboard" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "model-registry-operator" "Manages model-catalog deployment and init container references" "Internal RHOAI"
        rhoaiDashboard = softwareSystem "RHOAI Dashboard" "User-facing dashboard for browsing AI model catalog" "Internal RHOAI"

        # Ingestion flows
        kafkaBrokers -> kafkaProcessor "CDC messages" "Kafka/9092 SASL_SSL"
        modelValidationHub -> apiClient "Benchmark data" "HTTPS/443 TLS"
        kafkaProcessor -> dataDirectory "Writes benchmark files" "File I/O"
        apiClient -> dataDirectory "Writes benchmark files" "File I/O"
        enrichScript -> dataDirectory "Merges enrichment data" "File I/O"

        # Build and deploy flow
        dataDirectory -> initContainer "COPY into container image" "Dockerfile.konflux"
        initContainer -> modelCatalog "Provides benchmark data volume" "Init container → shared volume"
        modelRegistryOperator -> modelCatalog "Manages deployment" "Kubernetes API"

        # User-facing
        modelCatalog -> rhoaiDashboard "Serves benchmark data"
        dataSciUser -> rhoaiDashboard "Browses model catalog"

        # CI flow
        ciEngineer -> kafkaProcessor "Triggers ingestion" "CLI"
        ciEngineer -> apiClient "Triggers ingestion" "CLI"
    }

    views {
        systemContext modelPerfBenchmarkData "SystemContext" {
            include *
            autoLayout
        }

        container modelPerfBenchmarkData "Containers" {
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
                shape person
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
        }
    }
}
