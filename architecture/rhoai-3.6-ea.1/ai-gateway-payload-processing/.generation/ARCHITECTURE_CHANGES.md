# Architecture Changes: ai-gateway-payload-processing

| Action | Category | Row Key | Column | Analyzer Value | Candidate Value | Reason | Evidence |
|--------|----------|---------|--------|----------------|-----------------|--------|----------|
| add | integration_points | networking.istio.io/v1/DestinationRule :: Controller watch (Watches) | * | <empty> | <empty> | ExternalProvider controller watches owned DestinationRule resources via unstructured watch with owner handler | pkg/controller/externalprovider/reconciler.go:237-246 |
| add | integration_points | networking.istio.io/v1/DestinationRule :: Resource CRUD | * | <empty> | <empty> | ExternalProvider reconciler creates and updates DestinationRule for TLS origination to external provider endpoints | pkg/controller/externalprovider/reconciler.go:124-128, pkg/controller/externalprovider/reconciler.go:301-318 |
| add | integration_points | networking.istio.io/v1/ServiceEntry :: Controller watch (Watches) | * | <empty> | <empty> | ExternalProvider controller watches owned ServiceEntry resources via unstructured watch with owner handler | pkg/controller/externalprovider/reconciler.go:234-246 |
| add | integration_points | networking.istio.io/v1/ServiceEntry :: Resource CRUD | * | <empty> | <empty> | ExternalProvider reconciler creates and updates ServiceEntry for mesh-external DNS resolution of provider endpoints | pkg/controller/externalprovider/reconciler.go:117-122, pkg/controller/externalprovider/reconciler.go:278-299 |
