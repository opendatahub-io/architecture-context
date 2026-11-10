workspace "llm-d-benchmark" "Benchmarking and validation client for llm-d based serving in RHOAI" {
    model {
        operator = person "Performance Engineer / CI" "Runs llmdbenchmark plan/standup/run/teardown from a workstation or CI runner"

        llmdBenchmark = softwareSystem "llm-d-benchmark" "Client-side CLI and harness image that stands up an llm-d stack, runs repeatable LLM inference benchmarks, and collects Benchmark Report v0.2 results" {
            cli = container "llmdbenchmark CLI" "Orchestrates plan, standup, update, smoketest, run, teardown, experiment and results subcommands" "Python 3.14 console script"
            parser = container "Plan/Render Engine" "Merges defaults, scenario, env and CLI; validates with Pydantic; renders Jinja2 manifests and helmfiles" "Python module"
            executor = container "Step Executor" "Runs numbered steps sequentially or in parallel; shells out to kubectl/oc/helm/helmfile" "Python module"
            resultsStore = container "Results Store" "Push/pull/list results in GCS via SDK or Prism proxy" "Python module"
            telemetry = container "Telemetry" "Optional non-blocking HTTP POST of results with Google OIDC auth" "Python module"
            harness = container "Harness Pod(s)" "Runs inference-perf, vllm-benchmark, guidellm, inferencemax, aiperf, lm-eval or nop against the model endpoint; writes to workload PVC" "Container: ghcr.io/llm-d/llm-d-benchmark:nightly"
            dataAccess = container "Data-access Pod + Service" "Mounts workload PVC at /requests; rsync daemon on 20873/TCP (no auth) for kubectl cp" "Container + ClusterIP Service"
            downloadJob = container "Model Download Job/DaemonSet" "Pre-pulls model weights from Hugging Face into model PVC" "Kubernetes Job"
            discovery = container "llm_d_stack_discovery" "Read-only tracing of an llm-d stack from an OpenAI-compatible URL" "Python 3.11 CLI / K8s Job"
            benchmarkReport = container "benchmark-report" "Benchmark Report v0.2 schemas, validators and converters" "Python library"
        }

        k8s = softwareSystem "Kubernetes / OpenShift API" "Cluster control plane; RBAC enforcement" "Internal Platform"
        llmdStack = softwareSystem "llm-d Inference Stack" "Gateway API / Istio / agentgateway + GAIE EPP + vLLM (modelservice, standalone, kustomize guides, FMA); KServe LLMInferenceService in RHOAI" "Internal Platform"
        helmCharts = softwareSystem "llm-d modelservice / llm-d-infra charts" "Helm charts for the stack under test" "Internal Platform"
        lws = softwareSystem "LeaderWorkerSet" "Multi-node / wide-EP serving" "Internal Platform"
        keda = softwareSystem "KEDA / Workload Variant Autoscaler" "Autoscaling scenarios" "Internal Platform"
        fma = softwareSystem "Fast Model Actuation" "fma.llm-d.ai CRDs" "Internal Platform"
        monitoring = softwareSystem "OpenShift Monitoring / Thanos" "Metrics capture at run end" "Internal Platform"

        hf = softwareSystem "Hugging Face Hub" "Model weights, tokenizers, datasets" "External"
        gcs = softwareSystem "Google Cloud Storage" "Results store" "External"
        prism = softwareSystem "Prism (prism.llm-d.ai)" "llm-d-operated GCS proxy fallback" "External"
        s3 = softwareSystem "Amazon S3" "Results upload" "External"
        telemetryReceiver = softwareSystem "Telemetry Receiver" "Optional results/metadata receiver (e.g. Cloud Run)" "External"

        operator -> cli "Runs subcommands" "CLI"
        cli -> parser "Renders plan"
        cli -> executor "Executes steps"
        cli -> resultsStore "Publishes results"
        cli -> telemetry "Sends telemetry (optional)"
        cli -> benchmarkReport "Builds/validates reports"
        executor -> k8s "Creates namespaces, PVCs, secrets, RBAC, pods, jobs, configmaps" "HTTPS/6443 (TLS verify may be disabled)"
        executor -> helmCharts "helmfile apply" "HTTPS/443"
        executor -> lws "Creates LWS instances" "K8s API"
        executor -> keda "Creates ScaledObject / TriggerAuthentication" "K8s API"
        executor -> fma "Reads CRDs, patches Deployments" "K8s API"
        cli -> dataAccess "kubectl cp results" "HTTPS/SPDY via API exec"
        cli -> monitoring "Thanos query" "HTTPS/443 curl -k, Bearer"
        harness -> llmdStack "Generates OpenAI-compatible load; scrapes EPP /metrics" "HTTP(S)"
        harness -> k8s "Reads pods/logs/services, creates Jobs" "HTTPS/443 SA token"
        harness -> hf "Downloads tokenizers/datasets" "HTTPS/443 HF_TOKEN"
        harness -> dataAccess "Shares workload PVC"
        downloadJob -> hf "Downloads model weights" "HTTPS/443 HF_TOKEN"
        discovery -> k8s "Reads routes, gateways, inferencepools, pods" "HTTPS/443 read-only ClusterRole"
        discovery -> llmdStack "Traces stack configuration"
        resultsStore -> gcs "Push/pull/list" "HTTPS/443 Google ADC"
        resultsStore -> prism "Fallback proxy" "HTTPS/443 no client auth"
        cli -> s3 "aws s3 cp" "HTTPS/443 AWS credentials"
        telemetry -> telemetryReceiver "POST results" "HTTPS/443 Bearer OIDC"
    }

    views {
        systemContext llmdBenchmark "SystemContext" {
            include *
            autoLayout
        }

        container llmdBenchmark "Containers" {
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
            element "External" {
                background #999999
            }
            element "Internal Platform" {
                background #7ed321
            }
        }
    }
}
