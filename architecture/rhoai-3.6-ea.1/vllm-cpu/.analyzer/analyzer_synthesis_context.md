# Analyzer Synthesis Context: vllm-cpu

This file is a bounded, source-linked projection. Read it before the full analyzer JSON. It does not replace the authoritative JSON.

## Coverage Findings

- **crds (not-verified)**: 0 crds facts extracted; absence is not proven by the available coverage
- **grpc_services (not-verified)**: 0 grpc_services facts extracted; absence is not proven by the available coverage
- **http_endpoints (observed)**: 47 http_endpoints facts extracted [source: vllm/entrypoints/anthropic/api_router.py:49, vllm/entrypoints/anthropic/api_router.py:95, vllm/entrypoints/api_server.py:40, vllm/entrypoints/api_server.py:46, vllm/entrypoints/generate/generative_scoring/api_router.py:29, vllm/entrypoints/openai/chat_completion/api_router.py:40, vllm/entrypoints/openai/chat_completion/api_router.py:77, vllm/entrypoints/openai/completion/api_router.py:34, vllm/entrypoints/openai/dp_supervisor.py:228, vllm/entrypoints/openai/dp_supervisor.py:229, vllm/entrypoints/openai/models/api_router.py:20, vllm/entrypoints/openai/responses/api_router.py:110, vllm/entrypoints/openai/responses/api_router.py:48, vllm/entrypoints/openai/responses/api_router.py:80, vllm/entrypoints/pooling/classify/api_router.py:23, vllm/entrypoints/pooling/embed/api_router.py:25, vllm/entrypoints/pooling/embed/api_router.py:46, vllm/entrypoints/pooling/pooling/api_router.py:24, vllm/entrypoints/pooling/scoring/api_router.py:105, vllm/entrypoints/pooling/scoring/api_router.py:31, vllm/entrypoints/pooling/scoring/api_router.py:49, vllm/entrypoints/pooling/scoring/api_router.py:68, vllm/entrypoints/pooling/scoring/api_router.py:86, vllm/entrypoints/serve/disagg/api_router.py:49, vllm/entrypoints/serve/disagg/api_router.py:82, vllm/entrypoints/serve/elastic_ep/api_router.py:32, vllm/entrypoints/serve/elastic_ep/api_router.py:90, vllm/entrypoints/serve/instrumentator/basic.py:30, vllm/entrypoints/serve/instrumentator/basic.py:53, vllm/entrypoints/serve/instrumentator/offline_docs.py:36, vllm/entrypoints/serve/lora/api_router.py:43, vllm/entrypoints/serve/lora/api_router.py:59, vllm/entrypoints/serve/profile/api_router.py:21, vllm/entrypoints/serve/profile/api_router.py:29, vllm/entrypoints/serve/render/api_router.py:109, vllm/entrypoints/serve/render/api_router.py:35, vllm/entrypoints/serve/render/api_router.py:61, vllm/entrypoints/serve/render/api_router.py:84, vllm/entrypoints/serve/sagemaker/api_router.py:48, vllm/entrypoints/serve/sagemaker/api_router.py:49, vllm/entrypoints/serve/sagemaker/api_router.py:55, vllm/entrypoints/serve/tokenize/api_router.py:36, vllm/entrypoints/serve/tokenize/api_router.py:62, vllm/entrypoints/serve/tokenize/api_router.py:98, vllm/entrypoints/speech_to_text/realtime/api_router.py:17, vllm/entrypoints/speech_to_text/transcription/api_router.py:31, vllm/entrypoints/speech_to_text/translation/api_router.py:31]
- **services (observed)**: 1 services facts extracted [source: vllm/entrypoints/serve/disagg/api_router.py:82]
- **ingress (not-verified)**: 0 ingress facts extracted; absence is not proven by the available coverage
- **webhooks (not-verified)**: 0 webhooks facts extracted; absence is not proven by the available coverage

## Deterministic Cross-References


## Gap Evidence Index

### authentication

- **Question:** Where is authentication enforced for this surface, and is it conditional?
  **Expected signal:** middleware, filter, policy, or enforcement branch
  **Candidate:** `vllm/entrypoints/openai/api_server.py`:261 (Bearer token, HTTP API)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### configuration_lifecycle

- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.cpu.ubi`:106 (Dockerfile.cpu.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.hpu.ubi`:167 (Dockerfile.hpu.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.konflux.cpu`:170 (Dockerfile.konflux.cpu:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.ppc64le.ubi`:360 (Dockerfile.ppc64le.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.rocm.ubi`:122 (Dockerfile.rocm.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.s390x.ubi`:319 (Dockerfile.s390x.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.tpu.ubi`:57 (Dockerfile.tpu.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `Dockerfile.ubi`:132 (Dockerfile.ubi:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile`:1083 (docker/Dockerfile:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.cpu`:247 (docker/Dockerfile.cpu:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.ppc64le`:349 (docker/Dockerfile.ppc64le:ENTRYPOINT)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** What lifecycle, command, probes, and deployment configuration surround this entrypoint?
  **Expected signal:** main command, startup path, probe, signal handling, or workload mapping
  **Candidate:** `docker/Dockerfile.rocm`:705 (docker/Dockerfile.rocm:CMD)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### http_endpoints

- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/api_server.py`:46 (/generate, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/generate/generative_scoring/api_router.py`:29 (/generative_scoring, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/openai/dp_supervisor.py`:228 (/ready, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/pooling/classify/api_router.py`:23 (/classify, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/pooling/pooling/api_router.py`:24 (/pooling, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/pooling/scoring/api_router.py`:68 (/rerank, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/serve/disagg/api_router.py`:82 (/abort_requests, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/serve/elastic_ep/api_router.py`:90 (/is_scaling_elastic_ep, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/serve/instrumentator/basic.py`:30 (/load, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/serve/instrumentator/offline_docs.py`:36 (/docs, GET)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/serve/sagemaker/api_router.py`:55 (/invocations, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
- **Question:** Does this endpoint have additional dynamic routes or a concrete handler/owner?
  **Expected signal:** route registration, handler binding, middleware, or owner symbol
  **Candidate:** `vllm/entrypoints/serve/tokenize/api_router.py`:62 (/detokenize, POST)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship
### services

- **Question:** Which workload owns this Service and does its target port match a runtime listener?
  **Expected signal:** selector, target deployment, port mapping, or listener
  **Candidate:** `vllm/entrypoints/serve/disagg/api_router.py`:82 (vllm)
  **Status:** candidate; **Limitations:** candidate location only; source inspection is required to establish the relationship

## Section Evidence

### authentication

- HTTP API methods=All mechanism=Bearer token enforcement=ASGI middleware (AuthenticationMiddleware) policy=Source-defined authentication [source: vllm/entrypoints/openai/api_server.py:261]
### http_endpoints

- GET /docs on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/instrumentator/offline_docs.py:36]
- GET /health on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/api_server.py:40]
- GET /load on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/instrumentator/basic.py:30]
- GET /ping on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/sagemaker/api_router.py:49]
- GET /ready on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/dp_supervisor.py:228]
- GET /readyz on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/dp_supervisor.py:229]
- GET /tokenizer_info on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/tokenize/api_router.py:98]
- GET /v1/models on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/models/api_router.py:20]
- POST /abort_requests on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/disagg/api_router.py:82]
- POST /classify on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/pooling/classify/api_router.py:23]
- POST /detokenize on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/tokenize/api_router.py:62]
- POST /generate on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/api_server.py:46]
- POST /generative_scoring on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/generate/generative_scoring/api_router.py:29]
- POST /inference/v1/generate on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/disagg/api_router.py:49]
- POST /invocations on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/sagemaker/api_router.py:55]
- POST /is_scaling_elastic_ep on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/elastic_ep/api_router.py:90]
- POST /ping on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/sagemaker/api_router.py:48]
- POST /pooling on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/pooling/pooling/api_router.py:24]
- POST /rerank on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/pooling/scoring/api_router.py:68]
- POST /scale_elastic_ep on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/elastic_ep/api_router.py:32]
- POST /score on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/pooling/scoring/api_router.py:31]
- POST /start_profile on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/profile/api_router.py:21]
- POST /stop_profile on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/profile/api_router.py:29]
- POST /tokenize on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/tokenize/api_router.py:36]
- POST /v1/audio/transcriptions on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/speech_to_text/transcription/api_router.py:31]
- POST /v1/audio/translations on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/speech_to_text/translation/api_router.py:31]
- POST /v1/chat/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/chat_completion/api_router.py:40]
- POST /v1/chat/completions/batch on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/chat_completion/api_router.py:77]
- POST /v1/chat/completions/derender on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/render/api_router.py:84]
- POST /v1/chat/completions/render on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/render/api_router.py:35]
- POST /v1/completions on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/completion/api_router.py:34]
- POST /v1/completions/derender on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/render/api_router.py:109]
- POST /v1/completions/render on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/render/api_router.py:61]
- POST /v1/embeddings on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/pooling/embed/api_router.py:25]
- POST /v1/load_lora_adapter on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/serve/lora/api_router.py:43]
- POST /v1/messages on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/anthropic/api_router.py:49]
- POST /v1/messages/count_tokens on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/anthropic/api_router.py:95]
- POST /v1/rerank on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/pooling/scoring/api_router.py:86]
- POST /v1/responses/{response_id}/cancel on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/openai/responses/api_router.py:110]
- WEBSOCKET /v1/realtime on port ; transport= encryption=Configurable auth=Unknown owner= [source: vllm/entrypoints/speech_to_text/realtime/api_router.py:17]

## Cross-Cutting Evidence

### deployment_topology

- **observed**: Service vllm targets  with 0 port(s) [source: vllm/entrypoints/serve/disagg/api_router.py:82]
### disconnected_deployment

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:disconnected_deployment]
### high_availability

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:high_availability]
### ingress

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:ingress]
### security

- **observed**: All HTTP API uses Bearer token at ASGI middleware (AuthenticationMiddleware); policy=Source-defined authentication [source: vllm/entrypoints/openai/api_server.py:261]
### supply_chain

- **unresolved**: No complete deterministic evidence family was extracted; targeted source/configuration review may be required [source: coverage:supply_chain]
