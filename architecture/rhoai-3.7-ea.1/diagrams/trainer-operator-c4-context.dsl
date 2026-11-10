workspace "trainer-operator" "RHOAI 3.7-ea.1 Trainer module controller" {
    model {
        dataScientist = person "Data Scientist" "Creates TrainJobs via Dashboard, SDK or kubectl"
        clusterAdmin = person "Platform Administrator" "Enables the Trainer component via the DataScienceCluster"

        trainerOperator = softwareSystem "trainer-operator" "Module operator: reconciles the singleton Trainer CR and deploys the Kubeflow Trainer v2 control plane, runtimes and ImageStreams" {
            manager = container "manager" "controller-runtime operator; metrics 8443/TCP HTTPS (TokenReview + SAR), probes 8081/TCP" "Go 1.26"
            reconciler = container "Trainer reconciler" "Action chain: dependencies, namespace, releases, render, SSA deploy, status, strip finalizers, GC" "odh-platform-utilities framework"
            tlsWatcher = container "TLS profile resolver/watcher" "Resolves APIServer TLS profile; injects operand tls config; restarts on change" "Go library"
            templates = container "Baked manifest templates" "/opt/manifests-template, /opt/runtimes-template, /opt/imagestreams-template rendered in emptyDir" "Kustomize"
        }

        rhods = softwareSystem "rhods-operator" "Platform operator: creates Trainer default-trainer, injects APPLICATIONS_NAMESPACE / RELATED_IMAGE_*, publishes odh-trainer-config" "Internal RHOAI"
        kubeflowTrainer = softwareSystem "Kubeflow Trainer controller" "Operand v2.3.0: reconciles TrainJob, TrainingRuntime, ClusterTrainingRuntime, OptimizationJob; webhooks 9443, metrics 8443, status 10443" "Internal RHOAI"
        k8s = softwareSystem "Kubernetes API server" "All reconciliation, SSA, discovery" "External"
        openshiftConfig = softwareSystem "OpenShift config API" "APIServer TLS profile, ClusterVersion" "External"
        jobset = softwareSystem "Red Hat JobSet Operator" "Provides JobSet CRD; JobSetOperator cluster health gates reconcile" "External"
        olm = softwareSystem "OLM" "operatorconditions / clusterextensions used to detect jobset-operator" "External"
        prometheus = softwareSystem "Prometheus / prometheus-operator" "Scrapes metrics; ServiceMonitor and PrometheusRule CRDs" "External"
        serviceCa = softwareSystem "OpenShift service-ca" "Issues trainer-operator-metrics-tls" "External"
        imageStreams = softwareSystem "OpenShift Image Streams" "training-hub universal workbench ImageStreams" "External"

        clusterAdmin -> rhods "Enables Trainer component"
        rhods -> trainerOperator "Creates Trainer CR, injects env, publishes ConfigMap" "HTTPS/6443 via API"
        dataScientist -> kubeflowTrainer "Creates TrainJobs (via Kubernetes API)" "HTTPS/6443"

        manager -> reconciler "Runs"
        manager -> tlsWatcher "Runs"
        reconciler -> templates "Renders"
        tlsWatcher -> reconciler "Provides operand TLS config"

        reconciler -> k8s "Watch, SSA apply, status, GC" "HTTPS/6443 TLS 1.2+, SA token"
        trainerOperator -> kubeflowTrainer "Deploys and configures (SSA)" "HTTPS/6443"
        reconciler -> jobset "Checks JobSetOperator cluster + jobsets CRD" "HTTPS/6443"
        reconciler -> olm "Lists operatorconditions / clusterextensions" "HTTPS/6443"
        tlsWatcher -> openshiftConfig "Gets/watches APIServer TLS profile" "HTTPS/6443"
        reconciler -> prometheus "Applies ServiceMonitor, PrometheusRule" "HTTPS/6443"
        reconciler -> imageStreams "CRUD ImageStreams (OpenShift only)" "HTTPS/6443"
        serviceCa -> manager "Issues metrics serving cert"
        prometheus -> manager "Scrapes /metrics" "HTTPS/8443 Bearer + SAR"
        prometheus -> kubeflowTrainer "Scrapes /metrics" "HTTPS/8443 Bearer"
        kubeflowTrainer -> jobset "Creates JobSets" "HTTPS/6443"
    }

    views {
        systemContext trainerOperator "SystemContext" {
            include *
            autoLayout
        }

        container trainerOperator "Containers" {
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
                background #6aa9f0
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
