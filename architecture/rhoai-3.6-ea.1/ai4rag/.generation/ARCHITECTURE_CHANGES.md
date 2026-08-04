# Architecture Changes: ai4rag

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | OGX Inference Service | * | <empty> | <empty> | ai4rag uses ogx-client SDK for embeddings, chat completions, and vector store operations against the OGX inference platform | ai4rag/components/utils/ogx_client.py:39, ai4rag/rag/embedding/ogx.py:31, ai4rag/rag/foundation_models/ogx.py:25, ai4rag/rag/vector_store/ogx.py:14, pyproject.toml:36 |
| add | authentication | S3-compatible storage :: All | * | <empty> | <empty> | S3 access authenticated via AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables through boto3 SDK | ai4rag/components/utils/s3.py:10-11, ai4rag/components/data/text_extraction.py:242-244 |
| add | authentication | OGX Inference API :: All | * | <empty> | <empty> | OGX client authenticated via API key passed at construction; includes SSL verify=False fallback | ai4rag/components/utils/ogx_client.py:39-68 |
