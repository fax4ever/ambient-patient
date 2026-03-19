{{/*
Expand the name of the chart.
*/}}
{{- define "ambient-patient.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "ambient-patient.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "ambient-patient.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/name: {{ include "ambient-patient.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
App-server image
*/}}
{{- define "ambient-patient.appServerImage" -}}
{{- printf "%s/%s/%s:%s" .Values.images.registry .Values.images.namespace .Values.images.appServer.repository .Values.images.appServer.tag }}
{{- end }}

{{/*
Full-agent-ui uses same image as app-server (different command only)
*/}}
{{- define "ambient-patient.fullAgentUiImage" -}}
{{- include "ambient-patient.appServerImage" . }}
{{- end }}

{{/*
Ace-controller pipeline (python-app) image
*/}}
{{- define "ambient-patient.aceControllerPipelineImage" -}}
{{- printf "%s/%s/%s:%s" .Values.images.registry .Values.images.namespace .Values.images.aceControllerPipeline.repository .Values.images.aceControllerPipeline.tag }}
{{- end }}

{{/*
UI-app (webrtc-ui) image
*/}}
{{- define "ambient-patient.uiAppImage" -}}
{{- printf "%s/%s/%s:%s" .Values.images.registry .Values.images.namespace .Values.images.uiApp.repository .Values.images.uiApp.tag }}
{{- end }}

{{/*
Turn-server (Coturn) image - always use the built image from the registry
*/}}
{{- define "ambient-patient.turnServerImage" -}}
{{- printf "%s/%s/%s:%s" .Values.images.registry .Values.images.namespace .Values.images.turnServer.repository .Values.images.turnServer.tag }}
{{- end }}

{{/*
Websockify sidecar image - use built image from registry when route.turnServer.websockifyImage is not set
*/}}
{{- define "ambient-patient.websockifyImage" -}}
{{- if .Values.route.turnServer.websockifyImage }}
{{- .Values.route.turnServer.websockifyImage }}
{{- else }}
{{- printf "%s/%s/%s:%s" .Values.images.registry .Values.images.namespace .Values.images.websockify.repository .Values.images.websockify.tag }}
{{- end }}
{{- end }}

{{/*
Voice interface hostname - ensures both routes share the same host
For path-based routing to work, both routes must share the same hostname.
This requires an explicit host to be set in values.yaml
*/}}
{{- define "ambient-patient.voiceInterfaceHost" -}}
{{- required "A valid .Values.route.voiceInterface.host is required for path-based routing!" .Values.route.voiceInterface.host }}
{{- end }}

{{/*
Effective TURN server host: when exposed via route (same host + path /turn), use voice interface host; otherwise use turnServer.host
*/}}
{{- define "ambient-patient.turnServerHost" -}}
{{- if and .Values.route.voiceInterface.enabled .Values.route.turnServer.enabled }}
{{- include "ambient-patient.voiceInterfaceHost" . }}
{{- else }}
{{- .Values.turnServer.host }}
{{- end }}
{{- end }}

{{/*
TURN_SERVER_URL for pipeline/UI: when using route, use turn:host:443?transport=tcp (WebSocket path /turn); else turn:host:3478
*/}}
{{- define "ambient-patient.turnServerUrl" -}}
{{- $host := include "ambient-patient.turnServerHost" . }}
{{- if and .Values.route.voiceInterface.enabled .Values.route.turnServer.enabled }}
{{- printf "turn:%s:443?transport=tcp" $host }}
{{- else if $host }}
{{- printf "turn:%s:3478" $host }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}
