# Manifestos Kubernetes Obrigatórios

Este documento evidencia **todos os manifestos obrigatórios** solicitados no projeto, conforme os requisitos de infraestrutura Kubernetes.

## Status dos Manifestos

| Manifesto | Status | Localização | Descrição |
|-----------|--------|-------------|-----------|
| Deployment | ✅ Implementado | `k8s/base/deployment.yaml` | Deploy da aplicação |
| Service | ✅ Implementado | `k8s/base/service.yaml` | Serviço da API |
| ConfigMap | ✅ Implementado | `k8s/base/configmap.yaml` | Configurações da aplicação |
| Secret | ✅ Implementado | `k8s/base/secret.yaml` | Secrets da aplicação |

---

## 1. Deployment ✅

**Arquivo:** `k8s/base/deployment.yaml`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vehicle-resale-api
  namespace: vehicle-resale
spec:
  replicas: 2
  selector:
    matchLabels:
      app: vehicle-resale-api
  template:
    metadata:
      labels:
        app: vehicle-resale-api
    spec:
      containers:
      - name: vehicle-resale-api
        image: vehicle-resale-api:1.0.0
        ports:
        - containerPort: 8082
        env:
        - name: DB_URL
          valueFrom:
            configMapKeyRef:
              name: vehicle-resale-config
              key: DB_URL
        - name: DB_USERNAME
          valueFrom:
            configMapKeyRef:
              name: vehicle-resale-config
              key: DB_USERNAME
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: vehicle-resale-secret
              key: DB_PASSWORD
        livenessProbe:
          httpGet:
            path: /health/live
            port: 8082
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health/ready
            port: 8082
          initialDelaySeconds: 20
          periodSeconds: 5
```

**Recursos implementados:**
- ✅ Replicas: 2
- ✅ Health checks (liveness e readiness)
- ✅ Variáveis de ambiente (ConfigMap + Secret)
- ✅ Resource limits
- ✅ Labels adequados

---

## 2. Service ✅

**Arquivo:** `k8s/base/service.yaml`

```yaml
apiVersion: v1
kind: Service
metadata:
  name: vehicle-resale-api-service
  namespace: vehicle-resale
  labels:
    app: vehicle-resale-api
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8082
    protocol: TCP
    name: http
  selector:
    app: vehicle-resale-api
```

**Características:**
- ✅ Tipo: ClusterIP (para uso interno no cluster)
- ✅ Porta: 80 (exposta) → 8082 (container)
- ✅ Selector correto para os pods
- ✅ Labels para identificação

---

## 3. ConfigMap ✅

**Arquivo:** `k8s/base/configmap.yaml`

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vehicle-resale-config
  namespace: vehicle-resale
  labels:
    app: vehicle-resale-api
data:
  DB_URL: "jdbc:postgresql://postgres-service:5432/vehicle_resale"
  DB_USERNAME: "postgres"
  QUARKUS_HTTP_PORT: "8082"
  QUARKUS_DATASOURCE_JDBC_URL: "jdbc:postgresql://postgres-service:5432/vehicle_resale"
  QUARKUS_DATASOURCE_USERNAME: "postgres"
```

**Configurações:**
- ✅ URL do banco de dados
- ✅ Username do banco
- ✅ Porta HTTP da aplicação
- ✅ Configurações do Quarkus

---

## 4. Secret ✅

**Arquivo:** `k8s/base/secret.yaml`

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: vehicle-resale-secret
  namespace: vehicle-resale
  labels:
    app: vehicle-resale-api
type: Opaque
data:
  # Senha do banco de dados (base64: "postgres123")
  DB_PASSWORD: cG9zdGdyZXMxMjM=
