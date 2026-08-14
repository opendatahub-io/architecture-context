# Architecture Changes: spark-operator

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|

No structured table rows were added, deleted, or modified. Source reads confirmed existing analyzer facts for authentication (scoped secret access via resourceNames), integration_points (cert-manager Certificate/Issuer CRUD), and internal_dependencies (odh-platform-utilities PlatformObject interface). FIPS Compliance was added as a synthesis subsection under Security with evidence-backed build-time and application-level crypto findings.
