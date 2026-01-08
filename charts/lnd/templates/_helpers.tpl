{{/*
Required values. Chart will refuse to render if any are undefined, and
the corresponding message(s) will be displayed to inform the user.
*/}}
{{- required "You must set a value for 'network'" .Values.global.network -}}
{{- required "To disable persistence use lnd.persistence.enabled: false" .Values.lnd.persistence.enabled -}}

{{/*
Expand the name of the chart.
*/}}
{{- define "lnd.name" -}}
{{- default .Chart.Name .Values.lnd.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lnd.fullname" -}}
{{- if .Values.lnd.fullnameOverride }}
{{- .Values.lnd.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.lnd.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "lnd.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lnd.labels" -}}
helm.sh/chart: {{ include "lnd.chart" . }}
{{ include "lnd.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lnd.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lnd.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lnd.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lnd.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Set pvcSize if defined, otherwise choose sane value based on network
*/}}
{{- define "lnd.pvcSize" -}}
  {{- $pvcSize := "50Gi" -}}
  {{- if .Values.lnd.persistence.size -}}
    {{- $pvcSize = .Values.lnd.persistence.size -}}
  {{- else -}}
    {{- if eq .Values.global.network "testnet" -}}
      {{- $pvcSize = "10Gi" -}}
    {{- else if eq .Values.global.network "regtest" -}}
      {{- $pvcSize = "1Gi" -}}
    {{- end -}}
  {{- end -}}
  {{- printf "%s" $pvcSize -}}
{{- end -}}
