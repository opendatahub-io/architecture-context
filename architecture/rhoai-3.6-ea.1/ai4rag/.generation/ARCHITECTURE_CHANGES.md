# Architecture Changes: ai4rag

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | Data Science Pipelines | * | <empty> | <empty> | KFPEventHandler class is designed for use within Kubeflow Pipelines components, establishing runtime dependency on platform pipeline infrastructure | ai4rag/utils/event_handler/event_handler.py:47 |
| add | internal_dependencies | Model Serving (MaaS) | * | <empty> | <empty> | create_maas_client creates OpenAI-compatible client for platform MaaS endpoint; models.py references MaaS serving for discovery and inference | ai4rag/components/utils/maas_client.py:30, ai4rag/search_space/prepare/models.py:29 |
