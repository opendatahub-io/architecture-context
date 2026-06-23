workspace {
    model {
        datascientist = person "Data Scientist / Application Developer" "Submits async inference requests via Producer SDK"

        llmdAsync = softwareSystem "llm-d-async" "Asynchronous inference processor that dequeues LLM requests from message queues, dispatches to inference gateway, and publishes results" {
            asyncProcessor = container "Async Processor" "Dequeues requests, dispatches to IGW, publishes results. Supports concurrent workers with flow control gates." "Go Service"
            producerSDK = container "Producer SDK" "Client library for submitting requests and retrieving results from Redis sorted set queues" "Go Library"
            flowControlGates = container "Flow Control Gates" "Pluggable dispatch throttling via Redis, Prometheus, composite, and quota-based gates" "Go Library"
        }

        redis = softwareSystem "Redis" "Message queue backend for request/result queues, retry queues, and gate budget tracking" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue backend for GCP deployments" "External"
        igw = softwareSystem "Inference Gateway (IGW)" "Routes inference requests to appropriate model servers" "Internal llm-d"
        prometheus = softwareSystem "Prometheus" "Provides inference pool metrics for flow control gate decisions" "External"
        gmp = softwareSystem "Google Managed Prometheus" "Alternative Prometheus backend for GCP deployments" "External"
        vllm = softwareSystem "vLLM Model Servers" "Serves LLM inference requests (accessed indirectly via IGW)" "Internal"
        k8sAPI = softwareSystem "Kubernetes API Server" "Provides SubjectAccessReview for metrics endpoint authentication" "Platform"
        gaie = softwareSystem "Gateway API Inference Extension (GAIE)" "Manages the Inference Gateway; provides EPP logging utilities" "Internal llm-d"

        # User interactions
        datascientist -> producerSDK "Submits inference requests and retrieves results"

        # Producer SDK interactions
        producerSDK -> redis "ZADD requests, BRPOP results" "Redis / 6379/TCP"

        # Async Processor interactions
        asyncProcessor -> redis "Poll requests, publish results, retry queue, gate budgets" "Redis / 6379/TCP"
        asyncProcessor -> gcpPubSub "Subscribe requests, publish results" "gRPC-HTTPS / 443/TCP"
        asyncProcessor -> igw "POST inference requests with JSON payload" "HTTP(S) / 80 or 443/TCP"
        asyncProcessor -> prometheus "PromQL queries for flow control" "HTTP / 9090/TCP"
        asyncProcessor -> gmp "PromQL queries (GCP alternative)" "HTTPS / 443/TCP"
        asyncProcessor -> k8sAPI "SubjectAccessReview for metrics auth" "HTTPS / 443/TCP"

        # Flow control
        flowControlGates -> redis "Budget keys, quota tracking" "Redis / 6379/TCP"
        flowControlGates -> prometheus "Saturation and budget metrics" "HTTP / 9090/TCP"

        # Internal dependencies
        igw -> vllm "Routes inference to model servers"
        asyncProcessor -> gaie "Imports EPP logging utilities" "Go module dependency"
    }

    views {
        systemContext llmdAsync "SystemContext" {
            include *
            autoLayout
        }

        container llmdAsync "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal llm-d" {
                background #7ed321
                color #ffffff
            }
            element "Internal" {
                background #4a90e2
                color #ffffff
            }
            element "Platform" {
                background #dae8fc
                color #333333
            }
            element "Person" {
                shape Person
                background #08427b
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
