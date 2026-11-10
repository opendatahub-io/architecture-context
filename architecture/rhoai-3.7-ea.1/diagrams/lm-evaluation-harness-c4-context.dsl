workspace {
    model {
        user = person "Data Scientist" "Requests model evaluations via LMEvalJob or EvalHub"

        lmeval = softwareSystem "lm-evaluation-harness" "Batch language model benchmark evaluation runtime (odh-ta-lmes-job-rhel9)" {
            cli = container "lm_eval CLI" "Classic CLI entrypoint (python -m lm_eval) used by TrustyAI LMEvalJob runs" "Python"
            adapter = container "EvalHub Adapter (main.py)" "FrameworkAdapter: reads /meta/job.json, runs simple_evaluate via local-completions, reports status/results" "Python"
            library = container "lm_eval package" "Task registry, model backends, evaluator, filters, metrics, caching" "Python library"
            ociScript = container "scripts/oci.py" "Packages results as OCI artifact with olot + skopeo" "Python"
            s3Script = container "scripts/s3_downloader.py" "Downloads models/datasets from S3-compatible storage into hf_home" "Python / boto3"
        }

        trustyai = softwareSystem "trustyai-service-operator" "LMEvalJob controller that launches CLI evaluation pods" "Internal RHOAI"
        evalhub = softwareSystem "EvalHub" "Schedules adapter jobs and receives status/results callbacks" "Internal RHOAI"
        mlflow = softwareSystem "MLflow" "Evaluation results persistence" "Internal RHOAI"
        modelServing = softwareSystem "Model Serving" "OpenAI-compatible inference endpoint (KServe / vLLM / llm-d)" "Internal RHOAI"
        aipcc = softwareSystem "AIPCC Base Images" "CUDA 13.0 / CPU torch 2.13 runtime images" "Internal RHOAI"
        hf = softwareSystem "Hugging Face Hub" "Datasets, tokenizers, metrics" "External"
        registry = softwareSystem "OCI Registry" "Stores result artifacts" "External"
        s3 = softwareSystem "S3-compatible Storage" "Model and dataset storage" "External"
        llmApis = softwareSystem "Third-party LLM APIs" "OpenAI, Anthropic, watsonx.ai, TextSynth" "External"

        user -> trustyai "Creates LMEvalJob"
        user -> evalhub "Submits evaluation job"
        trustyai -> cli "Launches pod: python -m lm_eval"
        evalhub -> adapter "Launches pod, mounts /meta/job.json and /test_data"
        cli -> library "Uses"
        adapter -> library "simple_evaluate (local-completions)"
        adapter -> ociScript "Optional OCI export"
        library -> modelServing "POST /v1/completions, Bearer token" "HTTP/HTTPS"
        library -> hf "Downloads datasets/tokenizers/metrics (skipped offline)" "HTTPS/443"
        library -> llmApis "Optional CLI model backends" "HTTPS/443"
        adapter -> evalhub "Status and results callbacks" "HTTP/HTTPS"
        adapter -> mlflow "Saves results via eval-hub-sdk" "HTTP/HTTPS"
        ociScript -> registry "Pushes results artifact" "HTTPS/443"
        s3Script -> s3 "Downloads models/datasets" "HTTPS"
        lmeval -> aipcc "Built on" "Container base image"
    }

    views {
        systemContext lmeval "SystemContext" {
            include *
            autoLayout
        }

        container lmeval "Containers" {
            include *
            autoLayout
        }

        styles {
            element "External" {
                background #999999
            }
            element "Internal RHOAI" {
                background #7ed321
            }
            element "Person" {
                shape person
            }
        }
    }
}
