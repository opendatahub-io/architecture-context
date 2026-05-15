workspace {
    model {
        dataEngineer = person "Data Engineer" "Runs Kafka processor to prepare benchmark data"
        datascientist = person "Data Scientist" "Views model benchmark data via model catalog"

        modelsPerfBenchmarkData = softwareSystem "models-perf-benchmark-data" "Packages pre-built benchmark performance data for RHOAI validated models" {
            kafkaProcessor = container "Kafka Processor" "Consumes model benchmark data from Kafka, transforms and writes structured output files" "Python 3.12 CLI" "Build-Time"
            dataImage = container "Data Container Image" "Packages static benchmark data into a volume-mountable init container image" "UBI9-minimal Container" "Runtime"
        }

        kafka = softwareSystem "Kafka Broker" "Message broker providing model benchmark data via CDC topics" "External"
        modelCatalog = softwareSystem "Model Catalog" "Serves model catalog data including benchmark information to users" "Internal RHOAI"
        modelRegistryOperator = softwareSystem "Model Registry Operator" "Manages model-catalog deployment and injects init container references" "Internal RHOAI"
        konflux = softwareSystem "Konflux Build System" "Builds and publishes container images" "External"
        imageRegistry = softwareSystem "Image Registry" "Stores built container images" "External"

        # Build-time relationships
        dataEngineer -> kafkaProcessor "Runs to process benchmark data"
        kafkaProcessor -> kafka "Consumes benchmark messages" "Kafka/9096 SASL_SSL SCRAM-SHA-512"
        kafkaProcessor -> kafkaProcessor "Writes data/ directory" "File I/O"
        konflux -> dataImage "Builds image from data/ directory" "Dockerfile.konflux"
        konflux -> imageRegistry "Pushes built image" "HTTPS/443"

        # Runtime relationships
        modelRegistryOperator -> dataImage "References as init container in model-catalog Deployment" "Image Pull"
        dataImage -> modelCatalog "Provides benchmark data via shared volume mount" "Volume Mount /app/benchmarks"
        datascientist -> modelCatalog "Views benchmark data"
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
            element "Build-Time" {
                background #4a90e2
                color #ffffff
            }
            element "Runtime" {
                background #50c878
                color #ffffff
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
