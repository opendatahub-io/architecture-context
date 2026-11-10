workspace "must-gather (RHOAI 3.7-ea.1)" "C4 context for the odh-must-gather diagnostics image" {
    model {
        admin = person "Cluster Admin" "Runs oc adm must-gather (OCP) or a Kubernetes Job (xKS) to collect diagnostics"
        support = person "Red Hat Support" "Receives the must-gather bundle attached to support cases" "External"

        mustGather = softwareSystem "odh-must-gather" "Ephemeral container image of Bash collection scripts that snapshots RHOAI/RHAII cluster state" {
            gather = container "gather" "Entrypoint: detects distro, resolves namespaces, inspects core namespaces and platform CRs, dispatches collectors" "Bash (collection-scripts/gather.sh)"
            common = container "common.sh" "run_mustgather (oc adm inspect), rhoai_version, collect_helm_releases, get_operator_ns" "Bash library"
            xksUtil = container "xks_util.sh" "detect_k8s_distro, kubectl_inspect, auto_discover_resources (kubectl replacement for oc adm inspect)" "Bash library"
            collectors = container "Component collectors" "20 gather_*.sh scripts listing CR kinds per component" "Bash scripts"
            llmd = container "LLM-D and dependency collectors" "LLM-D, Gateway API, monitoring, cluster-scoped dump, cert-manager, Sail, LWS" "Bash scripts"
            clis = container "CLI tools" "oc, kubectl (ose-cli-rhel9), helm v4.1.4 (Git LFS)" "Binaries"
            outDir = container "must-gather/ directory" "Pod-local output: version file, CR YAML, logs, Helm values" "Filesystem"
        }

        ocCli = softwareSystem "oc adm must-gather" "OpenShift CLI orchestration: temp ns/SA/cluster-admin binding, copy-out" "External"
        kubeApi = softwareSystem "Kubernetes / OpenShift API server" "Source of all collected data; RBAC enforcement" "External"
        olm = softwareSystem "OLM" "Subscription / CSV for operator namespace and version detection" "External"
        registry = softwareSystem "registry.redhat.io" "Hosts odh-must-gather-rhel9 image" "External"
        konflux = softwareSystem "Konflux (konflux-central)" "Hermetic multi-arch build pipeline" "External"

        rhodsOperator = softwareSystem "rhods-operator" "Owns DSCI, DSC, component/service platform CRs" "Internal RHOAI"
        components = softwareSystem "RHOAI components" "KServe, LLM-D, DSP, Workbenches, KubeRay, Kueue, Trainer, Model Registry, Feast, MLflow, TrustyAI, Spark, AI Gateway/MaaS, MCPLO, OGX" "Internal RHOAI"
        rhaiHelm = softwareSystem "RHAII Helm chart" "Helm-based RHAII install (rhai-gitops), cloud manager" "Internal RHOAI"
        deps = softwareSystem "Platform dependencies" "cert-manager, Sail/Istio, LeaderWorkerSet, Kuadrant/Authorino/Limitador, Prometheus Operator" "External"

        admin -> ocCli "Runs with --image=odh-must-gather-rhel9"
        admin -> kubeApi "kubectl apply Job / kubectl cp (xKS)" "HTTPS/443"
        ocCli -> kubeApi "Creates temp ns, SA, cluster-admin binding, pod; copies output" "HTTPS/6443"
        ocCli -> mustGather "Runs /usr/bin/gather"
        mustGather -> kubeApi "get/list/logs/api-resources, Helm Secret reads" "HTTPS/443, SA bearer token"
        mustGather -> olm "Reads rhods-operator Subscription / CSV" "HTTPS/443"
        mustGather -> rhodsOperator "Reads DSCI, DSC, platform CRs (via API)"
        mustGather -> components "Reads component CRs and namespaces (via API)"
        mustGather -> rhaiHelm "helm get values / manifest (via API)"
        mustGather -> deps "Reads dependency CRs and full namespaces incl. Secrets (via API)"
        kubeApi -> registry "Kubelet pulls image" "HTTPS/443, pull secret"
        konflux -> registry "Builds and pushes image" "quay.io/rhoai/odh-must-gather-rhel9"
        admin -> support "Uploads must-gather bundle"

        gather -> common "Sources"
        gather -> xksUtil "Sources"
        gather -> collectors "Dispatches (parallel on OCP)"
        gather -> llmd "Dispatches"
        collectors -> common "run_mustgather"
        llmd -> xksUtil "kubectl_inspect"
        common -> clis "Invokes oc / helm"
        xksUtil -> clis "Invokes kubectl"
        clis -> kubeApi "REST" "HTTPS/443"
        gather -> outDir "Writes"
    }

    views {
        systemContext mustGather "SystemContext" {
            include *
            autoLayout
        }

        container mustGather "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
        }
    }
}
