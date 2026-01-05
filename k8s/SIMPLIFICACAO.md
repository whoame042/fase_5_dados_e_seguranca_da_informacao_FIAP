# Simplificação da Pasta k8s

## ✅ Simplificações Realizadas

### Removido (Não Essenciais)

1. **demos/** - Demos de Canary e A/B Testing (não são requisitos)
2. **overlays/** - Overlays para AWS, Azure, GCP, Local (complexidade desnecessária)
3. **scripts/** - Scripts auxiliares (load-test, monitor-hpa, etc.)
4. **init-data-configmap.yaml** e **init-data-job.yaml** - Migração via Hibernate
5. **ingress.yaml** - Ingress removido (pode ser adicionado depois se necessário)
6. **Documentação extra**: MANIFESTOS_OBRIGATORIOS.md, DB_INIT_README.md

### Mantido (Essenciais)

1. **Namespace** - `namespace.yaml`
2. **API Application**:
   - `deployment.yaml` - Deployment da API
   - `service.yaml` - Service da API
   - `configmap.yaml` - Configurações
   - `secret.yaml` - Secrets
3. **PostgreSQL (API Database)**:
   - `postgres-deployment.yaml`
   - `postgres-service.yaml`
   - `postgres-configmap.yaml`
   - `postgres-secret.yaml`
   - `postgres-pvc.yaml`
4. **Keycloak (Authentication - Separated)**:
   - `keycloak-deployment.yaml`
   - `keycloak-service.yaml`
   - `keycloak-configmap.yaml`
   - `keycloak-secret.yaml`
   - `keycloak-postgres-deployment.yaml`
   - `keycloak-postgres-service.yaml`
   - `keycloak-postgres-pvc.yaml`
5. **Kustomize** - `kustomization.yaml`
6. **Scripts**:
   - `deploy.sh` - Script simplificado de deploy
   - `README.md` - Documentação básica

### Otimizações

1. **Replicas reduzidas**: API de 2 para 1 replica
2. **Recursos reduzidos**:
   - API: 256Mi/250m (requests) → 512Mi/500m (limits)
   - Keycloak: 256Mi/250m (requests) → 512Mi/500m (limits)
3. **Storage reduzido**:
   - PostgreSQL: 5Gi → 2Gi
   - Keycloak PostgreSQL: 2Gi → 1Gi

## 📊 Estrutura Final

```
k8s/
├── base/                    # 18 manifestos essenciais
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   ├── secret.yaml
│   ├── postgres-*.yaml (5 arquivos)
│   ├── keycloak-*.yaml (7 arquivos)
│   └── kustomization.yaml
├── deploy.sh               # Script simplificado
└── README.md               # Documentação básica
```

**Total**: 20 arquivos (antes: ~50+ arquivos)

## ✅ Requisitos Técnicos Atendidos

- ✅ **Deploy automatizado**: Script `deploy.sh` funcional
- ✅ **Keycloak separado**: Deployment e banco separados
- ✅ **PostgreSQL separado**: Banco da API separado do Keycloak
- ✅ **Namespace isolado**: `vehicle-resale`
- ✅ **Health checks**: Liveness e readiness probes
- ✅ **Persistent storage**: PVCs para ambos os bancos
- ✅ **Configuração via ConfigMaps/Secrets**: Separação de configuração

## 🚀 Como Usar

```bash
# Deploy completo
cd k8s
./deploy.sh

# Ou manualmente
kubectl apply -k base/

# Verificar
kubectl get pods -n vehicle-resale
kubectl get services -n vehicle-resale

# Port-forward
kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80
```

## 📝 Notas

- **Migração de dados**: Usa `QUARKUS_HIBERNATE_ORM_DATABASE_GENERATION=update` (Hibernate cria/atualiza schema)
- **Ingress**: Removido para simplificar. Pode ser adicionado depois se necessário.
- **Overlays**: Removidos. Para diferentes ambientes, use variáveis de ambiente ou crie overlays específicos se necessário.

