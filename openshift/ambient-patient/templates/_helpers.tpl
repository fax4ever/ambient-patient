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
Voice interface hostname - ensures both routes share the same host.
For path-based routing, UI (/) and API (/api) routes must use the same hostname.

Set either:
  - route.voiceInterface.host — full hostname (fixed; use for legacy single-namespace installs)
  - route.voiceInterface.clusterDomain — builds voice-interface-<namespace>.<clusterDomain> so multiple namespaces on one cluster get unique hosts
*/}}
{{- define "ambient-patient.voiceInterfaceHost" -}}
{{- if .Values.route.voiceInterface.host }}
{{- .Values.route.voiceInterface.host }}
{{- else if .Values.route.voiceInterface.clusterDomain }}
{{- $label := printf "voice-interface-%s" .Values.namespace | trunc 63 | trimSuffix "-" }}
{{- printf "%s.%s" $label .Values.route.voiceInterface.clusterDomain }}
{{- else }}
{{- fail "Set route.voiceInterface.clusterDomain (recommended) or route.voiceInterface.host for voice-interface routes. clusterDomain should be the apps subdomain, e.g. apps.my-cluster.openshift.com" }}
{{- end }}
{{- end }}
