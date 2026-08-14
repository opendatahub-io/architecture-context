# Architecture Changes: pipelines-components

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | CodeFlare SDK | * | <empty> | <empty> | CodeFlare SDK is used for distributed RayJob submission in parse_and_chunk component | components/data_processing/parse_and_chunk/component.py:576 |
| add | authentication | Kubernetes API :: All | * | <empty> | <empty> | Pipeline components authenticate to Kubernetes API using in-cluster ServiceAccount tokens via load_incluster_config | components/data_processing/parse_and_chunk/component.py:572, pipelines/training/finetuning_evalhub/sft_minimal/pipeline.py:91-92 |
| add | authentication | S3-compatible storage :: All | * | <empty> | <empty> | S3 access authenticated via AWS credential environment variables injected into pipeline step containers | components/data_processing/automl/tabular_data_loader/component.py:90, components/data_processing/dataset_download/component.py:48 |
