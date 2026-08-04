# Architecture Changes: ai-gateway-payload-processing

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | networking.istio.io/v1/ServiceEntry :: Resource CRUD | * | <empty> | <empty> | ExternalProvider controller creates Istio ServiceEntry resources for mesh-external DNS resolution of provider endpoints | pkg/controller/externalprovider/reconciler.go:56, pkg/controller/externalprovider/reconciler.go:117-119, pkg/controller/externalprovider/reconciler.go:278-298 |
| add | integration_points | networking.istio.io/v1/DestinationRule :: Resource CRUD | * | <empty> | <empty> | ExternalProvider controller creates Istio DestinationRule resources for TLS origination to provider endpoints | pkg/controller/externalprovider/reconciler.go:57, pkg/controller/externalprovider/reconciler.go:124-126, pkg/controller/externalprovider/reconciler.go:301-318 |
