workspace {
    model {
        user = person "Data Scientist / AI Engineer" "Requests Garak red-teaming evaluations through eval-hub"

        garak = softwareSystem "llama-stack-provider-trustyai-garak" "eval-hub FrameworkAdapter image that runs NVIDIA Garak LLM red-teaming scans as Kubernetes Jobs or Kubeflow Pipelines" {
            adapter = container "GarakAdapter" "Loads JobSpec, resolves profile/config, runs scan or submits/polls KFP, parses results, reports to eval-hub" "Python, eval-hub-sdk FrameworkAdapter"
            kfpAdapter = container "GarakKFPAdapter" "Entrypoint that forces KFP execution mode; pod acts as orchestrator" "Python"
            runner = container "Garak Runner" "Runs garak --config subprocess with process group and timeout handling" "Python subprocess + garak 0.17.0+rhaiv.4"
            pipeline = container "evalhub-garak-scan Pipeline" "validate, resolve_taxonomy, sdg_generate, prepare_prompts, garak_scan, write_kfp_outputs" "Kubeflow Pipeline (same image)"
            results = container "Result Utils" "Parses Garak JSONL/AVID, computes TBSA, renders HTML reports" "Python + Jinja2/Vega"
        }

        evalHub = softwareSystem "eval-hub" "Evaluation platform; launches Job, provides JobSpec and sidecar callback/auth proxy" "Internal ODH"
        dsp = softwareSystem "Data Science Pipelines" "Kubeflow Pipelines API and runtime" "Internal ODH"
        operator = softwareSystem "trustyai-service-operator" "Supplies garak-provider-image via trustyai-service-operator-config ConfigMap" "Internal ODH"
        modelServing = softwareSystem "Model Serving" "Target, attacker, judge, evaluator and SDG models (KServe/vLLM or any OpenAI-compatible endpoint)" "Internal ODH"
        mlflow = softwareSystem "MLflow" "Optional result persistence via eval-hub SDK" "Internal ODH"
        k8s = softwareSystem "Kubernetes API" "Secret and ConfigMap reads" "External"
        s3 = softwareSystem "S3-compatible Storage" "Pipeline artifacts, inputs, results (OpenShift AI Data Connection)" "External"
        oci = softwareSystem "OCI Registry" "Optional scan artifact persistence" "External"
        hf = softwareSystem "Hugging Face Hub / NLTK" "Runtime model and corpus downloads by some probes" "External"

        user -> evalHub "Submits evaluation job"
        evalHub -> garak "Launches Job with JobSpec /meta/job.json"
        garak -> evalHub "report_status / report_results via sidecar" "HTTP/8080 localhost"
        garak -> dsp "Submits and polls pipeline runs" "HTTPS/443, Bearer SA token"
        garak -> k8s "Reads Data Connection Secret and image ConfigMap" "HTTPS/443"
        operator -> garak "Provides KFP component image digest" "ConfigMap"
        garak -> modelServing "Sends adversarial prompts" "HTTP(S) OpenAI-compatible, Bearer API key"
        garak -> s3 "Exchanges artifacts and results" "HTTPS/443, AWS keys"
        garak -> mlflow "Saves results (optional)" "HTTPS/443 via SDK"
        garak -> oci "Pushes artifacts (optional)" "HTTPS/443 via SDK"
        garak -> hf "Downloads models/corpora" "HTTPS/443"

        evalHub -> adapter "Launches" "Kubernetes Job"
        kfpAdapter -> adapter "Subclasses"
        adapter -> runner "Simple mode: runs garak" "Local process"
        adapter -> results "Parses reports"
        adapter -> dsp "KFP mode: create/poll run" "HTTPS/443"
        dsp -> pipeline "Executes"
        runner -> modelServing "Adversarial prompts" "HTTP(S)"
        pipeline -> modelServing "SDG and scan requests" "HTTPS"
        pipeline -> s3 "Reads inputs, writes reports" "HTTPS/443"
        adapter -> s3 "Downloads results" "HTTPS/443"
        adapter -> k8s "Reads Secret / ConfigMap" "HTTPS/443"
        adapter -> evalHub "Callbacks" "HTTP/8080 localhost"
    }

    views {
        systemContext garak "SystemContext" {
            include *
            autoLayout
        }

        container garak "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal ODH" {
                background #7ed321
            }
        }
    }
}
