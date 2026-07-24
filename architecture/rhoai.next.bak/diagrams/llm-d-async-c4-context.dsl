workspace {
    model {
        producer = person "Producer Application" "External application that submits async inference jobs to the queue"
        consumer = person "Consumer Application" "External application that retrieves inference results from the queue"

        asyncProcessor = softwareSystem "llm-d Async Processor" "Queue-based async worker that pulls inference jobs from message queues and dispatches them to an inference gateway" {
            worker = container "Async Worker" "N concurrent goroutines that poll queues, apply dispatch gates, and forward requests" "Go Service"
            flowControl = container "Flow Control Gates" "Configurable dispatch gating: prometheus-saturation, prometheus-budget, prometheus-query, redis, redis-quota, composite, constant" "Go Package"
            redisPubSubFlow = container "Redis Pub/Sub Flow" "Queue implementation using Redis Pub/Sub channels" "Go Package"
            redisSortedSetFlow = container "Redis Sorted Set Flow" "Queue implementation using Redis sorted sets with deadline-based scoring" "Go Package"
            gcpPubSubFlow = container "GCP Pub/Sub Flow" "Queue implementation using GCP Pub/Sub topics and subscriptions" "Go Package"
            metricsServer = container "Metrics Server" "Prometheus metrics endpoint on port 9090 with optional K8s auth" "Go (controller-runtime)"
            randomRobin = container "RandomRobinPolicy" "Merges multiple queue channels using reflect.Select for random multiplexing" "Go Package"
        }

        producerSDK = softwareSystem "Producer SDK" "Go client library for submitting requests to and retrieving results from the Redis sorted-set queue" "Internal Library"

        redis = softwareSystem "Redis" "Message queue backend for request/retry/result queues, dispatch budget keys, and quota tracking" "External"
        gcpPubSub = softwareSystem "GCP Pub/Sub" "Alternative message queue backend using Google Cloud Pub/Sub topics" "External"
        prometheus = softwareSystem "Prometheus" "Metric source for flow control dispatch gates (pool saturation, queue depth)" "External"
        gmp = softwareSystem "Google Managed Prometheus" "Alternative Prometheus backend for GCP deployments" "External"
        igw = softwareSystem "Inference Gateway (IGW)" "llm-d inference gateway (Envoy/Istio) that receives forwarded inference requests" "Internal llm-d"
        epp = softwareSystem "Inference Scheduler (EPP)" "llm-d endpoint picker providing flow control metrics for dispatch gates" "Internal llm-d"
        vllm = softwareSystem "vLLM Model Servers" "Model serving runtime providing running request count metrics" "Internal llm-d"
        inferencePool = softwareSystem "Gateway API InferencePool" "Provides ready pods metric for computing max system capacity" "Internal llm-d"
        k8sAPI = softwareSystem "Kubernetes API" "ServiceAccount token auth, TokenReview and SubjectAccessReview for metrics endpoint" "External"

        # Relationships
        producer -> producerSDK "Submits inference requests via" "Go SDK"
        producerSDK -> redis "ZADD to request sorted set" "Redis/6379 Optional TLS"
        consumer -> redis "BRPOP result queue" "Redis/6379 Optional TLS"

        producer -> gcpPubSub "Publish to request topic" "HTTPS/443 TLS 1.2+ GCP IAM"

        asyncProcessor -> redis "Poll/push queues, budget keys, quota" "Redis/6379 Optional TLS"
        asyncProcessor -> gcpPubSub "Subscribe/publish topics" "HTTPS/443 TLS 1.2+ OAuth2"
        asyncProcessor -> igw "POST inference requests" "HTTP(S)/80,443 TLS 1.2+ Optional mTLS"
        asyncProcessor -> prometheus "PromQL queries for gate metrics" "HTTP/9090"
        asyncProcessor -> gmp "PromQL queries (GCP alternative)" "HTTPS/443 TLS 1.2+"
        asyncProcessor -> k8sAPI "TokenReview, SubjectAccessReview" "HTTPS/443 TLS"

        igw -> epp "Route to optimal model server" "Internal"
        epp -> vllm "Forward inference request" "Internal"

        # Internal container relationships
        worker -> flowControl "Check dispatch gate before forwarding"
        worker -> randomRobin "Read merged queue channel"
        randomRobin -> redisPubSubFlow "Poll messages"
        randomRobin -> redisSortedSetFlow "Poll messages"
        randomRobin -> gcpPubSubFlow "Poll messages"
        flowControl -> prometheus "PromQL queries" "HTTP/9090"
        flowControl -> redis "Budget/quota keys" "Redis/6379"
    }

    views {
        systemContext asyncProcessor "SystemContext" {
            include *
            autoLayout
        }

        container asyncProcessor "Containers" {
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
            element "Internal Library" {
                background #f5a623
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Person" {
                background #08427b
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
