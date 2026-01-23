# Deploy no Minikube - Vehicle Resale API

Guia completo para fazer deploy da aplicação localmente usando Minikube.

---

## Pré-requisitos

### 1. Instalar Minikube

```bash
# Linux
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Verificar instalação
minikube version
```

### 2. Instalar kubectl

```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verificar instalação
kubectl version --client
```

### 3. Docker

Certifique-se de que o Docker está instalado e rodando:

```bash
docker --version
```

---

## Deploy Automatizado (Recomendado)

Use o script automatizado que faz todo o processo:

```bash
# Na raiz do projeto
./deploy-minikube.sh
```

O script faz automaticamente:
1. ✅ Verifica pré-requisitos
2. ✅ Inicia/verifica Minikube
3. ✅ Compila a aplicação
4. ✅ Faz build da imagem Docker
5. ✅ Aplica todos os recursos do Kubernetes
6. ✅ Aguarda pods ficarem prontos
7. ✅ Mostra instruções de acesso

---

## Deploy Manual Passo a Passo

### 1. Iniciar Minikube

```bash
# Iniciar com configurações adequadas
minikube start --driver=docker --memory=4096 --cpus=2

# Verificar status
minikube status
```

### 2. Compilar a Aplicação

```bash
# Na raiz do projeto
./mvnw clean package -DskipTests
./mvnw quarkus:build -DskipTests
```

### 3. Build da Imagem Docker

```bash
# Usar Docker do Minikube
eval $(minikube docker-env)

# Build da imagem
docker build -t vehicle-resale-api:1.0.1 .

# Verificar imagem
docker images | grep vehicle-resale-api
```

### 4. Aplicar Recursos do Kubernetes

```bash
cd k8s

# 1. Namespace
kubectl apply -f base/namespace.yaml

# 2. ConfigMaps e Secrets
kubectl apply -f base/postgres-configmap.yaml
kubectl apply -f base/postgres-secret.yaml
kubectl apply -f base/keycloak-configmap.yaml
kubectl apply -f base/keycloak-secret.yaml
kubectl apply -f base/configmap.yaml
kubectl apply -f base/secret.yaml

# 3. PersistentVolumeClaims
kubectl apply -f base/postgres-pvc.yaml
kubectl apply -f base/keycloak-postgres-pvc.yaml

# 4. PostgreSQL (App)
kubectl apply -f base/postgres-deployment.yaml
kubectl apply -f base/postgres-service.yaml

# Aguardar PostgreSQL ficar pronto
kubectl wait --for=condition=ready pod -l app=postgres -n vehicle-resale --timeout=120s

# 5. Keycloak PostgreSQL
kubectl apply -f base/keycloak-postgres-deployment.yaml
kubectl apply -f base/keycloak-postgres-service.yaml

# Aguardar Keycloak PostgreSQL
kubectl wait --for=condition=ready pod -l app=keycloak-postgres -n vehicle-resale --timeout=120s

# 6. Keycloak
kubectl apply -f base/keycloak-deployment.yaml
kubectl apply -f base/keycloak-service.yaml

# Aguardar Keycloak (pode demorar 2-3 minutos)
kubectl wait --for=condition=ready pod -l app=keycloak -n vehicle-resale --timeout=180s

# 7. API
kubectl apply -f base/deployment.yaml
kubectl apply -f base/service.yaml

# Aguardar API
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=120s

cd ..
```

### 5. Verificar Status

```bash
# Ver todos os pods
kubectl get pods -n vehicle-resale

# Ver services
kubectl get services -n vehicle-resale

# Ver logs da API
kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale
```

---

## Acessar os Serviços

### Opção 1: Port Forward (Recomendado para testes)

#### API
```bash
kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80
```
- API: http://localhost:8082
- Swagger UI: http://localhost:8082/swagger-ui
- Health: http://localhost:8082/health

#### Keycloak
```bash
kubectl port-forward -n vehicle-resale svc/keycloak-service 8180:8180
```
- Keycloak: http://localhost:8180
- Login: admin / admin123

#### PostgreSQL
```bash
kubectl port-forward -n vehicle-resale svc/postgres-service 5433:5432
```
- Conectar: `psql -h localhost -p 5433 -U postgres -d vehicle_resale`

### Opção 2: Minikube Service

```bash
# Expor serviço da API
minikube service vehicle-resale-api-service -n vehicle-resale

# Expor serviço do Keycloak
minikube service keycloak-service -n vehicle-resale
```

### Opção 3: NodePort (acesso via IP do Minikube)

```bash
# Obter IP do Minikube
minikube ip

# Obter porta do NodePort
kubectl get svc -n vehicle-resale

# Acessar: http://<MINIKUBE_IP>:<NODEPORT>
```

---

## Comandos Úteis

### Logs

```bash
# Logs da API
kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale

# Logs do Keycloak
kubectl logs -f -l app=keycloak -n vehicle-resale

# Logs do PostgreSQL
kubectl logs -f -l app=postgres -n vehicle-resale

# Logs de todos os containers de um pod
kubectl logs -f <pod-name> --all-containers=true -n vehicle-resale
```

