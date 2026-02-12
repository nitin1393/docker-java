{{/*
Expand the name of the chart.
*/}}
{{- define ".name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define ".fullname" -}}
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
{{- define ".chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define ".labels" -}}
helm.sh/chart: {{ include ".chart" . }}
{{ include ".selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define ".selectorLabels" -}}
app.kubernetes.io/name: {{ include ".name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define ".serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include ".fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Node taints - dynamically generated based on nodepool name
Expects dict with: name, config
*/}}
{{- define "karpenter.taints" -}}
{{- $name := .name -}}
{{- if eq $name "infra" }}
taints:
  - key: "node.kubernetes.io/infrastructure"
    value: "true"
    effect: "NoSchedule"
{{- else }}
taints:
  - key: "workload"
    value: "dspm"
    effect: "NoSchedule"
{{- end }}
{{- end }}

{{/*
Node labels - dynamically generated based on nodepool name
Expects dict with: name, config, clusterName
*/}}
{{- define "karpenter.nodeLabels" -}}
{{- $name := .name -}}
{{- $clusterName := .clusterName -}}
{{- if eq $name "infra" }}
labels:
  node.kubernetes.io/infrastructure: "true"
  environment: {{ regexFind "dev|stage|prod" $clusterName | default "dev" | quote }}
  provisioner: "karpenter"
{{- else }}
labels:
  node.kubernetes.io/application: "true"
  environment: {{ regexFind "dev|stage|prod" $clusterName | default "dev" | quote }}
  provisioner: "karpenter"
{{- end }}
{{- end }}

{{/*
Node affinity - dynamically generated based on nodepool name
Expects dict with: name, config
*/}}
{{- define "karpenter.nodeAffinity" -}}
{{- $name := .name -}}
{{- if eq $name "infra" }}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: "node.kubernetes.io/infrastructure"
              operator: In
              values:
                - "true"
{{- else }}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
        - matchExpressions:
            - key: "workload"
              operator: In
              values:
                - "dspm"
{{- end }}
{{- end }}

{{/*
Tolerations for pods that need to run on specific nodepool nodes
Expects dict with: name, config
*/}}
{{- define "karpenter.tolerations" -}}
{{- $name := .name -}}
{{- if eq $name "infra" }}
tolerations:
  - key: "node.kubernetes.io/infrastructure"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
{{- else }}
tolerations:
  - key: "workload"
    operator: "Equal"
    value: "dspm"
    effect: "NoSchedule"
{{- end }}
{{- end }}
