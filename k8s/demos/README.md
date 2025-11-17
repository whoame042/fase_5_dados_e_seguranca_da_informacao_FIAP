# 🚀 Demonstrações de Estratégias de Deployment

Este diretório contém demonstrações práticas de estratégias avançadas de deployment no Kubernetes.

## 📚 Índice

- [Canary Deployment](#canary-deployment)
- [A/B Testing](#ab-testing)
- [Comparação entre Estratégias](#comparação-entre-estratégias)
- [Como Executar](#como-executar)

---

## 🐤 Canary Deployment

### O que é?

**Canary Deployment** é uma estratégia de deploy gradual onde uma nova versão é implantada para um pequeno subconjunto de usuários antes de ser disponibilizada para todos.

### Como funciona?

```
┌─────────────────────────────────────────────────────────┐
│  FASE 1: Deploy Inicial (V1 - 100%)                    │
│  ┌─────────────────────────────────────────────┐      │
│  │  V1: 10 pods (100% do tráfego)              │      │
│  └─────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FASE 2: Canary (V1: 90%, V2: 10%)                     │
│  ┌────────────────────────────────────┐                │
│  │  V1: 9 pods (90% do tráfego)      │                │
│  └────────────────────────────────────┘                │
│  ┌───────────────┐                                     │
│  │  V2: 1 pod    │  ← Versão Canary (10%)            │
│  └───────────────┘                                     │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FASE 3: Aumento Gradual (V1: 50%, V2: 50%)           │
│  ┌──────────────────────┐                              │
│  │  V1: 5 pods (50%)    │                              │
│  └──────────────────────┘                              │
│  ┌──────────────────────┐                              │
│  │  V2: 5 pods (50%)    │                              │
│  └──────────────────────┘                              │
└─────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────┐
│  FASE 4: Promoção Completa (V2 - 100%)                │
│  ┌─────────────────────────────────────────────┐      │
│  │  V2: 10 pods (100% do tráfego)              │      │
│  └─────────────────────────────────────────────┘      │
│  V1: 0 pods (removida)                                │
└─────────────────────────────────────────────────────────┘
```

### Características

- ✅ **Deploy gradual** - Reduz o risco de falhas em produção
- ✅ **Rollback rápido** - Se houver problemas, basta escalar V2 para 0
- ✅ **Monitoramento** - Permite observar métricas da nova versão antes de promover
- ✅ **Transparente para usuários** - Usuários não sabem qual versão estão usando
- ⚠️ **Distribuição aleatória** - Não há controle sobre quais usuários recebem a nova versão

### Quando usar?

- ✅ Deploy de novas versões com baixo risco
- ✅ Validação de performance em produção
- ✅ Testes de carga com tráfego real
- ✅ Não há necessidade de segmentação de usuários

### Arquivos

- `canary/deployment-v1.yaml` - Deployment da versão estável (V1)
- `canary/deployment-v2-canary.yaml` - Deployment da versão canary (V2)
- `canary/service.yaml` - Service compartilhado (roteia para ambas as versões)
- `canary/demo-canary.sh` - Script de demonstração automatizado

---

## 🔀 A/B Testing

### O que é?

**A/B Testing** é uma estratégia onde diferentes versões são servidas para diferentes grupos de usuários simultaneamente para comparar métricas de negócio.

### Como funciona?

```
┌─────────────────────────────────────────────────────────┐
│  Usuários Acessando a API                               │
│                                                          │
│  ┌──────────────┐         ┌──────────────┐            │
│  │ Usuário SEM  │         │ Usuário COM  │            │
│  │ header/cookie│         │ header/cookie│            │
│  └──────┬───────┘         └──────┬───────┘            │
│         │                        │                     │
│         │                        │                     │
│         ▼                        ▼                     │
│  ┌─────────────┐         ┌─────────────┐             │
│  │  INGRESS    │         │  INGRESS    │             │
│  │ (Roteia por │         │ (Detecta    │             │
│  │  padrão)    │         │  X-Version:B│             │
│  └──────┬──────┘         │  ou cookie) │             │
│         │                 └──────┬──────┘             │
│         │                        │                     │
│         ▼                        ▼                     │
│  ┌─────────────┐         ┌─────────────┐             │
│  │  Versão A   │         │  Versão B   │             │
│  │  (Controle) │         │(Experimental)│             │
│  │  2 pods     │         │  2 pods     │             │
│  └─────────────┘         └─────────────┘             │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### Características

- ✅ **Controle granular** - Escolhe exatamente quais usuários vão para cada versão
- ✅ **Segmentação** - Pode rotear por header, cookie, IP, região, etc.
- ✅ **Comparação de métricas** - Permite comparar KPIs entre versões
- ✅ **Experimentos controlados** - Ideal para testes A/B de features
- ⚠️ **Requer Ingress Controller** - Mais complexo de configurar

### Quando usar?

- ✅ Testar novas features com usuários beta
- ✅ Comparar performance de diferentes algoritmos
- ✅ Validar mudanças de UI/UX com métricas de conversão
- ✅ Testes com grupos específicos de usuários

### Roteamento

O roteamento é feito pelo NGINX Ingress Controller baseado em:

1. **Header HTTP**: `X-Version: B`
   ```bash
   curl -H "X-Version: B" http://vehicle-resale-api-ab.local/health
   ```

2. **Cookie**: `version=B`
   ```bash
   curl --cookie "version=B" http://vehicle-resale-api-ab.local/health
   ```

3. **Padrão**: Sem header/cookie → Versão A
   ```bash
   curl http://vehicle-resale-api-ab.local/health
   ```

### Arquivos

- `ab-testing/deployment-version-a.yaml` - Deployment da versão A (controle)
- `ab-testing/deployment-version-b.yaml` - Deployment da versão B (experimental)
- `ab-testing/service-version-a.yaml` - Service exclusivo para versão A
- `ab-testing/service-version-b.yaml` - Service exclusivo para versão B
- `ab-testing/ingress-ab.yaml` - Ingress com regras de roteamento A/B
- `ab-testing/demo-ab.sh` - Script de demonstração automatizado

---

## ⚖️ Comparação entre Estratégias

| Característica | Canary Deployment | A/B Testing |
|----------------|-------------------|-------------|
| **Objetivo** | Deploy seguro com redução de risco | Comparação de métricas de negócio |
| **Distribuição de tráfego** | Baseada em % de pods | Baseada em regras (header/cookie) |
| **Controle de usuários** | ❌ Aleatório | ✅ Granular e determinístico |
| **Complexidade** | 🟢 Baixa | 🟡 Média (requer Ingress) |
| **Rollback** | 🟢 Muito rápido (scale down) | 🟡 Rápido (mudar regra Ingress) |
| **Uso típico** | Deploy de novas versões | Testes de features/experimentos |
| **Monitoramento** | Métricas técnicas (CPU, erros) | Métricas de negócio (conversão, uso) |
| **Duração** | ⏱️ Curta (minutos/horas) | ⏱️ Longa (dias/semanas) |
| **Sessão de usuário** | ❌ Pode mudar entre versões | ✅ Consistente (via cookie) |

---

## 🚀 Como Executar

### Pré-requisitos

- Minikube rodando
- kubectl configurado
- NGINX Ingress Controller habilitado
  ```bash
  minikube addons enable ingress
  ```

### Canary Deployment

#### Automático (Recomendado)
```bash
cd k8s/demos/canary
./demo-canary.sh
```

#### Manual
```bash
cd k8s/demos/canary

# Fase 1: Deploy V1 (100%)
kubectl apply -f deployment-v1.yaml
kubectl apply -f service.yaml

# Fase 2: Deploy V2 Canary (10%)
kubectl apply -f deployment-v2-canary.yaml

# Fase 3: Aumentar V2 para 50%
kubectl scale deployment/vehicle-resale-api-v1 --replicas=5 -n vehicle-resale
kubectl scale deployment/vehicle-resale-api-v2-canary --replicas=5 -n vehicle-resale

# Fase 4: Promover V2 para 100%
kubectl scale deployment/vehicle-resale-api-v1 --replicas=0 -n vehicle-resale
kubectl scale deployment/vehicle-resale-api-v2-canary --replicas=10 -n vehicle-resale

# Fase 5: Limpar V1
kubectl delete deployment/vehicle-resale-api-v1 -n vehicle-resale
```

### A/B Testing

#### Automático (Recomendado)
```bash
cd k8s/demos/ab-testing
./demo-ab.sh
```

#### Manual
```bash
cd k8s/demos/ab-testing

# Deploy ambas as versões
kubectl apply -f deployment-version-a.yaml
kubectl apply -f deployment-version-b.yaml
kubectl apply -f service-version-a.yaml
kubectl apply -f service-version-b.yaml

# Configurar Ingress A/B
kubectl apply -f ingress-ab.yaml

# Adicionar ao /etc/hosts
echo "$(minikube ip) vehicle-resale-api-ab.local" | sudo tee -a /etc/hosts

# Testar Versão A (padrão)
curl http://vehicle-resale-api-ab.local/health

# Testar Versão B (com header)
curl -H "X-Version: B" http://vehicle-resale-api-ab.local/health

# Testar Versão B (com cookie)
curl --cookie "version=B" http://vehicle-resale-api-ab.local/health
```

---

## 📊 Monitoramento e Métricas

### Canary Deployment

Monitorar durante o deploy:

```bash
# Ver distribuição de pods
kubectl get pods -n vehicle-resale -l app=vehicle-resale-api --show-labels

# Ver logs da versão Canary
kubectl logs -f -n vehicle-resale -l version=v2

# Ver métricas de CPU/Memória
kubectl top pods -n vehicle-resale -l app=vehicle-resale-api
```

### A/B Testing

Monitorar tráfego por versão:

```bash
# Ver logs da Versão A
kubectl logs -f -n vehicle-resale -l version=a

# Ver logs da Versão B
kubectl logs -f -n vehicle-resale -l version=b

# Ver acessos por Ingress
kubectl logs -f -n ingress-nginx <ingress-controller-pod>
```

---

## 🗑️ Limpeza

### Canary
```bash
cd k8s/demos/canary
kubectl delete -f .
```

### A/B Testing
```bash
cd k8s/demos/ab-testing
kubectl delete -f .
```

---

## 📝 Notas Importantes

### Canary Deployment

1. **Proporção de tráfego** é controlada pelo número de pods (réplicas)
2. **Rollback** é imediato: `kubectl scale deployment/v2-canary --replicas=0`
3. **Monitoramento** é essencial antes de promover a versão canary

### A/B Testing

1. **NGINX Ingress** é obrigatório para roteamento baseado em headers
2. **Cookies** garantem que o usuário sempre vá para a mesma versão
3. **Headers** são úteis para testes de API ou aplicações móveis

---

## 🎓 Referências

- [Kubernetes Deployment Strategies](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [NGINX Ingress Canary Annotations](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#canary)
- [A/B Testing Best Practices](https://martinfowler.com/bliki/CanaryRelease.html)

---

**Última atualização:** 17/11/2024

