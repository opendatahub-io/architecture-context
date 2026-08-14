# Architecture Changes: ml-metadata

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | grpc_services | MetadataStoreService | * | <empty> | <empty> | gRPC service definition found in proto with ~35 RPCs; server binary exposes port 8080 via ENTRYPOINT | ml_metadata/proto/metadata_store_service.proto:1142, ml_metadata/tools/docker_server/Dockerfile.konflux:46-59 |
| add | authentication | MetadataStoreService gRPC :: All | * | <empty> | <empty> | No built-in auth; optional mTLS via SSLConfig; platform-delegated in RHOAI | ml_metadata/proto/metadata_store.proto:860-873, ml_metadata/tools/docker_server/Dockerfile.konflux:56-59 |
| add | internal_dependencies | MySQL/MariaDB | * | <empty> | <empty> | Server builds and ships with mariadb-connector-c; ConnectionConfig supports MySQL backend | ml_metadata/tools/docker_server/Dockerfile.konflux:39, ml_metadata/proto/metadata_store.proto:788-798 |
| add | integration_points | MySQL/MariaDB :: Database client | * | <empty> | <empty> | Server connects to MySQL/MariaDB for persistent metadata storage via ConnectionConfig | ml_metadata/proto/metadata_store.proto:607-656, ml_metadata/proto/metadata_source.proto:44 |
