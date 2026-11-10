workspace "Model Registry (RHOAI 3.7-ea.1)" {
    model {
        dataScientist = person "Data Scientist" "Registers, versions and browses models and catalog entries"
        admin = person "Platform Admin" "Creates ModelRegistry instances, configures catalog sources"

        modelRegistry = softwareSystem "Model Registry" "Central metadata store and REST API for models, plus the Model/MCP/Agent/Skill/Serving-Runtime catalog" {
            proxy = container "Model Registry REST server" "/model-registry proxy: /api/model_registry/v1 and v1alpha3 on 8080/TCP plain HTTP; no in-process auth" "Go (chi, GORM embedmd)"
            catalog = container "Model Catalog server" "/model-registry catalog: plugin-based catalogs, pglock leader election, ingestion on leader only; 8080/TCP plain HTTP" "Go"
            uploadJob = container "Async Upload Job" "Copies models S3/OCI/URI to S3 or OCI ModelCar, registers them, optionally signs" "Python 3.12 Kubernetes Job"
            isvcCtrl = container "InferenceService controller library" "Syncs KServe InferenceService serving state into the registry; embedded in model-registry-operator" "Go controller-runtime"
            registryDb = container "Registry Database" "Per-instance metadata store" "MySQL 8.x / PostgreSQL" "Database"
            catalogDb = container "model-catalog-postgres" "Catalog store and leader lock" "PostgreSQL 17.x" "Database"
        }

        operator = softwareSystem "model-registry-operator" "Deploys registry/catalog, fronts them with kube-rbac-proxy/Gateway, runs ISVC sync" "Internal RHOAI"
        dashboard = softwareSystem "odh-dashboard (model-registry module)" "UI and BFF for registry and catalog; launches upload Jobs" "Internal RHOAI"
        kserve = softwareSystem "KServe" "InferenceService serving platform" "Internal RHOAI"
        perfData = softwareSystem "odh-model-performance-data" "Init container image with benchmark data" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API" "Cluster API server" "External"
        hf = softwareSystem "Hugging Face Hub" "Model catalog source" "External"
        git = softwareSystem "Git remotes" "Skill catalog sources" "External"
        s3 = softwareSystem "S3 Storage" "Model artifact storage" "External"
        oci = softwareSystem "OCI Registries" "ModelCar image storage" "External"
        sigstore = softwareSystem "Sigstore" "Fulcio/Rekor/TUF signing services" "External"

        dataScientist -> dashboard "Uses" "HTTPS/443"
        admin -> operator "Creates ModelRegistry CRs"
        dashboard -> proxy "Registry REST via operator auth proxy" "HTTPS/8443 -> HTTP/8080"
        dashboard -> catalog "Catalog REST via operator proxy" "HTTP/8080"
        dashboard -> k8s "Creates Job, Secret, ConfigMap" "HTTPS/6443"
        k8s -> uploadJob "Schedules"
        operator -> proxy "Deploys"
        operator -> catalog "Deploys"
        operator -> isvcCtrl "Embeds"
        perfData -> catalog "Seeds /shared-data/performance"

        proxy -> registryDb "Reads/writes metadata" "DB wire 3306/5432, optional TLS"
        catalog -> catalogDb "Reads/writes catalog, advisory lock" "PostgreSQL/5432"
        catalog -> hf "Ingests models" "HTTPS/443"
        catalog -> git "Clones skill repos" "https/http/git"
        uploadJob -> s3 "Downloads/uploads models" "HTTPS/443"
        uploadJob -> oci "Pulls/pushes ModelCar" "HTTPS/443"
        uploadJob -> sigstore "Signs model and image" "HTTPS/443"
        uploadJob -> proxy "Registers model" "HTTPS/443, bearer token"
        isvcCtrl -> k8s "Watches/patches InferenceServices" "HTTPS/6443"
        isvcCtrl -> proxy "Syncs serving state" "HTTPS/443 or HTTP/8080"
        isvcCtrl -> kserve "Watches InferenceService CRs"
    }

    views {
        systemContext modelRegistry "SystemContext" {
            include *
            autoLayout
        }

        container modelRegistry "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Database" {
                shape Cylinder
                background #e8e8e8
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #000000
            }
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
        }
    }
}
