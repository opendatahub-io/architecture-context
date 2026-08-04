# Architecture Changes: pipelines-components

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | internal_dependencies | CodeFlare SDK | * | <empty> | <empty> | Multiple pipeline components import codeflare_sdk for distributed Ray job submission via ManagedClusterConfig and RayJob | components/data_processing/parse_and_chunk/component.py:576 |