### Debug

```bash
# Descrever pod (ver eventos)
kubectl describe pod <pod-name> -n vehicle-resale

# Acessar shell do container
kubectl exec -it <pod-name> -n vehicle-resale -- /bin/bash

# Listar variáveis de ambiente
kubectl exec <pod-name> -n vehicle-resale -- env

# Port forward para debug
kubectl port-forward <pod-name> 8080:8080 -n vehicle-resale
```

### Gerenciamento

```bash
# Reiniciar deployment
kubectl rollout restart deployment/vehicle-resale-api -n vehicle-resale

# Ver histórico de rollout
kubectl rollout history deployment/vehicle-resale-api -n vehicle-resale

# Rollback
kubectl rollout undo deployment/vehicle-resale-api -n vehicle-resale

# Escalar deployment
kubectl scale deployment/vehicle-resale-api --replicas=2 -n vehicle-resale

# Atualizar imagem
kubectl set image deployment/vehicle-resale-api vehicle-resale-api=vehicle-resale-api:1.0.2 -n vehicle-resale
```

### Limpeza

```bash
# Deletar um recurso específico
kubectl delete deployment vehicle-resale-api -n vehicle-resale

# Deletar namespace completo (remove tudo)
kubectl delete namespace vehicle-resale

# Parar Minikube
minikube stop

# Deletar cluster Minikube
minikube delete
```

---

## Troubleshooting

### Pod não inicia (ImagePullBackOff)

```bash
# Verificar se imagePullPolicy está correto
kubectl get deployment vehicle-resale-api -n vehicle-resale -o yaml | grep imagePullPolicy

# Deve ser: imagePullPolicy: Never (para imagens locais)

# Se necessário, atualizar:
kubectl patch deployment vehicle-resale-api -n vehicle-resale -p '{"spec":{"template":{"spec":{"containers":[{"name":"vehicle-resale-api","imagePullPolicy":"Never"}]}}}}'
```

### Imagem não encontrada

```bash
# Verificar se está usando Docker do Minikube
eval $(minikube docker-env)

# Listar imagens disponíveis
docker images | grep vehicle-resale-api

# Rebuild se necessário
docker build -t vehicle-resale-api:1.0.1 .
```

### Pod em CrashLoopBackOff

```bash
# Ver logs para identificar erro
kubectl logs <pod-name> -n vehicle-resale

# Ver eventos
kubectl get events -n vehicle-resale --sort-by='.lastTimestamp'

# Verificar se dependências estão prontas
kubectl get pods -n vehicle-resale
```

### PostgreSQL não conecta

```bash
# Verificar se PostgreSQL está rodando
kubectl get pods -l app=postgres -n vehicle-resale

# Ver logs do PostgreSQL
kubectl logs -l app=postgres -n vehicle-resale

# Testar conexão de dentro do pod da API
kubectl exec -it <api-pod-name> -n vehicle-resale -- curl postgres-service:5432
```

### Keycloak não inicia

```bash
# Keycloak demora para iniciar (2-3 minutos)
# Ver logs
kubectl logs -l app=keycloak -n vehicle-resale

# Verificar se Keycloak PostgreSQL está pronto
kubectl get pods -l app=keycloak-postgres -n vehicle-resale

# Aumentar memória do Minikube se necessário
minikube stop
minikube start --memory=6144 --cpus=4
```

### Verificar recursos do Minikube

```bash
# Ver recursos disponíveis
minikube ssh
free -h
df -h
exit

# Ver consumo de recursos dos pods
kubectl top nodes
kubectl top pods -n vehicle-resale
```

---

## Minikube Dashboard

Para visualizar graficamente todos os recursos:

```bash
# Abrir dashboard
minikube dashboard
```

---

## Configuração de Addons

### Habilitar Ingress (opcional)

```bash
# Habilitar addon de ingress
minikube addons enable ingress

# Verificar
kubectl get pods -n ingress-nginx
```

### Habilitar Metrics Server

```bash
# Habilitar metrics
minikube addons enable metrics-server

# Verificar
kubectl top nodes
kubectl top pods -n vehicle-resale
```

---

## Deploy em Produção

Para deploy em produção (EKS, GKE, AKS):

1. **Ajustar imagePullPolicy:**
   ```yaml
   imagePullPolicy: IfNotPresent  # ou Always para pull de registry
   ```

2. **Usar image de registry:**
   ```yaml
   image: ghcr.io/usuario/vehicle-resale-api:1.0.1
   ```

3. **Ajustar recursos:**
   ```yaml
   resources:
     requests:
       memory: "256Mi"
       cpu: "250m"
     limits:
       memory: "512Mi"
       cpu: "500m"
   ```

4. **Configurar Ingress** para acesso externo

5. **Configurar Persistent Volumes** apropriados para cloud

---

## Referências

- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes Concepts](https://kubernetes.io/docs/concepts/)
- [Quarkus Kubernetes](https://quarkus.io/guides/deploying-to-kubernetes)

---

**Última atualização:** Janeiro 2026  
**Versão:** 1.0.1
