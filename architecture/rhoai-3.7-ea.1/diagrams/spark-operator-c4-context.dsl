workspace "Spark Operator - RHOAI 3.7-ea.1" "C4 context for spark-operator (red-hat-data-services/spark-operator @ fef8c2a)" {
    model {
        dataScientist = person "Data Scientist" "Submits Spark batch jobs and interactive Spark Connect sessions"
        platformAdmin = person "Platform Admin" "Enables Spark via the SparkOperator CR and sets jobNamespaces"

        sparkOperator = softwareSystem "Spark Operator" "Runs Apache Spark workloads on OpenShift AI via SparkApplication, ScheduledSparkApplication and SparkConnect CRs" {
            moduleController = container "spark-operator-module-controller-manager" "Reconciles the cluster-scoped SparkOperator CR; renders and applies the operator kustomize overlay; reports platform status" "Go, controller-runtime, odh-platform-utilities"
            controller = container "spark-operator-controller" "Reconciles SparkApplication, ScheduledSparkApplication and SparkConnect; runs spark-submit in-process; manages UI Services, PDBs, operand NetworkPolicies" "Go + OpenJDK 17 + PySpark 4.0.4"
            webhook = container "spark-operator-webhook" "Mutating/validating webhooks for Spark CRs and pods; CRD conversion; self-signed TLS cert management" "Go, HTTPS 9443"
            webhookSecret = container "spark-operator-webhook-certs" "Self-signed CA and server certificate (RSA-2048, 10-year)" "Kubernetes Secret" "Datastore"
            sparkPods = container "Spark driver/executor pods" "Spark workload pods created via spark-submit; Spark RPC 7078/7079, UI 4040" "Operand"
            sparkConnect = container "SparkConnect server" "Long-running Spark Connect server per SparkConnect CR" "Operand, gRPC 15002"
        }

        odhOperator = softwareSystem "opendatahub-operator" "Deploys the module controller, creates SparkOperator CR, injects env" "Internal ODH"
        workbench = softwareSystem "Workbenches / Kubeflow SDK" "Creates SparkConnect sessions and connects via gRPC" "Internal ODH"
        monitoring = softwareSystem "Platform Monitoring (Prometheus)" "Scrapes operator metrics via PodMonitor" "Internal ODH"
        platformUtils = softwareSystem "odh-platform-utilities" "PlatformObject contract, manifest rendering" "Internal ODH"

        k8sApi = softwareSystem "Kubernetes API Server" "Resource CRUD, watches, leases, admission callbacks" "External"
        ocpConfig = softwareSystem "OpenShift Config API" "apiservers/cluster TLS security profile" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues metrics serving certificates and CA bundle" "External"
        extDeps = softwareSystem "User Dependency Endpoints" "Jars, Python files and data sources referenced by Spark apps" "External"
        batchSched = softwareSystem "Batch Schedulers" "Volcano / YuniKorn / scheduler-plugins (optional, off by default)" "Optional"
        certManager = softwareSystem "cert-manager" "Optional webhook certificates (RBAC granted, not used in RHOAI)" "Optional"
        submitter = softwareSystem "Spark Submitter Service" "Out-of-process spark-submit (RestSubmitter gate, disabled)" "Optional"

        # People
        platformAdmin -> odhOperator "Enables Spark component"
        dataScientist -> k8sApi "Creates SparkApplication / SparkConnect" "HTTPS/6443, user token"
        dataScientist -> workbench "Uses Kubeflow SDK"

        # Platform
        odhOperator -> moduleController "Deploys, creates SparkOperator CR, injects env" "HTTPS/6443"
        moduleController -> k8sApi "Server-side apply of CRDs, RBAC, Deployments, webhook configs, NetworkPolicies, PodMonitors" "HTTPS/6443, SA token"
        moduleController -> platformUtils "Uses"

        # Operator
        k8sApi -> webhook "Admission + conversion callbacks" "HTTPS 443->9443, cluster TLS profile"
        webhook -> webhookSecret "Reads/writes CA and server cert"
        controller -> k8sApi "Watches CRs; creates pods, Services, ConfigMaps, PDBs, NetworkPolicies" "HTTPS/6443, SA token"
        controller -> sparkPods "Submits via spark-submit"
        controller -> sparkConnect "Creates server pod + Service"
        controller -> ocpConfig "Reads TLS profile" "HTTPS/6443"
        webhook -> ocpConfig "Reads TLS profile" "HTTPS/6443"
        controller -> extDeps "Fetches dependencies (allow-all egress)" "any"
        sparkPods -> extDeps "Reads data / dependencies" "any"
        sparkPods -> k8sApi "Driver creates executor pods" "HTTPS/6443, driver SA"
        workbench -> sparkConnect "Spark Connect session" "gRPC/15002, plaintext, no auth"
        workbench -> k8sApi "Creates SparkConnect" "HTTPS/6443, user token"
        monitoring -> controller "Scrapes /metrics" "HTTPS/8080, no auth"
        monitoring -> webhook "Scrapes /metrics" "HTTPS/8080, no auth"
        serviceCa -> controller "Issues metrics certs"
        serviceCa -> webhook "Issues metrics certs"
        controller -> batchSched "PodGroup / scheduler name (optional)"
        webhook -> certManager "Optional certificates (disabled)"
        controller -> submitter "REST submission (disabled)" "HTTPS, optional mTLS"
    }

    views {
        systemContext sparkOperator "SystemContext" {
            include *
            autoLayout
        }

        container sparkOperator "Containers" {
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
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #4a90e2
                color #ffffff
            }
            element "Datastore" {
                shape Cylinder
            }
            element "Operand" {
                background #f5a623
                color #000000
            }
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal ODH" {
                background #7ed321
                color #000000
            }
            element "Optional" {
                background #e8e8e8
                color #000000
                border dashed
            }
        }
    }
}
