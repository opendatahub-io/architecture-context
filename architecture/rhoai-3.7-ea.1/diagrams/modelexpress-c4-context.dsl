workspace "ModelExpress" "Model-weight distribution control plane for RHOAI 3.7.0-ea.1" {
    model {
        user = person "Data Scientist / Platform Admin" "Creates ModelExpressServer CRs in a namespace"

        modelexpress = softwareSystem "ModelExpress" "Model-weight distribution control plane. Brokers model-cache and P2P (NIXL/RDMA) source metadata so inference replicas avoid cold pulls." {
            operator = container "modelexpress-operator-openshift" "Reconciles ModelExpressServer into Deployment, Service, PVC, NetworkPolicy, SA/Role/RoleBinding and optional auth-delegator CRB. Health 8081, TLS metrics 8443." "Rust / kube-rs" "Operator"
            server = container "modelexpress-server" "gRPC coordinator: Model, P2P, Refit, RefitCollective, Api, Health services on 8001; Prometheus /metrics on 9401. Optional TokenReview auth and tenant isolation." "Rust / tonic + axum" "Service"
            cache = container "Model Cache PVC" "Server-managed shared disk cache with eviction" "PersistentVolumeClaim" "Storage"
            client = container "ModelExpress client library" "Engine loaders (vLLM, SGLang, TRT-LLM), NIXL transfer, RL refit. Runs inside inference images; not shipped as a RHOAI image." "Python / Rust / Go stubs" "Client"
        }

        k8s = softwareSystem "Kubernetes API Server" "CRD storage, TokenReview, SubjectAccessReview" "External"
        ocpConfig = softwareSystem "OpenShift Config API" "apiservers.config.openshift.io cluster TLS profile" "Internal Platform"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues operator metrics and optional server gRPC TLS certs" "Internal Platform"
        monitoring = softwareSystem "OpenShift Monitoring" "Prometheus scraping via ServiceMonitor" "Internal Platform"
        odhOperator = softwareSystem "opendatahub-operator / rhods-operator" "Installs the ModelExpress operator via kustomize overlays/odh" "Internal ODH"
        inference = softwareSystem "Inference Runtimes" "vLLM, SGLang, TRT-LLM, NVIDIA Dynamo, llm-d, KServe-managed pods" "Internal ODH"
        redis = softwareSystem "Redis" "Optional user-supplied metadata backend" "External"
        hf = softwareSystem "HuggingFace Hub" "Model source" "External"
        ngc = softwareSystem "NVIDIA NGC" "Model source" "External"
        s3 = softwareSystem "S3-compatible Storage" "Model source" "External"

        user -> k8s "Creates ModelExpressServer" "HTTPS/443"
        odhOperator -> operator "Deploys" "Kustomize manifests"
        operator -> k8s "Watches CRs, server-side applies children, patches status" "HTTPS/443, SA token"
        operator -> ocpConfig "Reads cluster TLS profile" "HTTPS/443"
        operator -> server "Deploys and configures" "Deployment via SSA"
        serviceCa -> operator "Provides metrics TLS cert"
        serviceCa -> server "Provides optional gRPC TLS cert"
        monitoring -> operator "Scrapes /metrics" "HTTPS/8443, Bearer TokenReview + SAR"
        monitoring -> server "Scrapes /metrics" "HTTP/9401, no auth"

        inference -> client "Embeds"
        client -> server "Model cache and P2P source coordination" "gRPC/8001, optional TLS, optional SA token"
        client -> client "Peer weight transfer" "NIXL RDMA, no TLS"
        server -> k8s "TokenReview; ModelMetadata, ModelCacheEntry, ConfigMaps" "HTTPS/443"
        server -> redis "Metadata backend" "RESP/6379, optional TLS"
        server -> cache "Stores downloaded models" "Filesystem"
        server -> hf "Downloads models" "HTTPS/443, HF_TOKEN"
        server -> ngc "Downloads models" "HTTPS/443, NGC API key"
        server -> s3 "Downloads models" "HTTPS/443, AWS SigV4"
    }

    views {
        systemContext modelexpress "SystemContext" {
            include *
            autoLayout
        }

        container modelexpress "Containers" {
            include *
            autoLayout
        }

        styles {
            element "Person" {
                shape Person
                background #08427b
                color #ffffff
            }
            element "Software System" {
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Storage" {
                shape Cylinder
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Internal Platform" {
                background #b8e986
                color #000000
            }
        }
    }
}
