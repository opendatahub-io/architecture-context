# Architecture Changes: ml-metadata

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | grpc_services | MetadataStoreService | * | <empty> | <empty> | gRPC service defined in proto with ~40 RPCs; server listens on port 8080 per Dockerfile entrypoint | ml_metadata/proto/metadata_store_service.proto:1142, ml_metadata/tools/docker_server/Dockerfile.konflux:47-59 |
| add | integration_points | MariaDB/MySQL :: Database | * | <empty> | <empty> | Server supports MySQL/MariaDB backend via ConnectionConfig; MariaDB connector bundled in Dockerfile | ml_metadata/proto/metadata_store.proto:788-805, ml_metadata/tools/docker_server/Dockerfile.konflux:39 |
| add | internal_dependencies | MariaDB | * | <empty> | <empty> | MariaDB connector library bundled; MySQLDatabaseConfig defined in proto for persistent backend | ml_metadata/proto/metadata_store.proto:607-656, ml_metadata/tools/docker_server/Dockerfile.konflux:38-39 |
| add | authentication | MetadataStoreService gRPC :: All | * | <empty> | <empty> | No built-in auth; optional mTLS via MetadataStoreServerConfig.SSLConfig with client_verify | ml_metadata/proto/metadata_store.proto:860-874, ml_metadata/tools/docker_server/Dockerfile.konflux:56-59 |
