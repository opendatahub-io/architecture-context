workspace "Feast (RHOAI 3.7-ea.1)" "Feature store for RHOAI: operator plus Feast operand servers" {
    model {
        dataScientist = person "Data Scientist" "Defines features, materializes data, retrieves features from workbenches and pipelines"
        platformAdmin = person "Platform Admin" "Enables Feast through the RHOAI platform operator"

        feast = softwareSystem "Feast" "Feature store: reconciles FeatureStore CRs into per-namespace registry, online, offline, UI, lineage and MCP servers" {
            operator = container "Feast Operator" "Reconciles FeatureStore (feast.dev/v1) and Notebook CRs. Metrics on 8443/TCP HTTPS with TokenReview + SAR" "Go, controller-runtime 0.23.3"
            registry = container "Registry Server" "feast.registry.RegistryServer gRPC 6570/6571 and REST 6572/6573. Feast authz" "Python, gRPC + FastAPI"
            online = container "Online Feature Server" "Online retrieval, push, materialize on 6566/6567. Feast authz" "Python, FastAPI/gunicorn"
            offline = container "Offline Server" "Historical retrieval over Arrow Flight 8815/8816. Feast authz" "Python, Arrow Flight"
            ui = container "UI Server" "Web UI on 8888/8443, exposed via reencrypt Route. No auth detected" "Python, FastAPI"
            lineage = container "Lineage Server" "OpenLineage consumer and graph API on 6580/6581" "Python"
            mcp = container "MCP Server (operand)" "MCP tools over Feast on 8100/8101" "Python, fastmcp"
            dataRegistry = container "Data Registry" "Cluster singleton. kube-rbac-proxy 8443 → Feast REST 127.0.0.1:6572; dataregistry.opendatahub.io API" "Python + kube-rbac-proxy"
            cronJob = container "Materialization CronJob" "kubectl exec into the Feast Deployment for scheduled feast apply / materialize-incremental" "ose-cli"
            standaloneMcp = container "odh-feast-mcp" "Standalone feast mcp server image, port 8000. No operator wiring" "Python"
        }

        k8s = softwareSystem "Kubernetes API" "Cluster API server, TokenReview and SubjectAccessReview" "External"
        stores = softwareSystem "Feature Stores and Backends" "Redis/Valkey, PostgreSQL, Cassandra, Snowflake, Milvus, S3/GCS" "External"
        oidc = softwareSystem "OIDC Provider" "JWKS for OIDC authz" "External"
        openLineage = softwareSystem "OpenLineage Endpoint" "Lineage event consumer" "External"
        git = softwareSystem "Git Repository" "Feature repository source" "External"

        rhodsOperator = softwareSystem "RHOAI Platform Operator" "Deploys the Feast operator and injects images" "Internal RHOAI"
        dashboard = softwareSystem "RHOAI Dashboard" "Feature store UI; reads registry REST and data registry" "Internal RHOAI"
        workbenches = softwareSystem "Workbenches (Kubeflow Notebooks)" "Labeled notebooks get Feast client configs" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Tracking URI for feature–model linkage" "Internal RHOAI"
        sparkOperator = softwareSystem "Spark Operator" "Spark compute engine for materialization" "Internal RHOAI"
        ray = softwareSystem "KubeRay / CodeFlare" "Ray compute engine" "Internal RHOAI"
        router = softwareSystem "OpenShift Router" "Route ingress for the Feast UI" "Internal RHOAI"
        prometheus = softwareSystem "Prometheus" "Scrapes operator and Feast metrics" "Internal RHOAI"
        serviceCa = softwareSystem "OpenShift Service CA" "Issues serving certificates" "Internal RHOAI"

        dataScientist -> k8s "Creates FeatureStore CRs" "HTTPS/6443"
        dataScientist -> workbenches "Uses Feast SDK from"
        dataScientist -> router "Opens Feast UI" "HTTPS/443"
        platformAdmin -> rhodsOperator "Enables Feast component"
        rhodsOperator -> operator "Deploys (config/overlays/rhoai)"

        operator -> k8s "Watches CRs, creates Deployments, Services, Routes, RBAC, NetworkPolicies, CronJobs" "HTTPS/6443, SA token"
        operator -> mlflow "Discovers tracking URI" "CRD watch"
        operator -> workbenches "Writes notebook-feast-config ConfigMaps"
        operator -> registry "Status/client calls" "gRPC/REST, intra-comm token"

        workbenches -> online "Retrieves online features" "HTTPS/443→6567, Bearer token"
        workbenches -> registry "Reads feature definitions" "gRPC/443→6571, Bearer token"
        dashboard -> registry "Reads registry REST" "HTTPS/443→6573"
        dashboard -> dataRegistry "Data catalog API" "HTTPS/443→8443, Bearer token"
        router -> ui "Reencrypt" "HTTPS/8443"

        online -> registry "Feature definitions" "gRPC/6571 TLS, intra-comm token"
        offline -> registry "Feature definitions" "gRPC/6571 TLS, intra-comm token"
        ui -> registry "Registry data"
        lineage -> registry "Lineage data"
        mcp -> registry "Registry metadata"
        standaloneMcp -> registry "Feast client" "gRPC/HTTP"
        cronJob -> k8s "pods/exec on Feast Deployment" "HTTPS/WSS 6443"

        online -> k8s "TokenReview" "HTTPS/6443"
        dataRegistry -> k8s "TokenReview + SAR" "HTTPS/6443"
        online -> stores "Reads/writes online features" "Configured, DB credentials"
        offline -> stores "Historical data" "Configured"
        registry -> stores "Registry backend" "Configured"
        online -> oidc "JWKS fetch" "HTTPS/443"
        lineage -> openLineage "Lineage events" "HTTPS, API key"
        registry -> git "Clones feature repo" "HTTPS/443"
        offline -> sparkOperator "SparkApplications"
        offline -> ray "Ray compute" "gRPC"
        prometheus -> operator "Scrapes metrics" "HTTPS/8443, TokenReview + SAR"
        prometheus -> online "Scrapes metrics" "HTTP/8000, no auth"
        serviceCa -> feast "Issues *-tls serving certs"
    }

    views {
        systemContext feast "SystemContext" {
            include *
            autoLayout
        }

        container feast "Containers" {
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
                background #438dd5
                color #ffffff
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
        }
    }
}
