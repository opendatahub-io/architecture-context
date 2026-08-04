# Architecture Changes: MLServer

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | http_endpoints | GET :: /v2/health/live | * | <empty> | <empty> | V2 liveness probe endpoint registered in FastAPI app | mlserver/rest/app.py:141 |
| add | http_endpoints | GET :: /v2/health/ready | * | <empty> | <empty> | V2 readiness probe endpoint registered in FastAPI app | mlserver/rest/app.py:142 |
| add | http_endpoints | GET :: /v2 | * | <empty> | <empty> | V2 server metadata endpoint registered in FastAPI app | mlserver/rest/app.py:154 |
| add | http_endpoints | GET :: /v2/models/{model_name} | * | <empty> | <empty> | V2 model metadata endpoint registered in FastAPI app | mlserver/rest/app.py:117 |
| add | http_endpoints | GET :: /v2/models/{model_name}/ready | * | <empty> | <empty> | V2 model ready check endpoint registered in FastAPI app | mlserver/rest/app.py:63 |
| add | http_endpoints | POST :: /v2/models/{model_name}/infer | * | <empty> | <empty> | V2 model inference endpoint registered in FastAPI app | mlserver/rest/app.py:72 |
| add | http_endpoints | POST :: /v2/models/{model_name}/generate | * | <empty> | <empty> | V2 text generation endpoint registered in FastAPI app | mlserver/rest/app.py:83 |
| add | http_endpoints | POST :: /v2/models/{model_name}/infer_stream | * | <empty> | <empty> | V2 streaming inference endpoint registered in FastAPI app | mlserver/rest/app.py:94 |
| add | http_endpoints | POST :: /v2/models/{model_name}/generate_stream | * | <empty> | <empty> | V2 streaming generation endpoint registered in FastAPI app | mlserver/rest/app.py:105 |
| add | http_endpoints | GET :: /v2/runtimes | * | <empty> | <empty> | Runtime security information endpoint registered in FastAPI app | mlserver/rest/app.py:159 |
| add | http_endpoints | POST :: /v2/repository/index | * | <empty> | <empty> | Model repository index endpoint registered in FastAPI app | mlserver/rest/app.py:167 |
| add | http_endpoints | POST :: /v2/repository/models/{model_name}/load | * | <empty> | <empty> | Model load endpoint registered in FastAPI app | mlserver/rest/app.py:172 |
| add | http_endpoints | POST :: /v2/repository/models/{model_name}/unload | * | <empty> | <empty> | Model unload endpoint registered in FastAPI app | mlserver/rest/app.py:177 |
| add | http_endpoints | GET :: /metrics | * | <empty> | <empty> | Prometheus metrics endpoint on dedicated metrics port 8082 | mlserver/settings.py:445-451, mlserver/rest/app.py:225-236 |
| update | grpc_services | GRPCInferenceService | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | ModelRepositoryService | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ModelInfer | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ModelMetadata | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ModelReady | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ModelStreamInfer | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryIndex | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelLoad | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelUnload | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/RuntimeSecurity | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ServerLive | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ServerMetadata | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.GRPCInferenceService/ServerReady | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryIndex | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelLoad | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelUnload | Port | | 8081/TCP | gRPC server binds to settings.grpc_port which defaults to 8081 | mlserver/grpc/server.py:88-89, mlserver/settings.py:435 |
| update | grpc_services | GRPCInferenceService | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | ModelRepositoryService | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ModelInfer | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ModelMetadata | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ModelReady | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ModelStreamInfer | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryIndex | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelLoad | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelUnload | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/RuntimeSecurity | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ServerLive | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ServerMetadata | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.GRPCInferenceService/ServerReady | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryIndex | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelLoad | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelUnload | Transport | Unknown | HTTP/2 | gRPC uses HTTP/2 transport by protocol definition | mlserver/grpc/server.py:75-89 |
| update | grpc_services | GRPCInferenceService | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | ModelRepositoryService | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelInfer | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelMetadata | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelReady | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelStreamInfer | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryIndex | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelLoad | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelUnload | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RuntimeSecurity | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ServerLive | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ServerMetadata | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ServerReady | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryIndex | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelLoad | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelUnload | Encryption | Unknown | None (insecure port) | Server uses add_insecure_port - no TLS at application level | mlserver/grpc/server.py:88 |
| update | grpc_services | GRPCInferenceService | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | ModelRepositoryService | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelInfer | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelMetadata | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelReady | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ModelStreamInfer | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryIndex | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelLoad | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RepositoryModelUnload | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/RuntimeSecurity | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ServerLive | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ServerMetadata | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.GRPCInferenceService/ServerReady | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryIndex | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelLoad | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| update | grpc_services | inference.model_repository.ModelRepositoryService/RepositoryModelUnload | Auth | Unknown | platform-delegated | No application-level auth; kube-rbac-proxy sidecar provides authentication | mlserver/grpc/server.py:88 |
| add | internal_dependencies | KServe | * | <empty> | <empty> | MLServer runs as a KServe ServingRuntime container | Dockerfile.konflux:66 |
| add | internal_dependencies | OpenTelemetry Collector | * | <empty> | <empty> | Distributed tracing export from REST and gRPC servers | mlserver/rest/app.py:7, mlserver/grpc/server.py:16 |
| add | integration_points | KServe :: Container runtime | * | <empty> | <empty> | MLServer operates as a KServe ServingRuntime container | Dockerfile.konflux:66 |
| add | integration_points | OpenTelemetry Collector :: Telemetry export | * | <empty> | <empty> | OpenTelemetry instrumentation in both REST and gRPC servers | mlserver/rest/app.py:7, mlserver/grpc/server.py:16 |
| add | integration_points | Kafka :: Message queue | * | <empty> | <empty> | Optional async inference via Kafka consumer/producer | mlserver/kafka/server.py:5, mlserver/kafka/server.py:28-35 |
