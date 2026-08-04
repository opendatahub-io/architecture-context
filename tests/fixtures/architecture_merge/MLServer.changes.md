# Architecture Change Evidence

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | get :: /v2/health/live | * | <empty> | <empty> | FastAPI registers the liveness route. | mlserver/rest/app.py:141-142 |
| add | http_endpoints | get :: /v2/health/ready | * | <empty> | <empty> | FastAPI registers the readiness route. | mlserver/rest/app.py:141-142 |
| add | http_endpoints | get :: /v2 | * | <empty> | <empty> | FastAPI registers the server metadata route. | mlserver/rest/app.py:141-160 |
| add | http_endpoints | get :: /v2/runtimes | * | <empty> | <empty> | FastAPI registers the runtime metadata route. | mlserver/rest/app.py:154-163 |
| add | http_endpoints | get :: /v2/models/{model_name}/ready | * | <empty> | <empty> | FastAPI registers model readiness. | mlserver/rest/app.py:60-70 |
| add | http_endpoints | get :: /v2/models/{model_name}/versions/{model_version}/ready | * | <empty> | <empty> | FastAPI registers versioned model readiness. | mlserver/rest/app.py:63-70 |
| add | http_endpoints | get :: /v2/models/{model_name} | * | <empty> | <empty> | FastAPI registers model metadata. | mlserver/rest/app.py:114-123 |
| add | http_endpoints | get :: /v2/models/{model_name}/versions/{model_version} | * | <empty> | <empty> | FastAPI registers versioned model metadata. | mlserver/rest/app.py:116-123 |
| add | http_endpoints | post :: /v2/models/{model_name}/infer | * | <empty> | <empty> | FastAPI registers model inference. | mlserver/rest/app.py:70-80 |
| add | http_endpoints | post :: /v2/models/{model_name}/versions/{model_version}/infer | * | <empty> | <empty> | FastAPI registers versioned inference. | mlserver/rest/app.py:74-80 |
| add | http_endpoints | post :: /v2/models/{model_name}/generate | * | <empty> | <empty> | FastAPI registers the generate alias. | mlserver/rest/app.py:81-91 |
| add | http_endpoints | post :: /v2/models/{model_name}/versions/{model_version}/generate | * | <empty> | <empty> | FastAPI registers the versioned generate alias. | mlserver/rest/app.py:85-91 |
| add | http_endpoints | post :: /v2/models/{model_name}/infer_stream | * | <empty> | <empty> | FastAPI registers streaming inference. | mlserver/rest/app.py:92-102 |
| add | http_endpoints | post :: /v2/models/{model_name}/versions/{model_version}/infer_stream | * | <empty> | <empty> | FastAPI registers versioned streaming inference. | mlserver/rest/app.py:96-102 |
| add | http_endpoints | post :: /v2/models/{model_name}/generate_stream | * | <empty> | <empty> | FastAPI registers the streaming generate alias. | mlserver/rest/app.py:103-113 |
| add | http_endpoints | post :: /v2/models/{model_name}/versions/{model_version}/generate_stream | * | <empty> | <empty> | FastAPI registers the versioned streaming generate alias. | mlserver/rest/app.py:107-113 |
| add | http_endpoints | post :: /v2/repository/index | * | <empty> | <empty> | FastAPI registers repository index. | mlserver/rest/app.py:165-170 |
| add | http_endpoints | post :: /v2/repository/models/{model_name}/load | * | <empty> | <empty> | FastAPI registers model loading. | mlserver/rest/app.py:170-175 |
| add | http_endpoints | post :: /v2/repository/models/{model_name}/unload | * | <empty> | <empty> | FastAPI registers model unloading. | mlserver/rest/app.py:175-180 |
| add | http_endpoints | get :: /v2/docs | * | <empty> | <empty> | FastAPI registers Swagger UI. | mlserver/rest/app.py:143-152 |
| add | http_endpoints | get :: /v2/docs/dataplane.json | * | <empty> | <empty> | FastAPI registers the OpenAPI schema route. | mlserver/rest/app.py:143-152 |
| add | http_endpoints | get :: /v2/models/{model_name}/docs | * | <empty> | <empty> | FastAPI registers model-specific Swagger UI. | mlserver/rest/app.py:123-140 |
| add | http_endpoints | get :: /v2/models/{model_name}/docs/dataplane.json | * | <empty> | <empty> | FastAPI registers model-specific OpenAPI. | mlserver/rest/app.py:123-132 |
| add | http_endpoints | get :: /metrics | * | <empty> | <empty> | The metrics server exposes the configured metrics endpoint. | mlserver/metrics/server.py:35-65 |
| add | services | rest inference | * | <empty> | <empty> | The REST server binds the configured HTTP server. | mlserver/rest/server.py:88-103 |
| add | services | grpc inference | * | <empty> | <empty> | The gRPC server binds the configured gRPC port. | mlserver/grpc/server.py:78-90 |
| add | services | metrics | * | <empty> | <empty> | The metrics server binds the configured metrics port. | mlserver/metrics/server.py:35-65 |
| add | egress | kafka brokers | * | <empty> | <empty> | Kafka consumers and producers connect to configured bootstrap servers. | mlserver/kafka/server.py:28-35 |
| add | egress | opentelemetry collector | * | <empty> | <empty> | OTLP spans are exported to the configured tracing server. | mlserver/tracing.py:18-24 |
| add | egress | kubernetes api | * | <empty> | <empty> | Runtime code reads the mounted service-account namespace. | mlserver/cloudevents.py:25-29 |
| add | authentication | runtime loading :: n/a | * | <empty> | <empty> | Production mode uses an image-baked trusted-runtime allowlist. | mlserver/settings.py:39-39; mlserver/settings.py:497-502 |
| add | authentication | custom environments :: n/a | * | <empty> | <empty> | Production mode rejects custom environment paths and tarballs. | mlserver/settings.py:571-600 |
| add | authentication | cors :: configurable | * | <empty> | <empty> | Production mode rejects wildcard CORS origins and regexes. | mlserver/settings.py:489-514 |
| add | integration_points | prometheus :: http scrape | * | <empty> | <empty> | The metrics server exposes Prometheus metrics over HTTP. | mlserver/metrics/server.py:35-65 |
| add | integration_points | opentelemetry collector :: grpc export | * | <empty> | <empty> | The tracer exports spans with the OTLP exporter. | mlserver/tracing.py:18-24 |
| add | integration_points | kafka :: tcp consumer/producer | * | <empty> | <empty> | The Kafka server creates both consumer and producer clients. | mlserver/kafka/server.py:28-35 |
| add | integration_points | kubernetes api :: file mount | * | <empty> | <empty> | CloudEvents read namespace identity from the service-account mount. | mlserver/cloudevents.py:25-29 |
