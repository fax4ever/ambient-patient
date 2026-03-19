#!/bin/bash
# Deploy Ambient Patient app-server with Helm

set -euo pipefail

NAMESPACE=${NAMESPACE:-ambient-patient}
RELEASE_NAME=${RELEASE_NAME:-ambient-patient}
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Deploying Ambient Patient (app-server + full-agent-ui + ace-controller-pipeline + turn-server)"
echo "Namespace: $NAMESPACE"
echo "Release: $RELEASE_NAME"

# Check if logged in
if ! oc whoami &> /dev/null; then
    echo "ERROR: Not logged in to OpenShift. Run 'oc login' first."
    exit 1
fi

echo "Checking if images exist..."
oc get imagestream app-server -n $NAMESPACE &>/dev/null || { echo "ERROR: app-server image not found. Run ./deploy/build-images.sh first"; exit 1; }
oc get imagestream ace-controller-pipeline -n $NAMESPACE &>/dev/null || { echo "ERROR: ace-controller-pipeline image not found. Run ./deploy/build-images.sh first"; exit 1; }
oc get imagestream coturn -n $NAMESPACE &>/dev/null || { echo "ERROR: coturn image not found. Run ./deploy/build-images.sh first (it builds coturn as part of 'all')"; exit 1; }
oc get imagestream websockify -n $NAMESPACE &>/dev/null || { echo "ERROR: websockify image not found (required for TURN at path /turn). Run ./deploy/build-images.sh websockify or ./deploy/build-images.sh all"; exit 1; }

# Build Helm set args for API keys (optional env vars)
SET_ARGS=(
    --namespace "$NAMESPACE"
    --set "images.namespace=$NAMESPACE"
    --set "namespace=$NAMESPACE"
)
[ -n "${NVIDIA_API_KEY:-}" ] && SET_ARGS+=(--set "appServer.nvidiaApiKey=$NVIDIA_API_KEY")
[ -n "${NGC_API_KEY:-}" ] && SET_ARGS+=(--set "appServer.ngcApiKey=$NGC_API_KEY")
[ -n "${TAVILY_API_KEY:-}" ] && SET_ARGS+=(--set "appServer.tavilyApiKey=$TAVILY_API_KEY")
[ -n "${LANGSMITH_API_KEY:-}" ] && SET_ARGS+=(--set "appServer.langsmithApiKey=$LANGSMITH_API_KEY")
[ -n "${NVIDIA_API_KEY:-}" ] && SET_ARGS+=(--set "aceControllerPipeline.nvidiaApiKey=$NVIDIA_API_KEY")
[ -n "${NGC_API_KEY:-}" ] && SET_ARGS+=(--set "aceControllerPipeline.ngcApiKey=$NGC_API_KEY")

echo "Installing Helm chart..."
helm upgrade --install "$RELEASE_NAME" "$SCRIPT_DIR/ambient-patient" "${SET_ARGS[@]}"

echo ""
echo "✓ Ambient Patient (app-server + full-agent-ui + ace-controller-pipeline + turn-server) deployed successfully!"
echo ""
echo "Monitor deployment:"
echo "  oc get pods -n $NAMESPACE -w"
echo ""
echo "Deployments (Coturn = $RELEASE_NAME-turn-server):"
echo "  oc get deploy -n $NAMESPACE"
echo ""
echo "Full Agent UI (open in browser):"
echo "  https://<host>/full-assistant/"
echo "  Get host: oc get route -n $NAMESPACE -l app.kubernetes.io/component=full-agent-ui -o jsonpath='{.items[0].spec.host}'"
