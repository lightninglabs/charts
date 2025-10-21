# lnd helm chart

[LND](https://github.com/lightningnetwork/lnd) is a complete
implementation of a Lightning Network node. It supports several
pluggable back-end chain services including btcd, bitcoind, and neutrino
(a new experimental light client).

## Introduction

This chart bootstraps a single node `lnd` deployment on a Kubernetes
cluster using the [Helm](https://helm.sh) package manager.

Container image
[lightninglabs/lnd](https://hub.docker.com/r/lightninglabs/lnd)
is produced directly by the
[Github workflow](https://github.com/lightningnetwork/lnd/blob/master/.github/workflows/docker.yml)

It uses [lndinit](https://github.com/lightninglabs/lndinit) to bootstrap
a new node, and also to unlock an existing node.

Additionally, [lndmon](https://github.com/lightninglabs/lndmon) is deployed as a sidecar
container, providing a drop-in monitoring solution with Prometheus metrics.

## Prerequisites

- Kubernetes 1.18+
- Helm v3.0+
- PV provisioner for persistent data support

## Configuration

The `lnd.conf` file is generated from a template instead being hardcoded.
For a complete list of available options, see the official
[sample-lnd.conf](https://github.com/lightningnetwork/lnd/blob/master/sample-lnd.conf).

Example:

```yaml
lnd:
  ...
  config:
    # top-level overrides [Application Options] go here
    overrides: 
      debuglevel: debug
    # subsytem overrides are organized by namespace
    bitcoin:
      node: bitcoind
    bitcoind:
      rpcuser: lightning
      rpcpass: lightning
    healthcheck:
      chainbackend.attempts: 3
      tls.attempts: 1
```
### RPC credentials

While the `bitcoind.rpcuser` and `bitcoind.rpcpass` can be set directly in `values.yaml` as shown above, **this is not recommended for production**.

Instead, store RPC credentials in a Kubernetes `Secret` and let LND read them at runtime. This keeps sensitive data out of Helm values and version control.

#### Create the Secret

```
kubectl create secret generic bitcoin-rpc \
  --from-literal=rpcuser=lightning \
  --from-literal=rpcpass=lightning
```
The default secret name and variables name can be changed:
```yaml
lnd:
  ...
  config:
    bitcoin:
      ...
      rpcSecretName: bitcoin-rpc
```

### Remote database considerations

Database parameters are defined under `lnd.db.<db_type>`, for example:

#### Bolt (embedded, default):
```yaml
lnd:
  ...
  db:
    backend: bolt
    bolt:
      auto-compact: true
      auto-compact-min-age: 0
      dbtimeout: 10s
```

#### etcd:
```yaml
lnd:
  ...
  db:
    backend: etcd
    etcd:
      host: localhost:2379
      user: userscopedforlnd
```

#### SQLite:
```yaml
lnd:
  ...
  db:
    backend: sqlite
    sqlite:
      timeout: 0s
      max-batch-size: 250
      max-page-size: 100
```

#### PostgreSQL:
```yaml
lnd:
  ...
  db:
    backend: postgres
    postgres:
      dsn: "postgresql://lnd_pg_user:lnd_pg_pass@mypostgresdb.svc.cluster.local:5432/dbname"
      timeout: 0
```

The chart does not yet handle creation of the remote database nor
users/roles. `lnd` will populate the schema and data as long as the user
has sufficient permissions to an existing (empty) db.

Refer to the
[LND Postgres docs](https://github.com/lightningnetwork/lnd/blob/master/docs/postgres.md)
for details.

#### Use Native SQL:
If set to true, native SQL will be used instead of KV emulation for tables
that support it.
Subsystems which support native SQL tables:
- Invoices
- Graph
```
lnd:
  ...
  db:
    useNativeSql: false
```

### Persistence

If you are not using an external database, node data (`channel.db`, etc)
is stored in `/data`. By default a PersistentVolumeClaim is created and
mounted into that directory. To disable persistence and use an `emptyDir`
instead, set `persistence.enabled: false`

> *!!! WARNING !!!*
> 
> An `emptyDir` volume is first created when a Pod is assigned to a Node,
> and exists as long as that Pod is running on that node. When a Pod is
> removed from a node for any reason, the data in the `emptyDir` is
> deleted forever.
> 
> *Do NOT use `emptyDir` in production unless you know what you
> are doing! All data stored in the volume will be lost on
> container restart! This is only safe if using an external database.*


## Installation

### Option 1: Local install from GHCR (OCI Registry)
```shell
helm install my-release --namespace my-namespace -f values.yaml oci://ghcr.io/lightninglabs/charts/lnd --version <version>
```

### Option 2: Local install from source
From within the `charts/lnd/` directory:
```shell
helm install my-release --namespace my-namespace -f values.yaml ./
```

## Upgrade

### Option 1: Local upgrade from GHCR (OCI Registry)
```shell
helm upgrade my-release --namespace my-namespace -f values.yaml oci://ghcr.io/lightninglabs/charts/lnd --version <version>
```

### Option 2: Local upgrade from source
From within the `charts/lnd/` directory:
```shell
helm upgrade my-release --namespace my-namespace -f values.yaml ./
```

### Initialization & Wallet Recovery

*ATTENTION*

The node bootstrapping process is handled by lndinit.
When the container starts, lndinit checks for the existence of a
specific Kubernetes Secret to determine whether to create a new
wallet or unlock an existing one.

lndinit:
- If the secret exists: lndinit will read the keys specified
in the init script to unlock or restore the wallet.
- If the secret does NOT exist: lndinit assumes a fresh install.
It will automatically generate a new 24-word seed and password,
create the Kubernetes Secret to store them, and provision a new wallet.

To restore an existing wallet: You must manually create the secret before installing the Helm chart.

> Naming Constraint: lndinit expects the secret name to end in -lnd-wallet-secret.
>
> By default, the name is <release-name>-lnd-wallet-secret.
>
> You can override the prefix in values.yaml using
lndSecrets.existingWalletSecretPrefix, but the suffix is still used.

If you need to create a node from an existing wallet seed and
passphrase, you need to manually create a secret in the correct
namespace in the follow format:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: <release-name>-lnd-wallet-secret 
  namespace: <namespace>
type: Opaque
stringData:
  walletpassword: "your-wallet-password"
  walletseed: "abandon ability able about above..."
```

### Remote Signing

This chart supports [remote signing](https://github.com/lightningnetwork/lnd/blob/master/docs/remote-signing.md).

The advantage of such a setup is that the `lnd` instance containing the private keys (the **signer**) can be completely offline except for a single inbound gRPC connection. The signer instance can run on a different machine with more tightly locked down network security, optimally only allowing the single gRPC connection from the outside.

## Uninstallation

To uninstall/delete the `my-release` deployment:

```shell
helm uninstall my-release
```

The command removes most of the Kubernetes resources associated with the
chart and deletes the release. To avoid accidental deletion,
PersistentVolumeClaims and Secrets are retained and will need to be
removed manually.
