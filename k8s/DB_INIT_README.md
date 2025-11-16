# 🗄️ Inicialização Automática do Banco de Dados no Kubernetes

Este documento explica como funciona a inicialização automática do banco de dados PostgreSQL com dados de teste no Kubernetes.

## 📋 Índice

- [Visão Geral](#visão-geral)
- [Componentes](#componentes)
- [Como Funciona](#como-funciona)
- [Estrutura de Arquivos](#estrutura-de-arquivos)
- [Uso](#uso)
- [Troubleshooting](#troubleshooting)

---

## 🎯 Visão Geral

Diferente do Docker Compose que usa o mecanismo nativo do PostgreSQL (`/docker-entrypoint-initdb.d/`), no Kubernetes usamos um **Job** que:

✅ Aguarda o PostgreSQL ficar pronto  
✅ Executa o script `init-data.sql`  
✅ Popula o banco com dados de teste  
✅ Verifica se dados já existem antes de inserir (evita duplicação)  
✅ Mostra estatísticas após a inserção  

---

## 🔧 Componentes

### 1. ConfigMap com SQL (`init-data-configmap.yaml`)
Armazena o script SQL completo com:
- Criação de tabelas (IF NOT EXISTS)
- Índices
- 23 veículos de exemplo
- 3 vendas de exemplo

### 2. Job de Inicialização (`init-data-job.yaml`)
Executa automaticamente após o deploy e:
- **Init Container**: Aguarda PostgreSQL estar pronto
- **Main Container**: Executa o SQL

### 3. Patches por Ambiente (`overlays/*/`)
Ajusta nomes de serviços conforme o ambiente:
- `local-postgres-service` (ambiente local)
- `postgres-service` (outros ambientes)

---

## 🚀 Como Funciona

### Fluxo de Execução

```
1. kubectl apply -k k8s/overlays/local
   ↓
2. PostgreSQL Pod inicia
   ↓
3. Job "init-database" é criado
   ↓
4. Init Container aguarda PostgreSQL (pg_isready)
   ↓
5. Verifica se já existem dados
   ↓
   ├─→ SIM: Pula inicialização (evita duplicação)
   └─→ NÃO: Executa init-data.sql
       ↓
       6. Mostra estatísticas
          ↓
          7. Job marca como "Completed"
```

### Proteção Contra Duplicação

O Job verifica automaticamente se já existem dados:

```sql
SELECT COUNT(*) FROM vehicles WHERE id > 0;
```

Se houver veículos, pula a inicialização.

---

## 📁 Estrutura de Arquivos

```
k8s/
├── base/
│   ├── init-data-configmap.yaml      # ← SQL armazenado
│   ├── init-data-job.yaml            # ← Job base
│   ├── postgres-configmap.yaml       # ← Config do PostgreSQL
│   └── kustomization.yaml            # ← Inclui os recursos
│
└── overlays/
    └── local/
        ├── init-data-job-patch.yaml      # ← Ajusta para ambiente local
        ├── postgres-configmap-patch.yaml # ← DB_HOST = local-postgres-service
        └── kustomization.yaml            # ← Aplica patches
```

---

## 💻 Uso

### Deploy Normal (Inicialização Automática)

```bash
# Deploy com inicialização automática
kubectl apply -k k8s/overlays/local

# Aguarde alguns segundos e verifique
kubectl get job -n vehicle-resale
kubectl get pods -n vehicle-resale -l app=init-database
```

### Ver Logs do Job

```bash
# Ver logs do Job de inicialização
kubectl logs -n vehicle-resale -l app=init-database

# Ou específico
kubectl logs -n vehicle-resale <job-pod-name>
```

### Verificar Dados Inseridos

```bash
# Port-forward para acessar API
kubectl port-forward -n vehicle-resale service/local-vehicle-resale-api-service 8080:80

# Em outro terminal, listar veículos
curl http://localhost:8080/vehicles | jq length
# Deve retornar: 23
```

### Reinicializar Dados do Zero

Se quiser limpar tudo e reinicializar:

```bash
# 1. Deletar tudo (incluindo volume - DADOS SERÃO PERDIDOS)
kubectl delete namespace vehicle-resale

# 2. Aguardar limpeza
sleep 10

# 3. Aplicar novamente
kubectl apply -k k8s/overlays/local

# 4. Aguardar Job completar
kubectl wait --for=condition=complete --timeout=60s job/local-init-database-job -n vehicle-resale

# 5. Verificar logs
kubectl logs -n vehicle-resale -l app=init-database
```

### Executar Job Manualmente

Se o Job falhou ou quer executar novamente:

```bash
# 1. Deletar Job anterior
kubectl delete job local-init-database-job -n vehicle-resale

# 2. Recriar
kubectl apply -k k8s/overlays/local

# 3. Acompanhar execução
kubectl get job -n vehicle-resale -w
```

---

## 🐛 Troubleshooting

### Job não Completa

**Sintoma:** Job fica em estado "Running" por muito tempo

**Verificar:**
```bash
# Ver logs do init container
kubectl logs -n vehicle-resale <job-pod> -c wait-for-postgres

# Ver logs do container principal
kubectl logs -n vehicle-resale <job-pod> -c init-data

# Descrever pod para ver eventos
kubectl describe pod -n vehicle-resale <job-pod>
```

**Causas Comuns:**
1. PostgreSQL não está pronto
2. Senha do PostgreSQL incorreta
3. Nome do serviço incorreto

**Solução:**
```bash
# Verificar se PostgreSQL está rodando
kubectl get pods -n vehicle-resale -l app=postgres

# Verificar ConfigMap
kubectl get configmap local-postgres-config -n vehicle-resale -o yaml

# Verificar Secret
kubectl get secret local-postgres-secret -n vehicle-resale -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
```

---

### Job Falha com Erro de Conexão

**Erro:**
```
could not connect to server: Connection refused
```

**Solução:**
```bash
# 1. Verificar se nome do serviço está correto
kubectl get svc -n vehicle-resale | grep postgres

# 2. Verificar patch do ConfigMap
cat k8s/overlays/local/postgres-configmap-patch.yaml

# Deve ter:
# DB_HOST: "local-postgres-service"

# 3. Testar conectividade manualmente
kubectl run -it --rm debug --image=postgres:15-alpine --restart=Never -n vehicle-resale -- \
  psql -h local-postgres-service -U postgres -d vehicle_resale -c "SELECT 1;"
```

---

### Job Falha com Erro de Permissão

**Erro:**
```
password authentication failed for user "postgres"
```

**Solução:**
```bash
# Verificar senha no Secret
kubectl get secret local-postgres-secret -n vehicle-resale -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 -d
echo ""

# Se necessário, atualizar
kubectl delete secret local-postgres-secret -n vehicle-resale
kubectl create secret generic local-postgres-secret \
  --from-literal=POSTGRES_PASSWORD=postgres123 \
  -n vehicle-resale

# Recriar Job
kubectl delete job local-init-database-job -n vehicle-resale
kubectl apply -k k8s/overlays/local
```

---

### Dados Duplicados

**Sintoma:** Inserções duplicadas mesmo com `ON CONFLICT DO NOTHING`

**Causa:** Job foi executado múltiplas vezes

**Solução:**
```bash
# Opção 1: Limpar dados manualmente
kubectl exec -it -n vehicle-resale <postgres-pod> -- \
  psql -U postgres -d vehicle_resale -c "DELETE FROM sales; DELETE FROM vehicles;"

# Opção 2: Recriar volume (PERDE TODOS OS DADOS)
kubectl delete pvc local-postgres-pvc -n vehicle-resale
kubectl apply -k k8s/overlays/local
```

---

### Ver Estatísticas do Banco

```bash
# Conectar ao PostgreSQL
kubectl exec -it -n vehicle-resale <postgres-pod> -- \
  psql -U postgres -d vehicle_resale

# Dentro do psql:
SELECT 'Veículos' as tabela, COUNT(*) as total FROM vehicles 
UNION ALL 
SELECT 'Vendas', COUNT(*) FROM sales;

# Sair
\q
```

---

## 📊 Dados Inseridos

### Veículos (23 total)

- **20 veículos disponíveis** (status: AVAILABLE)
  - Marcas: Toyota, Honda, Volkswagen, Chevrolet, Fiat, Ford, Hyundai, Nissan, Renault, Jeep, BMW, Mercedes-Benz, Audi
  - Preços: R$ 42.000 até R$ 248.000

- **3 veículos vendidos** (status: SOLD)
  - Toyota Corolla 2020
  - Honda Civic 2019
  - Volkswagen Polo 2021

### Vendas (0-2 dependendo do estado)

Se executado com sucesso, insere 2 vendas:
- João Silva - Toyota Corolla (há 5 dias)
- Maria Santos - Honda Civic (há 3 dias)

---

## 🔄 Integração com CI/CD

O Job é executado automaticamente em cada deploy, tornando-o ideal para:

✅ Ambientes de desenvolvimento  
✅ Testes automatizados  
✅ Demos e apresentações  
✅ Ambientes efêmeros  

**Exemplo GitLab CI:**

```yaml
deploy-local:
  script:
    - kubectl apply -k k8s/overlays/local
    - kubectl wait --for=condition=complete --timeout=60s job/local-init-database-job -n vehicle-resale
    - kubectl logs -n vehicle-resale -l app=init-database
```

---

## 🎯 Próximos Passos

Após inicialização bem-sucedida:

1. **Testar API:**
   ```bash
   kubectl port-forward -n vehicle-resale service/local-vehicle-resale-api-service 8080:80
   curl http://localhost:8080/vehicles
   ```

2. **Ver Swagger UI:**
   ```bash
   http://localhost:8080/q/swagger-ui
   ```

3. **Fazer uma venda:**
   ```bash
   curl -X POST http://localhost:8080/sales \
     -H "Content-Type: application/json" \
     -d '{
       "vehicleId": 1,
       "buyerName": "Teste User",
       "buyerEmail": "teste@email.com",
       "buyerCpf": "111.222.333-44",
       "saleDate": "2025-11-14"
     }'
   ```

---

## 📚 Referências

- [Kubernetes Jobs](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)
- [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)
- [Kustomize Overlays](https://kubernetes.io/docs/tasks/manage-kubernetes-objects/kustomization/)

---

**Desenvolvido com ❤️ para facilitar o desenvolvimento local** 🚀

