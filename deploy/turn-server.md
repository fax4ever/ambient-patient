# Coturn TURN server (OpenShift / Helm)

The Helm chart deploys Coturn as a pod and wires TURN into the ace-controller pipeline so WebRTC can work when clients are behind NATs or firewalls. The chart **always uses the Coturn image you build** (same registry/namespace as other app images).

## Build the Coturn image

Build and push the Coturn image before deploying (e.g. as part of your usual image build):

```sh
./deploy/build-images.sh coturn
```

The chart uses `images.registry` / `images.namespace` / `coturn` / `latest` (see `images.turnServer` in `values.yaml`). No need to set `turnServer.image`.

## Configuration

Configure in `deploy/ambient-patient/values.yaml` (or override with `--set`):

- **`turnServer.host`** (required when not using the route): Hostname or IP where **the browser** can reach the TURN server (e.g. `localhost` when using port-forward). When **`route.turnServer.enabled`** is `true`, the chart uses the same host as the voice-interface route and exposes TURN at path **`/turn`** (see below).
- **`turnServer.hostNetwork`**: Set to `true` to use the node’s network (needs OpenShift hostnetwork SCC). Default is `false` so the pod runs without special privileges; use port-forward and `turnServer.host=localhost`.
- **`turnServer.username`** / **`turnServer.password`**: Credentials (default `admin` / `admin`).

## Exposing TURN on the same host as the voice interface (path `/turn`)

When **`route.voiceInterface.enabled`** and **`route.turnServer.enabled`** are both `true`, the chart:

- Creates a **Route** with the **same host** as the voice-interface and voice-interface-api routes, with **path** `route.turnServer.path` (default **`/turn`**).
- Adds a **WebSocket-to-TCP proxy** sidecar (websockify) in the turn-server pod so that `wss://<voice-interface-host>/turn` is forwarded to Coturn on TCP 3478. The turn-server pod then has **two containers** (Coturn + websockify); `READY 1/2` or `2/2` refers to these two containers in a single pod, not two pods.
- Sets **`TURN_SERVER_URL`** to `turn:<voice-interface-host>:443?transport=tcp` so the pipeline and UI use the same host and port 443; the client should use TURN over WebSocket to the `/turn` path when the WebRTC stack supports it.

No port-forward or `turnServer.host` is required in this mode; the effective TURN host is taken from `route.voiceInterface.host`. You must **build the websockify image** so the sidecar can run: `./deploy/build-images.sh websockify` or `./deploy/build-images.sh all`. If the turn-server pod shows `CreateContainerError` or `ImagePullBackOff` for the second container, the websockify image is missing. To disable this and use port-forward or hostNetwork instead, set **`route.turnServer.enabled: false`** and set **`turnServer.host`** as below.

## Using port-forward

If you expose the TURN service via port-forward instead of the route (or in addition, for direct TURN):

```sh
oc port-forward -n <namespace> svc/ambient-patient-turn-server 3478:3478
```

(Service name is `<release-name>-turn-server`, e.g. `ambient-patient-turn-server`.)

Set **`turnServer.host`** to the address the browser will use to reach that port (and set **`route.turnServer.enabled: false`** if you only use port-forward):

- Browser on the **same machine** as the port-forward: use `localhost` (or `127.0.0.1`), e.g. `--set turnServer.host=localhost`.
- Browser on a **different machine**: use the hostname or IP of the machine where `oc port-forward` is running.

TURN relay also uses UDP ports 51000–51010; the service only exposes 3478. For full relay, you may need to expose the relay ports (e.g. via hostNetwork + node firewall) or additional port-forwards if your setup exposes them.

## Deployment

1. **With route (same host, path /turn):** Ensure `route.voiceInterface.host` is set and `route.turnServer.enabled` is `true`. No need to set `turnServer.host`; it is derived from the voice-interface host. **Without route:** Set `turnServer.host` before deploying (e.g. `--set turnServer.host=YOUR_NODE_PUBLIC_IP` or `localhost` for port-forward), and set `route.turnServer.enabled: false` if you use a dedicated host/port.
2. Deploy with Helm. the turn-server deployment uses **hostNetwork** so Coturn listens on the node’s ports.
3. Ensure the node’s firewall allows **3478** (UDP/TCP) and **51000–51010** (UDP), and that `turnServer.host` points to that node’s public address.
4. The pipeline and UI receive `TURN_SERVER_URL`, `TURN_USERNAME`, and `TURN_PASSWORD` from the chart so WebRTC can use the TURN server.

**Note:** `hostNetwork: true` may require an OpenShift Security Context Constraint (e.g. `hostnetwork`) for the deployment’s service account.
