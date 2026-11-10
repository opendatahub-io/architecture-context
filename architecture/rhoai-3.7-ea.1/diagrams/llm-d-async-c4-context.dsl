workspace "llm-d-async" "C4 context for the llm-d Async Processor (RHOAI 3.7-ea.1)" {
    model {
        producer = person "Batch Producer" "batch-gateway, batch jobs or workflows that enqueue latency-insensitive inference requests"
        operator = person "Platform Operator" "Deploys the Helm chart and configures transports, pools, and gates"

        llmdAsync = softwareSystem "llm-d-async" "Async Processor: pulls inference requests from a broker, applies dispatch gates and merge policies, dispatches to the inference gateway, writes results" {
            processor = container "Async Processor" "Single binary /llm-d-async. Transport flows, flow control gates, merge policies, worker pools" "Go Service"
            healthServer = container "Health Server" "/healthz, /readyz on 8081/TCP" "Go HTTP"
            metricsServer = container "Metrics Server" "/metrics on 9090/TCP, optional TokenReview/SAR filter" "controller-runtime"
            producerLibs = container "Producer Libraries" "api, pipeline, producer (Redis), producer-sql (Postgres) Go modules" "Go Library"
            helmChart = container "Helm Chart" "Deployment, ServiceAccount, Secret, ConfigMap, PodMonitor, PrometheusRule, dashboards" "Helm v0.7.0"

            processor -> healthServer "Reports readiness/drain state"
            processor -> metricsServer "Exports queue/gate/worker metrics"
        }

        batchGateway = softwareSystem "batch-gateway" "Provides OpenAI /v1/batches API and produces async requests" "Internal RHOAI"
        inferenceGateway = softwareSystem "llm-d-router / EPP" "Inference gateway (gateway-api-inference-extension) with flow control" "Internal RHOAI"
        vllm = softwareSystem "vLLM Inference Pool" "Model serving backend" "Internal RHOAI"
        kserve = softwareSystem "KServe LLMInferenceService" "Hosts the llm-d gateway and pool" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Scrapes processor metrics; serves saturation metrics for gates" "Internal RHOAI"

        redis = softwareSystem "Redis / Valkey" "Message broker and quota store" "External"
        postgres = softwareSystem "PostgreSQL" "sql transport broker and sql-quota store (can be shared with batch-gateway)" "External"
        pubsub = softwareSystem "GCP Pub/Sub" "Message broker" "External"
        otlp = softwareSystem "OTLP Collector" "Trace sink (Jaeger, Tempo, OTel Collector)" "External"
        k8sApi = softwareSystem "Kubernetes API" "REST config; TokenReview/SubjectAccessReview" "External"

        producer -> batchGateway "Submits batches" "HTTPS"
        operator -> helmChart "helm install / configure values"
        batchGateway -> producerLibs "Uses to enqueue requests and read results"
        producerLibs -> redis "Enqueue requests / read results" "RESP/6379"
        producerLibs -> postgres "Insert async_requests / read async_results" "Postgres/5432"

        processor -> redis "Poll/claim requests, write results, quota/rate gates" "RESP/6379, optional TLS"
        processor -> postgres "Lease partitions, dispatch, write results, auto-migrate schema" "Postgres/5432, sslmode"
        processor -> pubsub "Pull/ack messages, publish results" "gRPC/443 TLS, ADC"
        processor -> inferenceGateway "POST inference requests with fairness/objective headers" "HTTP/HTTPS, optional mTLS"
        processor -> prometheus "PromQL budget/saturation queries" "HTTP"
        processor -> otlp "Export traces" "gRPC/4317 (plaintext default)"
        processor -> k8sApi "Load REST config; TokenReview/SAR when metrics auth on" "HTTPS/6443"
        prometheus -> metricsServer "Scrapes via PodMonitor" "HTTP/9090"
        inferenceGateway -> vllm "Routes requests" "HTTP/8000"
        kserve -> inferenceGateway "Deploys"
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
            element "Person" {
                shape person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #6aa8ee
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
