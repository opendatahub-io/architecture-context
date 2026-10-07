workspace {
    model {
        llmdEngine = person "llm-d Inference Engine" "Generates actual TTFT/TPOT latency observations from inference requests"
        llmdRouter = person "llm-d Routing Layer" "Consumes latency predictions to inform request routing decisions"

        latencyPredictor = softwareSystem "llm-d-latency-predictor" "Dual-server ML prediction system for TTFT/TPOT latency estimation" {
            predictionServer = container "Prediction Server" "Serves low-latency TTFT/TPOT predictions via REST API, supporting single and bulk (up to 10k) modes" "Python FastAPI, 8001/TCP" {
                predAPI = component "Prediction API" "REST endpoints for single and bulk predictions" "FastAPI routes"
                modelSync = component "Model Sync Thread" "Periodically downloads trained models from training server with checksum-based cache invalidation" "Background thread"
                bulkFastPath = component "Bulk Predict Fast Path" "Optimized numpy/DataFrame batch inference returning ORJSONResponse" "numpy, pandas"
            }

            trainingServer = container "Training Server" "Collects training data, trains regression models, serves trained model files for download" "Python FastAPI, 8000/TCP" {
                trainAPI = component "Training API" "REST endpoints for data ingestion, model download, and metrics" "FastAPI routes"
                retrainLoop = component "Retrain Loop" "Periodically retrains models (XGBoost/LightGBM/BayesianRidge) from bucketed data" "Background thread, 30min interval"
                bucketStore = component "Bucketed Data Store" "3D bucket grid (queue x cache x prefix = 400 buckets) with RandomDropDeque for balanced sampling" "In-memory"
                modelFileStore = component "Model File Store" "Serialized ML models (joblib format) on persistent storage" "PVC"
            }

            commonTypes = container "common/types" "Shared data types: ModelType, ObjectiveType, QueueGatedModel, RandomDropDeque" "Python library"

            testHarness = container "Test Harness" "Integration test suite exercising dual-server architecture end-to-end" "Python pytest Job"
        }

        kubernetes = softwareSystem "Kubernetes" "Container orchestration platform" "External"

        # Relationships
        llmdEngine -> latencyPredictor "Sends TTFT/TPOT training observations" "HTTP POST /add_training_data_bulk"
        llmdRouter -> latencyPredictor "Requests latency predictions" "HTTP POST /predict, /predict/bulk/strict"

        # Internal container relationships
        modelSync -> trainingServer "Downloads trained models" "HTTP GET /model/{name}/download, 8000/TCP"
        predictionServer -> commonTypes "Uses shared types"
        trainingServer -> commonTypes "Uses shared types"
        testHarness -> predictionServer "Validates" "HTTP"
        testHarness -> trainingServer "Validates" "HTTP"

        # Internal component relationships
        trainAPI -> bucketStore "Stores training samples"
        retrainLoop -> bucketStore "Reads training data"
        retrainLoop -> modelFileStore "Writes trained models"
        modelSync -> trainAPI "Checks model timestamps and downloads"
        predAPI -> bulkFastPath "Delegates batch requests"

        latencyPredictor -> kubernetes "Deploys on" "Deployment, Service, PVC"
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

        component predictionServer "PredictionServerComponents" {
            include *
            autoLayout
        }

        component trainingServer "TrainingServerComponents" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
            element "Component" {
                background #85bbf0
                color #000000
            }
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
        }
    }
}
