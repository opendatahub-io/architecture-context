# Analyzer Synthesis Context: modelmesh-runtime-adapter

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (observed)**: 42 grpc_services facts extracted [source: internal/proto/kfserving-predict-v2/inference.proto:11, internal/proto/kfserving-predict-v2/inference.proto:14, internal/proto/kfserving-predict-v2/inference.proto:17, internal/proto/kfserving-predict-v2/inference.proto:20, internal/proto/kfserving-predict-v2/inference.proto:23, internal/proto/kfserving-predict-v2/inference.proto:26, internal/proto/mlserver/dataplane/dataplane.proto:30, internal/proto/mlserver/dataplane/dataplane.proto:34, internal/proto/mlserver/dataplane/dataplane.proto:38, internal/proto/mmesh/model-mesh.proto:33, internal/proto/mmesh/model-mesh.proto:36, internal/proto/mmesh/model-mesh.proto:39, internal/proto/mmesh/model-mesh.proto:41, internal/proto/mmesh/model-mesh.proto:49, internal/proto/mmesh/model-mesh.proto:53, internal/proto/mmesh/model-mesh.proto:58, internal/proto/mmesh/model-runtime.proto:39, internal/proto/mmesh/model-runtime.proto:43, internal/proto/mmesh/model-runtime.proto:48, internal/proto/mmesh/model-runtime.proto:51, internal/proto/mmesh/model-runtime.proto:60, internal/proto/torchserve/inference.proto:32, internal/proto/torchserve/inference.proto:36, internal/proto/torchserve/management.proto:105, internal/proto/torchserve/management.proto:108, internal/proto/torchserve/management.proto:111, internal/proto/torchserve/management.proto:114, internal/proto/torchserve/management.proto:117, internal/proto/torchserve/management.proto:120, internal/proto/triton/triton.proto:107, internal/proto/triton/triton.proto:146, internal/proto/triton/triton.proto:157, internal/proto/triton/triton.proto:168, internal/proto/triton/triton.proto:179, internal/proto/triton/triton.proto:190, internal/proto/triton/triton.proto:201, internal/proto/triton/triton.proto:89, internal/proto/triton/triton.proto:99, model-mesh-mlserver-adapter/main.go:50, model-mesh-mlserver-adapter/mlserver/mock_mlserver_server.go:67, model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go:64, model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go:87]
- **http_endpoints (not-verified)**: 0 http_endpoints facts extracted; absence is not proven by the available coverage
- **services (not-verified)**: 0 services facts extracted; absence is not proven by the available coverage
- **ingress (confirmed-empty)**: 0 ingress facts extracted
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Behavioral Evidence

No bounded behavioral evidence was extracted.

## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `model-mesh-mlserver-adapter/main.go`:49 (None, gRPC services (Go))
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `model-mesh-mlserver-adapter/main.go`:50 (Model Runtime gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `model-mesh-mlserver-adapter/mlserver/mock_mlserver_server.go`:67 (GRPCInference Service gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go`:64 (Inference APIs Service gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go`:87 (Management APIs Service gRPC, None)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile`:107 (Dockerfile:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-mlserver-adapter/main.go`:28 (model-mesh-mlserver-adapter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-mlserver-adapter/mlserver/mock_mlserver_server.go`:40 (mlserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-ovms-adapter/main.go`:28 (model-mesh-ovms-adapter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-torchserve-adapter/main.go`:28 (model-mesh-torchserve-adapter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go`:47 (torchserve)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-triton-adapter/main.go`:28 (model-mesh-triton-adapter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-triton-adapter/triton/adapter_client/adapter_client.go`:31 (adapter_client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-triton-adapter/triton/mesh_client/mesh_client.go`:31 (mesh_client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-mesh-triton-adapter/triton/mock_triton_server.go`:38 (triton)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `model-serving-puller/main.go`:29 (model-serving-puller)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `pullman/cmd/main.go`:49 (cmd)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### egress

- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `model-mesh-mlserver-adapter/server/server.go`:96 (mlserver GRPCInference Service, outbound gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `model-mesh-torchserve-adapter/server/server.go`:111 (outbound gRPC client, torchserve Management APIs Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `model-mesh-triton-adapter/server/server.go`:80 (outbound gRPC client, triton GRPCInference Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `model-serving-puller/server/server.go`:96 (mmesh Model Runtime, outbound gRPC client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pullman/storageproviders/azure/downloader.go`:42 (Azure Blob Storage, Azure Blob Storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pullman/storageproviders/azure/downloader.go`:53 (Azure Blob Storage, Azure Blob Storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pullman/storageproviders/azure/downloader.go`:68 (Azure Blob Storage, Azure Blob Storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pullman/storageproviders/gcs/downloader.go`:50 (GCS storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pullman/storageproviders/gcs/downloader.go`:52 (GCS storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What target, credentials, TLS settings, and failure behavior does this client use?
  **Expected signal:** runtime client construction and target configuration
  **Candidate:** `pullman/storageproviders/s3/downloader.go`:59 (IBM COS S3 client, IBM Cloud Object Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### grpc_services

- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/kfserving-predict-v2/inference.proto`:17 (inference.GRPCInferenceService/ModelReady)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/kfserving-predict-v2/inference.proto`:23 (inference.GRPCInferenceService/ModelMetadata)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/kfserving-predict-v2/inference.proto`:26 (inference.GRPCInferenceService/ModelInfer)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/triton/triton.proto`:107 (inference.GRPCInferenceService/ModelStatistics)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/triton/triton.proto`:179 (inference.GRPCInferenceService/CudaSharedMemoryStatus)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/triton/triton.proto`:190 (inference.GRPCInferenceService/CudaSharedMemoryRegister)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/triton/triton.proto`:201 (inference.GRPCInferenceService/CudaSharedMemoryUnregister)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `internal/proto/triton/triton.proto`:99 (inference.GRPCInferenceService/ModelConfig)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `model-mesh-mlserver-adapter/main.go`:50 (ModelRuntime, model-mesh-mlserver-adapter)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `model-mesh-mlserver-adapter/mlserver/mock_mlserver_server.go`:67 (GRPCInferenceService, model-mesh-mlserver-adapter/mlserver)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go`:64 (InferenceAPIsService, model-mesh-torchserve-adapter/torchserve)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Where is this gRPC service registered and which interceptors or credentials apply?
  **Expected signal:** service registration, interceptor, TLS, or credential configuration
  **Candidate:** `model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go`:87 (ManagementAPIsService, model-mesh-torchserve-adapter/torchserve)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### integration_points

- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `model-mesh-mlserver-adapter/server/server.go`:96 (gRPC client, outbound, mlserver GRPCInference Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `model-mesh-torchserve-adapter/server/server.go`:111 (gRPC client, outbound, torchserve Management APIs Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `model-mesh-triton-adapter/server/server.go`:80 (gRPC client, outbound, triton GRPCInference Service)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `model-serving-puller/server/server.go`:96 (gRPC client, outbound, mmesh Model Runtime)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pullman/storageproviders/azure/downloader.go`:42 (Azure Blob Storage, File storage client)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pullman/storageproviders/gcs/downloader.go`:50 (File storage client, Google Cloud Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What runtime call or protocol realizes this integration?
  **Expected signal:** client construction, request path, protocol, or failure handling
  **Candidate:** `pullman/storageproviders/s3/downloader.go`:59 (File storage client, IBM Cloud Object Storage)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- GRPCInference Service gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-mlserver-adapter/mlserver/mock_mlserver_server.go:67]
- Inference APIs Service gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go:64]
- Management APIs Service gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go:87]
- Model Runtime gRPC methods=gRPC mechanism=None enforcement=N/A policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-mlserver-adapter/main.go:50]
- gRPC services (Go) methods=ALL mechanism=None enforcement=N/A policy=Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured [source: model-mesh-mlserver-adapter/main.go:49]
### integrations

- Azure Blob Storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: pullman/storageproviders/azure/downloader.go:42]
- Google Cloud Storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: pullman/storageproviders/gcs/downloader.go:50]
- IBM Cloud Object Storage interaction=File storage client role=runtime-integration protocol=HTTP/HTTPS purpose=Runtime object storage [source: pullman/storageproviders/s3/downloader.go:59]
- mlserver GRPCInference Service interaction=gRPC client, outbound role=runtime-integration protocol=gRPC purpose=Runtime outbound gRPC client to mlserver GRPCInference Service [source: model-mesh-mlserver-adapter/server/server.go:96]
- mmesh Model Runtime interaction=gRPC client, outbound role=runtime-integration protocol=gRPC purpose=Runtime outbound gRPC client to mmesh Model Runtime [source: model-serving-puller/server/server.go:96]
- torchserve Management APIs Service interaction=gRPC client, outbound role=runtime-integration protocol=gRPC purpose=Runtime outbound gRPC client to torchserve Management APIs Service [source: model-mesh-torchserve-adapter/server/server.go:111]
- triton GRPCInference Service interaction=gRPC client, outbound role=runtime-integration protocol=gRPC purpose=Runtime outbound gRPC client to triton GRPCInference Service [source: model-mesh-triton-adapter/server/server.go:80]

## Cross-Cutting Evidence

### deployment_topology

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:deployment_topology]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: ALL gRPC services (Go) uses None at N/A; policy=Bounded grpc.NewServer option set contains only observability interceptors; no authentication interceptor configured [source: model-mesh-mlserver-adapter/main.go:49]
- **observed**: gRPC GRPCInference Service gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-mlserver-adapter/mlserver/mock_mlserver_server.go:67]
- **observed**: gRPC Inference APIs Service gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go:64]
- **observed**: gRPC Management APIs Service gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-torchserve-adapter/torchserve/mock_torchserve_server.go:87]
- **observed**: gRPC Model Runtime gRPC uses None at N/A; policy=Plaintext gRPC service has no application authentication interceptor [source: model-mesh-mlserver-adapter/main.go:50]
- **dependency-signal**: tls-config targets crypto/tls: TLS configuration import [source: pullman/storageproviders/http/downloader.go, pullman/storageproviders/http/provider.go]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
