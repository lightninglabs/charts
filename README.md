# Lightning Labs Helm Charts

Official Helm charts for running Lightning Labs software on Kubernetes, published to GHCR as OCI artifacts.

- **Registry (OCI):** `ghcr.io/lightninglabs/charts`
- **Available charts:** [`lnd`](./charts/lnd/)

## Quick start

### Install from GHCR (recommended)

Helm 3.8+ supports OCI registries natively.

```bash
# Install LND from GHCR
helm install my-release --namespace my-namespace -f values.yaml oci://ghcr.io/lightninglabs/charts/lnd --version <version>
```

### Install from source
```bash
# Install LND from helm source
cd charts/lnd
helm install my-release --namespace my-namespace -f values.yaml ./
```

## Publishing & versioning

- Charts are published to:  
  `oci://ghcr.io/lightninglabs/charts/<chart>`

- Versions come from each chart’s `Chart.yaml` (`version:`).
