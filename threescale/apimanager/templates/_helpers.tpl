{{/*
Expand the name of the chart.
*/}}
{{- define "apimanager.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "apimanager.fullname" -}}
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
Create chart name and version as used by the chart label.
*/}}
{{- define "apimanager.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "apimanager.labels" -}}
helm.sh/chart: {{ include "apimanager.chart" . }}
{{ include "apimanager.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "apimanager.selectorLabels" -}}
app.kubernetes.io/name: {{ include "apimanager.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "apimanager.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "apimanager.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Minio name.
*/}}
{{- define "minio.name" -}}
{{- default "minio" .Values.minio.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common minio labels
*/}}
{{- define "minio.labels" -}}
helm.sh/chart: {{ include "apimanager.chart" . }}
{{ include "minio.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels for minio
*/}}
{{- define "minio.selectorLabels" -}}
app.kubernetes.io/name: {{ include "minio.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
ArgoCD Syncwave
*/}}
{{- define "minio.argocd-syncwave" -}}
{{- if .Values.argocd }}
{{- if and (.Values.minio.argocd.syncwave) (.Values.argocd.enabled) -}}
argocd.argoproj.io/sync-wave: "{{ .Values.minio.argocd.syncwave }}"
{{- else }}
{{- "{}" }}
{{- end }}
{{- else }}
{{- "{}" }}
{{- end }}
{{- end }}

{{/*
Name of the s3-auth secret.
*/}}
{{- define "s3-auth.name" -}}
{{- default "s3-auth" .Values.s3Auth.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* 
s3-auth secret.
*/}}
{{- define "s3-auth.secret" -}}
{{- if .Values.minio.enabled }}
{{- $hostname := printf "%s-%s.%s:80" (include "minio.name" . ) .Release.Namespace (include "openshift.subdomain" .) }}
data:
  AWS_ACCESS_KEY_ID: {{ .Values.minio.accessKey | b64enc }}
  AWS_SECRET_ACCESS_KEY: {{ .Values.minio.secretKey | b64enc }}
  AWS_BUCKET: {{ "3scale-bucket" | b64enc }}
  AWS_REGION: {{ .Values.minio.region | b64enc }}
  AWS_HOSTNAME: {{ $hostname | b64enc }}
  AWS_PATH_STYLE: {{ "true" | b64enc }}
  AWS_PROTOCOL: {{ "HTTP" | b64enc }}
{{- end }}
{{- end }}

{{/* 
system-seed secret
*/}}
{{- define "system-seed.secret" -}}
{{- $secretObj := (lookup "v1" "Secret" .Release.Namespace "system-seed") | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $adminAccessToken := "" }}
{{- if .Values.system.adminAccessToken }}
{{- $adminAccessToken = .Values.system.adminAccessToken }}
{{- else }}
{{- $adminAccessToken = (get $secretData "ADMIN_ACCESS_TOKEN") | default (randAlpha 16 | b64enc) }}
{{- end }}
{{- $adminPassword := "" }}
{{- if .Values.system.adminPassword }}
{{- $adminPassword = .Values.system.adminPassword }}
{{- else }}
{{- $adminPassword = (get $secretData "ADMIN_PASSWORD") | default (randAlpha 8 | b64enc) }}
{{- end }}
{{- $masterAccessToken := "" }}
{{- if .Values.system.masterAccessToken }}
{{- $masterAccessToken = .Values.system.masterAccessToken }}
{{- else }}
{{- $masterAccessToken := (get $secretData "MASTER_ACCESS_TOKEN") | default (randAlpha 8 | b64enc) }}
{{- end }}
{{- $masterPassword := "" }}
{{- if .Values.system.masterPassword }}
{{- $masterPassword = .Values.system.masterPassword }}
{{- else }}
{{- $masterPassword = (get $secretData "MASTER_PASSWORD") | default (randAlpha 8 | b64enc) }}
{{- end }}
data:
  ADMIN_ACCESS_TOKEN: {{ $adminAccessToken }}
  ADMIN_EMAIL: {{ .Values.system.adminEmail | b64enc }}
  ADMIN_PASSWORD: {{ $adminPassword }}
  ADMIN_USER: {{ .Values.system.adminUserId | b64enc }}
  MASTER_ACCESS_TOKEN: {{ $masterAccessToken }}
  MASTER_DOMAIN: {{ .Values.system.masterDomain | b64enc }}
  MASTER_PASSWORD: {{ $masterPassword }}
  MASTER_USER: {{ .Values.system.masterUserId | b64enc }}
  TENANT_NAME: {{ .Values.system.tenantName | b64enc }}
{{- end }}

{{/* 
OpenShift Subdomain
*/}}
{{- define "openshift.subdomain" -}}
{{- if .Values.global.openshift.subdomain }}
{{- .Values.global.openshift.subdomain }}
{{- else }}
{{- $ingresscontroller := (lookup "operator.openshift.io/v1" "IngressController" "openshift-ingress-operator" "default") | default dict }}
{{- $status := (get $ingresscontroller "status") | default dict }}
{{- $domain := (get $status "domain") | default dict }}
{{- $domain }}
{{- end }}
{{- end }}
