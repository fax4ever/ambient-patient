# Minimal WebSocket-to-TCP proxy for TURN over WebSocket (path /turn).
# Used as sidecar with Coturn when exposing TURN on same host at /turn.
FROM python:3.12-alpine
RUN pip install --no-cache-dir websockify
# Listen on 8080, forward to target (e.g. 127.0.0.1:3478 for TURN).
# Args: <listen_port> <target_host:port>
EXPOSE 8080
ENTRYPOINT ["websockify"]
