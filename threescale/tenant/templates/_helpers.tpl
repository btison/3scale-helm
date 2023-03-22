{{/*
Expand the name of the chart.
*/}}
{{- define "tenant.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "tenant.fullname" -}}
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
{{- define "tenant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "tenant.labels" -}}
helm.sh/chart: {{ include "tenant.chart" . }}
{{ include "tenant.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "tenant.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tenant.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "tenant.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "tenant.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Tenant email
*/}}
{{- define "tenant.email" -}}
{{- if .Values.tenant.email }}
{{- .Values.tenant.email }}
{{- else }}
{{- printf "%s@email.com" (include "tenant.name" .) }}
{{- end }}
{{- end }}

{{/*
Tenant admin id
*/}}
{{- define "tenant.adminId" -}}
{{- if .Values.tenant.adminId }}
{{- .Values.tenant.adminId }}
{{- else }}
{{- (include "tenant.name" .) }}
{{- end }}
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

{{/* 
OpenShift Subdomain
*/}}
{{- define "system.master-url" -}}
{{- $masterDomain := "" }}
{{- if .Values.system.masterDomain }}
{{- $masterDomain = .Values.system.masterDomain }}
{{- else }}
{{- $secretObj := (lookup "v1" "Secret" .Release.Namespace "system-seed") | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $masterDomainEnc := (get $secretData "MASTER_DOMAIN") | default ("3scale-master" | b64enc) }}
{{- $masterDomain = $masterDomainEnc | b64dec }}
{{- end }}
{{- printf "https://%s.%s" .Values.system.masterDomain (include "openshift.subdomain" .) }}
{{- end }}

{{/* 
tenant secret
*/}}
{{- define "tenant.admin-secret" -}}
{{- $secretName := printf "%s-admin-secret" .Values.tenant.organizationName }}
{{- $secretObj := (lookup "v1" "Secret" .Release.Namespace $secretName) | default dict }}
{{- $secretData := (get $secretObj "data") | default dict }}
{{- $adminPassword := "" }}
{{- if .Values.tenant.adminPassword }}
{{- $adminPassword = .Values.tenant.adminPassword }}
{{- else }}
{{- $adminPassword = (get $secretData "admin_password") | default (randAlpha 8 | b64enc) }}
{{- end }}
data:
  admin_password: {{ $adminPassword }}
{{- end }}