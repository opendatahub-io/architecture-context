workspace {
    model {
        dataScienceUser = person "Data Scientist / ML Engineer" "Browses model catalog to find validated models with performance benchmarks"

        modelPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Data container packaging Red Hat AI validated model performance benchmark data (JSON/NDJSON) for the model catalog" {
            dataContainer = container "odh-model-performance-data" "UBI9-minimal init container bundling static benchmark files under /app/benchmarks" "Data Container (UBI9-minimal)"
            kafkaProcessor = container "kafka-processor" "Python CLI tool consuming Kafka CDC messages and transforming them into structured provider/model file hierarchy (development only)" "Python 3.12 CLI"
        }

        modelCatalog = softwareSystem "Model Catalog" "Serves model metadata and performance benchmarks to users via API" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages model-catalog deployment lifecycle, patches init container image references" "Internal RHOAI"
        kafkaBroker = softwareSystem "Kafka Broker" "Hosts CDC topics with model benchmark, evaluation, and validation data" "External"
        konfluxCI = softwareSystem "Konflux CI" "Builds and publishes container images from source" "External"

        # Development flow
        kafkaBroker -> kafkaProcessor "Provides CDC messages" "Kafka SASL_SSL/9092 SCRAM-SHA-512"
        kafkaProcessor -> dataContainer "Populates data/ directory (packaged at build time)" "File I/O"

        # Build flow
        konfluxCI -> dataContainer "Builds container image from Dockerfile.konflux" "Container Build"

        # Production flow
        modelRegistryOperator -> modelCatalog "Manages deployment, patches init container ref" "Kubernetes API"
        dataContainer -> modelCatalog "Provides benchmark data via init container shared volume" "Volume Mount (emptyDir)"

        # User interaction
        dataScienceUser -> modelCatalog "Browses model benchmarks" "HTTPS"
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
