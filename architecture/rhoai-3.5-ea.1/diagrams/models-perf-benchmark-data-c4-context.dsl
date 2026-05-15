workspace {
    model {
        dataEngineer = person "Data Engineer" "Runs kafka-processor to prepare benchmark data" "Internal"
        mlEngineer = person "ML Engineer / Data Scientist" "Browses Model Catalog to discover validated models"

        modelsPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Packages and delivers Red Hat-validated AI model performance benchmark data" {
            dataContainer = container "odh-model-performance-data" "Minimal data-only init container that seeds benchmark data into model-catalog pod" "UBI9-minimal Container"
            kafkaProcessor = container "kafka-processor" "Offline CLI tool that consumes CDC messages from Kafka and produces structured benchmark data files" "Python 3.12 CLI"
        }

        kafkaCluster = softwareSystem "Internal Kafka Cluster" "CDC message source for model benchmark data" "External"
        modelCatalog = softwareSystem "Model Catalog" "Model Registry component that serves model metadata and benchmarks to users" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "model-registry-operator" "Operator that manages model-catalog Deployment including init container image references" "Internal RHOAI"
        konflux = softwareSystem "Konflux Build System" "Builds and publishes container images" "External"
        imageRegistry = softwareSystem "Image Registry" "Stores container images for deployment" "External"

        # Offline data preparation
        dataEngineer -> kafkaProcessor "Runs to prepare data"
        kafkaProcessor -> kafkaCluster "Consumes CDC messages" "Kafka/9092,9096 SASL_SSL SCRAM-SHA-512"

        # Build pipeline
        kafkaProcessor -> konflux "Produces data/ directory for image build"
        konflux -> imageRegistry "Pushes odh-model-performance-data-rhel9 image" "HTTPS/443"

        # Runtime data injection
        modelRegistryOperator -> modelCatalog "Manages Deployment spec with init container reference"
        dataContainer -> modelCatalog "Seeds benchmark data via shared volume mount"

        # End user
        mlEngineer -> modelCatalog "Browses validated model benchmarks"
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
