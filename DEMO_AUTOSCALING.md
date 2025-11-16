# 🚀 Guia de Demonstração - Auto Scaling (HPA)

Este guia mostra como demonstrar o **Horizontal Pod Autoscaler (HPA)** com **scale out** (aumentar pods) e **scale in** (diminuir pods).

## 📋 Pré-requisitos

✅ Minikube rodando  
✅ Metrics Server habilitado  
✅ Aplicação implantada no Kubernetes  

## 🎯 3 Formas de Demonstrar

### 1️⃣ Forma Automática (Recomendada)

Script completo que faz tudo automaticamente:

```bash
./k8s/demo-autoscaling.sh
```

**O que faz**:
1. Verifica Metrics Server
2. Aplica HPA
3. Gera carga (scale out)
4. Monitora em tempo real
5. Para carga (scale in)
6. Limpeza

### 2️⃣ Forma Manual (Mais Controle)

#### Passo 1: Aplicar HPA
```bash
kubectl apply -f k8s/overlays/local/hpa-demo.yaml
```

#### Passo 2: Monitorar (Terminal 1)
```bash
./k8s/monitor-hpa.sh
```

#### Passo 3: Gerar Carga (Terminal 2)
```bash
./k8s/load-test.sh
```

#### Passo 4: Observar Scale Out
Aguarde 1-2 minutos e veja os pods aumentarem!

#### Passo 5: Parar Carga (Scale In)
```bash
kubectl delete pod load-generator -n vehicle-resale
```

Aguarde 2-3 minutos e veja os pods diminuírem!

### 3️⃣ Comandos Individuais (Avançado)

```bash
# Ver HPA
kubectl get hpa -n vehicle-resale -w

# Ver pods
kubectl get pods -n vehicle-resale -w

# Ver métricas
watch -n 2 'kubectl top pods -n vehicle-resale'

# Gerar carga manual
kubectl run load-generator --image=busybox:1.36 --restart=Never -n vehicle-resale -- \
  /bin/sh -c "while true; do wget -q -O- http://local-vehicle-resale-api-service/api/vehicles/available; done"

# Parar carga
kubectl delete pod load-generator -n vehicle-resale
```

## 📊 Configuração do HPA

```yaml
minReplicas: 1
maxReplicas: 5
metrics:
  - CPU: 50%      # Scale out quando CPU > 50%
  - Memory: 70%   # Scale out quando Memory > 70%

behavior:
  scaleUp:   Rápido (15s) - demonstra rapidamente
  scaleDown: Lento (60s)  - evita oscilações
```

## 🎬 Roteiro para Vídeo

### 1. Mostrar Estado Inicial (30s)
```bash
kubectl get pods -n vehicle-resale
kubectl get hpa -n vehicle-resale
```

**Narração**: "Temos 1 pod rodando. O HPA está configurado para escalar entre 1 e 5 pods baseado em CPU e memória."

### 2. Aplicar HPA (15s)
```bash
kubectl apply -f k8s/overlays/local/hpa-demo.yaml
```

**Narração**: "Aplicando o Horizontal Pod Autoscaler..."

### 3. Iniciar Monitoramento (10s)
```bash
# Terminal 1
./k8s/monitor-hpa.sh
```

**Narração**: "Vou monitorar em tempo real..."

### 4. Gerar Carga - SCALE OUT (2 min)
```bash
# Terminal 2
./k8s/load-test.sh
```

**Narração**: "Agora vou gerar carga na aplicação. Observe a CPU aumentar... O HPA detectou alta utilização e está criando novos pods. Temos agora X pods rodando!"

**Pontos a destacar**:
- CPU subindo
- HPA criando pods
- Número de réplicas aumentando

### 5. Parar Carga - SCALE IN (2 min)
```bash
kubectl delete pod load-generator -n vehicle-resale
```

**Narração**: "Parando a carga... Observe que a CPU está diminuindo. O HPA vai gradualmente reduzir os pods de volta ao mínimo. Isso evita oscilações desnecessárias."

