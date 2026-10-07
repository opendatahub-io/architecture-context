workspace {
    model {
        ciEngineer = person "CI Engineer / Developer" "Runs integration tests against RHOAI clusters"

        autoxCI = softwareSystem "autox-ci" "End-to-end integration test suite and benchmark orchestration framework for AutoX components (AutoRAG, AutoML)" {
            autoxTests = container "autox_tests" "Pytest-based functional tests for AutoRAG and AutoML pipelines" "Python / pytest"
            autoxBenchmarks = container "autox_benchmarks" "Benchmark orchestration for AutoRAG quality evaluation" "Python / CLI"
            runTestsSh = container "run_tests.sh" "Test runner wrapper with env setup, suite selection, uv management" "Bash"
            testLib = container "Shared Libraries" "KFP client, K8s client, S3 client, DSPA support, settings" "Python"
        }

        openshiftAPI = softwareSystem "OpenShift API Server" "Kubernetes API with OpenShift extensions" "External"
        dspo = softwareSystem "Data Science Pipelines Operator" "Manages DataSciencePipelinesApplication CRs" "Internal RHOAI"
        kfp = softwareSystem "Kubeflow Pipelines" "Pipeline execution engine with REST API" "Internal RHOAI"
        kserve = softwareSystem "KServe" "Model serving platform with InferenceService CRD" "Internal RHOAI"
        s3Storage = softwareSystem "S3-Compatible Storage" "Object storage for datasets, artifacts, model weights" "External"
        huggingFace = softwareSystem "HuggingFace Hub" "Public ML dataset and model repository" "External"
        rhelPyPI = softwareSystem "RHEL AI PyPI" "Red Hat-published Python packages (AutoGluon)" "External"
        odhDashboard = softwareSystem "OpenShift AI Dashboard" "Web UI for RHOAI management" "Internal RHOAI"
        odhModelCtrl = softwareSystem "odh-model-controller" "Data Connection annotation conventions for KServe" "Internal RHOAI"

        ciEngineer -> autoxCI "Runs tests and benchmarks"
        ciEngineer -> runTestsSh "Executes via CLI" "Bash"

        runTestsSh -> autoxTests "Invokes pytest" "Python subprocess"
        autoxTests -> testLib "Uses shared utilities"
        autoxBenchmarks -> testLib "Uses shared utilities"

        autoxTests -> openshiftAPI "Creates namespaces, secrets, CRs" "HTTPS/6443, Bearer token"
        autoxTests -> kfp "Submits and monitors pipeline runs" "HTTPS/443, Bearer token"
        autoxTests -> s3Storage "Uploads test data, reads artifacts" "HTTPS, AWS Sig V4"
        autoxTests -> kserve "Deploys and scores models" "HTTPS/443, Bearer token"

        autoxTests -> dspo "Creates DataSciencePipelinesApplication CR" "via Kubernetes API"
        autoxTests -> odhModelCtrl "Follows Data Connection annotation patterns" "Label convention"

        autoxBenchmarks -> huggingFace "Downloads benchmark datasets" "HTTPS/443"
        autoxBenchmarks -> s3Storage "Uploads benchmark data, reads results" "HTTPS, AWS Sig V4"
        autoxBenchmarks -> kfp "Submits benchmark pipeline runs" "HTTPS/443, Bearer token"

        autoxCI -> rhelPyPI "Installs AutoGluon packages" "HTTPS/443"
    }

    views {
        systemContext autoxCI "SystemContext" {
            include *
            autoLayout
        }

        container autoxCI "Containers" {
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
                shape Person
                background #4a90e2
                color #ffffff
            }
            element "Software System" {
                background #4a90e2
                color #ffffff
            }
            element "Container" {
                background #438dd5
                color #ffffff
            }
        }
    }
}
