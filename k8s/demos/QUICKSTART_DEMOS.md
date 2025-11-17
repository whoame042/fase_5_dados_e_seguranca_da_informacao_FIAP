# 🚀 Quick Start - Demos de Deployment

## 🐤 Canary Deployment (Deploy Gradual)

### O que faz?
Deploy uma nova versão **gradualmente**, começando com 10% do tráfego e aumentando até 100%.

### Como executar?
```bash
cd k8s/demos/canary
./demo-canary.sh
```

### Fases
1. V1 → 100% (produção estável)
2. V2 → 10% (canary inicial)
3. V2 → 50% (aumentar tráfego)
4. V2 → 100% (promover para produção)
5. V1 → 0% (remover versão antiga)

---

## 🔀 A/B Testing (Testes de Feature)

### O que faz?
Serve **duas versões simultaneamente** para grupos diferentes de usuários.

### Como executar?
```bash
cd k8s/demos/ab-testing
./demo-ab.sh
```

### Roteamento
- **Sem header/cookie** → Versão A (padrão)
- **Com `X-Version: B`** → Versão B (experimental)
- **Com cookie `version=B`** → Versão B

### Testar
```bash
# Versão A (padrão)
curl http://vehicle-resale-api-ab.local/health

# Versão B (com header)
curl -H "X-Version: B" http://vehicle-resale-api-ab.local/health

# Versão B (com cookie)
curl --cookie "version=B" http://vehicle-resale-api-ab.local/health
```

---

## 📋 Quando usar cada um?

| Situação | Estratégia |
|----------|-----------|
| Deploy de nova versão com segurança | 🐤 **Canary** |
| Testar nova feature com usuários específicos | 🔀 **A/B Testing** |
| Validar performance em produção | 🐤 **Canary** |
| Comparar métricas de negócio | 🔀 **A/B Testing** |
| Rollback rápido | 🐤 **Canary** |
| Experimentos com segmentação | 🔀 **A/B Testing** |

---

## 🗑️ Limpar Demos

```bash
# Canary
kubectl delete -f k8s/demos/canary/

# A/B Testing
kubectl delete -f k8s/demos/ab-testing/
```

---

**Para mais detalhes, consulte:** `k8s/demos/README.md`