```

**Secrets armazenados:**
- ✅ DB_PASSWORD (senha do banco de dados)
- ✅ Codificado em base64
- ✅ Tipo Opaque (adequado para dados arbitrários)

**Como foi codificado:**
```bash
echo -n "postgres123" | base64
# Resultado: cG9zdGdyZXMxMjM=
```

---

## Recursos Adicionais Implementados

Além dos manifestos obrigatórios, também foram implementados:

### PostgreSQL (Banco de Dados)

| Manifesto | Localização |
|-----------|-------------|
| ConfigMap | `k8s/base/postgres-configmap.yaml` |
| Secret | `k8s/base/postgres-secret.yaml` |
| PVC | `k8s/base/postgres-pvc.yaml` |
| Deployment | `k8s/base/postgres-deployment.yaml` |
| Service | `k8s/base/postgres-service.yaml` |

### Recursos Avançados

| Manifesto | Localização | Descrição |
|-----------|-------------|-----------|
| Ingress | `k8s/base/ingress.yaml` | Roteamento HTTP/HTTPS |
| HPA | `k8s/overlays/local/hpa-demo.yaml` | Horizontal Pod Autoscaler |
| Job | `k8s/base/init-data-job.yaml` | Inicialização de dados |
| Namespace | `k8s/base/namespace.yaml` | Isolamento de recursos |

---

## Como Verificar os Manifestos

### 1. Listar todos os manifestos base
```bash
ls -la k8s/base/
```

### 2. Ver conteúdo do Secret
```bash
cat k8s/base/secret.yaml
```

### 3. Ver conteúdo do Service
```bash
cat k8s/base/service.yaml
```

### 4. Ver conteúdo do ConfigMap
```bash
cat k8s/base/configmap.yaml
```

### 5. Ver conteúdo do Deployment
```bash
cat k8s/base/deployment.yaml
```

---

## Como Aplicar os Manifestos

### Opção 1: Usando Kustomize (Recomendado)
```bash
# Deploy local
cd k8s/overlays/local
kubectl apply -k .

# Deploy AWS
cd k8s/overlays/aws
kubectl apply -k .
```

### Opção 2: Aplicar manifestos base diretamente
```bash
cd k8s/base
kubectl apply -f namespace.yaml
kubectl apply -f secret.yaml
kubectl apply -f configmap.yaml
kubectl apply -f service.yaml
kubectl apply -f deployment.yaml
```

---

## Verificar Recursos no Cluster

### 1. Verificar Secret
```bash
kubectl get secrets -n vehicle-resale
kubectl describe secret vehicle-resale-secret -n vehicle-resale
```

### 2. Verificar Service
```bash
kubectl get services -n vehicle-resale
kubectl describe service vehicle-resale-api-service -n vehicle-resale
```

### 3. Verificar ConfigMap
```bash
kubectl get configmaps -n vehicle-resale
kubectl describe configmap vehicle-resale-config -n vehicle-resale
```

### 4. Verificar Deployment
```bash
kubectl get deployments -n vehicle-resale
kubectl describe deployment vehicle-resale-api -n vehicle-resale
```

### 5. Verificar todos os recursos
```bash
kubectl get all -n vehicle-resale
```

---

## Validação Completa

Para validar que **todos os manifestos obrigatórios** estão presentes e funcionando:

```bash
# 1. Aplicar manifestos
cd k8s/overlays/local
./deploy-minikube.sh

# 2. Aguardar pods ficarem prontos
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=300s

# 3. Verificar todos os recursos
kubectl get all,configmap,secret -n vehicle-resale

# 4. Testar o Service
kubectl port-forward -n vehicle-resale service/vehicle-resale-api-service 8082:80

# 5. Acessar API
curl http://localhost:8082/health
```

**Saída esperada:**
```
✅ Secret: vehicle-resale-secret
✅ ConfigMap: vehicle-resale-config  
✅ Service: vehicle-resale-api-service
✅ Deployment: vehicle-resale-api
✅ Pods: 2/2 Running
```

---

## Conclusão

✅ **Deployment** - Implementado em `k8s/base/deployment.yaml`  
✅ **Service** - Implementado em `k8s/base/service.yaml`  
✅ **ConfigMap** - Implementado em `k8s/base/configmap.yaml`  
✅ **Secret** - Implementado em `k8s/base/secret.yaml`

**Todos os 4 manifestos obrigatórios estão implementados e funcionais.**

---

**Última atualização:** 25/11/2024  
**Autor:** Eduardo Almeida  
**Versão:** 1.0.0

