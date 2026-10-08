workspace {
    model {
        llmdScheduler = person "llm-d Scheduler" "Consumes TTFT/TPOT latency predictions for scheduling decisions"
        traceProducer = person "Trace Producer" "Produces request traces for model training"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "Online ML prediction and training for TTFT/TPOT latency estimation" {
            predictionServer = container "prediction-server" "Loads local models and serves single/bulk latency predictions" "Python FastAPI / Uvicorn" "8 workers, 10 replicas"
            trainingServer = container "training-server" "Accepts traces, retrains regression models, persists and serves artifacts" "Python FastAPI / Uvicorn" "1 replica"
            commonLib = container "common" "Shared model and request type definitions" "Python library"
            predictionService = container "prediction-service" "Routes external traffic to prediction pods" "Kubernetes ClusterIP" "80→8001"
            trainingService = container "training-service" "Routes traffic to the training pod" "Kubernetes ClusterIP" "8000→8000"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"
        aipcc = softwareSystem "AIPCC Base Image" "RHEL AI CPU container base image (3.5.0)" "External"
        rhelAIPyPI = softwareSystem "RHEL AI Python Index" "Red Hat AI package repository" "External"

        # Relationships
        llmdScheduler -> latencyPredictor "Requests latency predictions" "HTTP/80"
        traceProducer -> latencyPredictor "Submits training traces" "HTTP/8000"

        llmdScheduler -> predictionService "POST /predict" "HTTP/80"
        predictionService -> predictionServer "Forward" "HTTP/8001"
        predictionServer -> commonLib "Uses types"
        predictionServer -> trainingService "Poll model metadata and download artifacts" "HTTP/8000"

        traceProducer -> trainingService "POST /add_training_data_bulk" "HTTP/8000"
        trainingService -> trainingServer "Forward" "HTTP/8000"
        trainingServer -> commonLib "Uses types"

        latencyPredictor -> kubernetes "Deployed on" "Deployments, Services, ConfigMaps"
        latencyPredictor -> aipcc "Built from" "Konflux digest-pinned"
        latencyPredictor -> rhelAIPyPI "Installs dependencies" "HTTPS/443"
    }

    views {
        systemContext latencyPredictor "SystemContext" {
            include *
            autoLayout
        }

        container latencyPredictor "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
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