**Pontos a destacar**:
- CPU caindo
- HPA removendo pods gradualmente
- Voltando ao estado inicial

## 📈 Métricas para Mostrar

Durante a demonstração, mostre:

```bash
# CPU/Memory atual
kubectl top pods -n vehicle-resale

# Status do HPA
kubectl get hpa -n vehicle-resale

# Eventos do HPA
kubectl describe hpa local-vehicle-resale-api-hpa -n vehicle-resale

# Contagem de pods
kubectl get pods -n vehicle-resale --no-headers | grep local-vehicle-resale-api | wc -l
```

## 🔧 Troubleshooting

### Problema: Métricas mostram `<unknown>`
**Solução**: Aguarde 1-2 minutos para o Metrics Server coletar dados.

### Problema: HPA não escala
**Solução**:
```bash
# Verificar se requests estão definidos no deployment
kubectl describe deployment local-vehicle-resale-api -n vehicle-resale | grep -A 5 "Requests"

# Ver eventos do HPA
kubectl describe hpa local-vehicle-resale-api-hpa -n vehicle-resale
```

### Problema: Metrics Server não funciona
**Solução**:
```bash
minikube addons disable metrics-server
minikube addons enable metrics-server
kubectl get pods -n kube-system | grep metrics-server
```

### Problema: Scale in muito lento
**Solução**: É intencional! O `stabilizationWindowSeconds: 60` previne oscilações. Para demonstração mais rápida, reduza para 30s no HPA.

## 🎯 Valores para Demonstração Rápida

Se quiser demonstração mais rápida, edite o HPA:

```yaml
spec:
  minReplicas: 1
  maxReplicas: 3    # Reduzido de 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 30  # Reduzido de 50
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 30  # Reduzido de 60
```

Aplique:
```bash
kubectl apply -f k8s/overlays/local/hpa-demo.yaml
```

## 🧹 Limpeza

Após a demonstração:

```bash
# Remover HPA
kubectl delete -f k8s/overlays/local/hpa-demo.yaml

# Remover gerador de carga (se ainda existir)
kubectl delete pod load-generator -n vehicle-resale 2>/dev/null

# Verificar limpeza
kubectl get hpa -n vehicle-resale
```

## 📚 Conceitos Importantes

### Scale Out (Aumentar)
- **Quando**: CPU ou Memory acima do target
- **Velocidade**: Rápido (15-30s)
- **Objetivo**: Atender demanda aumentada

### Scale In (Diminuir)
- **Quando**: CPU ou Memory abaixo do target
- **Velocidade**: Lento (60s+)
- **Objetivo**: Economizar recursos, evitar oscilações

### Stabilization Window
- Período de observação antes de escalar
- Scale Up: 0s (imediato)
- Scale Down: 60s (cauteloso)

## 🎓 Explicações para o Vídeo

**HPA (Horizontal Pod Autoscaler)**:
"É um controlador do Kubernetes que automaticamente ajusta o número de pods baseado em métricas como CPU e memória."

**Scale Out**:
"Quando a aplicação recebe mais carga, o HPA cria automaticamente mais pods para distribuir o trabalho."

**Scale In**:
"Quando a carga diminui, o HPA remove pods gradualmente para economizar recursos."

**Benefit**:
"Isso garante que a aplicação sempre tenha recursos suficientes para atender a demanda, sem desperdiçar recursos quando não necessário."

## 📞 Suporte

Scripts criados:
- `k8s/demo-autoscaling.sh` - Demonstração completa automática
- `k8s/monitor-hpa.sh` - Monitoramento em tempo real
- `k8s/load-test.sh` - Gerador de carga
- `k8s/overlays/local/hpa-demo.yaml` - Configuração do HPA

Para mais informações:
```bash
# Ver detalhes do HPA
kubectl explain hpa

# Ver configuração aplicada
kubectl get hpa local-vehicle-resale-api-hpa -n vehicle-resale -o yaml
```

