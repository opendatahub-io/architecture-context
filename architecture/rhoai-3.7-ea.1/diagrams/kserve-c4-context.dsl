workspace "KServe (RHOAI 3.7-ea.1)" "C4 model generated from architecture/rhoai-3.7-ea.1/kserve.md" {

    model {
        dataScientist = person "Data Scientist" "Deploys InferenceService / LLMInferenceService / InferenceGraph CRs"
        apiClient = person "Inference Client" "Calls model endpoints through the platform Gateway"

        kserve = softwareSystem "KServe" "RHOAI model-serving control plane and data-plane runtimes" {
            module = container "kserve-module-controller" "Reconciles Kserve platform CR; renders /opt/manifests-template and server-side-applies the serving stack" "Go controller-runtime"
            controller = container "kserve-controller-manager" "Reconciles ISVC, InferenceGraph, TrainedModel, ServingRuntimes; hosts admission webhooks and pod mutator (443->9443)" "Go controller-runtime"
            llmisvc = container "llmisvc-controller-manager" "Reconciles LLMInferenceService/Config; InferencePool, HTTPRoute, LWS, DisaggregatedSet; webhooks and /convert" "Go controller-runtime"
            localmodel = container "localmodel-controller + node agent" "Model cache: LocalModelCache CRs, per-node download Jobs into PV/PVC" "Go controller-runtime / DaemonSet"
            router = container "InferenceGraph router" "Executes Sequence/Switch/Ensemble/Splitter graphs; TokenReview + SAR auth" "Go HTTP 8080"
            agent = container "agent / qpext" "Injected sidecars: logging, batching, model pulling (9081); metrics aggregation (9088)" "Go sidecar"
            storageInit = container "storage-initializer" "Init container downloading models; kserve-decrypt for JWE models" "Python 3.12"
            modelServer = container "Model servers" "KServe ModelServer (REST 8080 / gRPC 8081), autogluonserver; vLLM/OVMS/MLServer via ClusterServingRuntimes" "Python / runtime images"
            kubeRbacProxy = container "kube-rbac-proxy" "TLS + SAR for controller metrics (8443)" "Sidecar"
        }

        rhodsOperator = softwareSystem "rhods-operator" "Creates Kserve default-kserve and consumes its status" "Internal RHOAI"
        odhModelController = softwareSystem "odh-model-controller" "Routes, Kuadrant auth, NIM, runtime templates (deployed by kserve-module)" "Internal RHOAI"
        llmd = softwareSystem "llm-d router / EPP" "Inference scheduler and P/D routing sidecar" "Internal RHOAI"
        modelExpress = softwareSystem "ModelExpress / WVA" "Optional; Removed by default" "Internal RHOAI"
        dashboard = softwareSystem "ODH Dashboard" "UI for model deployment" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes / OpenShift API" "API server, APIServer TLS profile, SCC, Routes" "External"
        gateway = softwareSystem "Gateway API / OSSM + Kuadrant" "Platform Gateway, HTTPRoute, AuthPolicy, TelemetryPolicy" "External"
        gie = softwareSystem "Gateway API Inference Extension" "InferencePool / InferenceObjective" "External"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node LLM workloads" "External"
        autoscale = softwareSystem "KEDA / HPA / Knative" "Autoscaling and optional Serverless mode" "External"
        certs = softwareSystem "cert-manager / OpenShift service-CA" "Webhook and workload certificates" "External"
        prometheus = softwareSystem "Prometheus / Perses" "Metrics scraping and dashboards" "External"
        storage = softwareSystem "Object storage" "S3 / GCS / Azure / HF / ModelScope / HDFS / OCI" "External"
        kbs = softwareSystem "CoCo CDH / Trustee KBS" "Confidential model decryption keys" "External"

        dataScientist -> dashboard "Deploys models via"
        dataScientist -> k8s "Creates ISVC / LLMISVC / InferenceGraph" "HTTPS/6443"
        dashboard -> k8s "Creates serving CRs" "HTTPS/6443"
        apiClient -> gateway "Inference requests" "HTTPS/443"
        gateway -> modelServer "Forwards to predictor" "HTTP/h2c 8080"
        gateway -> llmd "ext-proc endpoint picking" "gRPC TLS"
        gateway -> router "Forwards graph requests" "HTTP(S) 8080"
        router -> modelServer "Calls graph nodes" "HTTP 8080"
        router -> k8s "TokenReview + SubjectAccessReview" "HTTPS/6443"

        rhodsOperator -> module "Creates Kserve default-kserve" "HTTPS/6443"
        module -> k8s "SSA CRDs, Deployments, webhooks, RBAC, presets" "HTTPS/6443"
        module -> controller "Deploys"
        module -> llmisvc "Deploys"
        module -> localmodel "Deploys when modelCache enabled"
        module -> odhModelController "Deploys"
        module -> modelExpress "Deploys if Managed"
        module -> certs "Manages Certificates / Issuers"
        module -> gateway "Creates Kuadrant TelemetryPolicy"
        controller -> k8s "Reconciles workloads; webhook callbacks" "HTTPS/6443, 443->9443"
        controller -> gateway "Creates HTTPRoute / Route / Ingress / VirtualService"
        controller -> autoscale "Creates HPA / ScaledObject / Knative Service"
        controller -> agent "Injects via /mutate-pods"
        controller -> storageInit "Injects via /mutate-pods"
        llmisvc -> k8s "Reconciles LLM workloads" "HTTPS/6443"
        llmisvc -> gie "Creates InferencePool / InferenceObjective"
        llmisvc -> lws "Creates LeaderWorkerSets"
        llmisvc -> llmd "Deploys EPP scheduler"
        localmodel -> storage "Downloads cached models" "HTTPS/443"
        storageInit -> storage "Downloads model artifacts" "HTTPS/443"
        storageInit -> kbs "Fetches decryption keys" "HTTP 127.0.0.1:8006"
        prometheus -> kubeRbacProxy "Scrapes controller metrics" "HTTPS/8443"
        odhModelController -> k8s "Watches ISVC / LLMISVC" "HTTPS/6443"
    }

    views {
        systemContext kserve "SystemContext" {
            include *
            autoLayout
        }

        container kserve "Containers" {
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
                background #1168bd
                color #ffffff
            }
            element "Container" {
                background #4a90e2
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
