workspace {
    model {
        dataScientist = person "Data Scientist" "Submits distributed training jobs via TrainJob CRs"
        platformAdmin = person "Platform Admin" "Manages RHOAI platform components"

        trainerOperator = softwareSystem "Trainer Operator" "Module operator that deploys and manages Kubeflow Trainer V2 controller and ClusterTrainingRuntimes on RHOAI clusters" {
            operatorController = container "trainer-operator" "Reconciles Trainer CR to deploy all Trainer resources via kustomize manifest rendering pipeline" "Go Operator (controller-runtime)"
            kubeflowTrainerCtrl = container "kubeflow-trainer-controller-manager" "Upstream Kubeflow Trainer V2 controller; manages TrainJob/TrainingRuntime/ClusterTrainingRuntime lifecycle" "Go Controller (Deployment)"
            webhookServer = container "Validating Webhook" "Validates TrainJob, ClusterTrainingRuntime, and TrainingRuntime CRs on CREATE/UPDATE" "Webhook Server (9443/TCP)"
            manifestPipeline = container "Manifest Rendering Pipeline" "Loads templates from /opt/manifests-template/, renders kustomize with RHOAI overlay and RELATED_IMAGE param substitution" "Kustomize"
        }

        rhodsOperator = softwareSystem "rhods-operator / opendatahub-operator" "Platform operator that manages RHOAI component lifecycle" "Internal RHOAI"
        jobSetOperator = softwareSystem "JobSet Operator" "Provides JobSet CRD for distributed job orchestration; installed via OLM" "External"
        kubernetesAPI = softwareSystem "Kubernetes API Server" "Cluster API server for all resource CRUD operations" "External"
        prometheus = softwareSystem "Prometheus / OpenShift Monitoring" "Metrics collection and alerting via PodMonitor" "External"
        openshiftImageRegistry = softwareSystem "OpenShift Image Registry" "Hosts ImageStreams for training runtime images (CUDA, ROCm, CPU)" "External"
        odhDashboard = softwareSystem "ODH Dashboard" "User-facing dashboard for submitting training jobs" "Internal RHOAI"

        # Relationships - Platform Admin
        platformAdmin -> rhodsOperator "Configures RHOAI platform"

        # Relationships - Platform Operator
        rhodsOperator -> trainerOperator "Creates Trainer CR 'default-trainer'" "CRD Watch / HTTPS 443"

        # Relationships - Operator internals
        operatorController -> manifestPipeline "Renders manifests"
        operatorController -> kubeflowTrainerCtrl "Deploys and manages" "Server-side Apply / HTTPS 443"
        operatorController -> webhookServer "Deploys ValidatingWebhookConfiguration"
        kubeflowTrainerCtrl -> webhookServer "Serves validation requests" "HTTPS 9443"

        # Relationships - Data Scientist
        dataScientist -> odhDashboard "Submits training jobs via UI"
        dataScientist -> kubernetesAPI "Creates TrainJob CRs via kubectl" "HTTPS 443"

        # Relationships - External dependencies
        operatorController -> jobSetOperator "Validates dependency health (OLM subscription, CR conditions, CRD)" "HTTPS 443"
        operatorController -> kubernetesAPI "Server-side apply: CRDs, Deployments, RBAC, Runtimes, ImageStreams" "HTTPS 443"
        kubeflowTrainerCtrl -> kubernetesAPI "CRUD: TrainJobs, JobSets, ConfigMaps, Secrets, NetworkPolicies" "HTTPS 443"
        kubeflowTrainerCtrl -> jobSetOperator "Creates JobSets for distributed training" "HTTPS 443 (via K8s API)"

        # Relationships - Monitoring
        prometheus -> trainerOperator "Scrapes metrics via PodMonitor" "HTTP 8080 / HTTPS 8443"

        # Relationships - Dashboard
        odhDashboard -> kubernetesAPI "Creates TrainJob CRs on behalf of users" "HTTPS 443"
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
            element "External" {
                background #999999
                color #ffffff
            }
            element "Internal RHOAI" {
                background #7ed321
                color #ffffff
            }
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
                background #438dd5
                color #ffffff
            }
        }
    }
}
