# Instruções de Uso - API de Revenda de Veículos

## Início Rápido (3 opções)

### Opção 1: Docker Compose (Recomendado para teste rápido)

```bash
# 1. Compile a aplicação
./mvnw clean package -DskipTests

# 2. Suba os containers
docker-compose up

# 3. Acesse a aplicação
# API: http://localhost:8082
# Swagger: http://localhost:8082/swagger-ui
```

**Observações:**
- O PostgreSQL será iniciado na porta **5433** (para evitar conflito com instalações locais)
- O arquivo `init-data.sql` será executado automaticamente na primeira inicialização
- O banco será populado com 20+ veículos de exemplo e algumas vendas
- **As configurações são gerenciadas via arquivo `.env`** (veja seção de Variáveis de Ambiente)

Para parar:
```bash
docker-compose down
```

Para limpar volumes e reinicializar o banco:
```bash
docker-compose down -v
docker-compose up
```

---

## Configuração de Variáveis de Ambiente

O projeto utiliza arquivo `.env` para gerenciar configurações. **Todas as configurações do `docker-compose.yml` agora são variáveis.**

### Configuração Inicial

```bash
# O arquivo .env já existe com valores padrão
# Para personalizá-lo:
cp .env.example .env
nano .env
```

### Variáveis Principais

| Variável | Descrição | Valor Padrão |
|----------|-----------|--------------|
| `POSTGRES_DB` | Nome do banco | `vehicle_resale` |
| `POSTGRES_USER` | Usuário do banco | `postgres` |
| `POSTGRES_PASSWORD` | Senha do banco | `postgres123` |
| `POSTGRES_PORT` | Porta externa | `5433` |
| `APP_PORT` | Porta da API | `8082` |
| `QUARKUS_LOG_LEVEL` | Nível de log | `INFO` |

### Exemplo: Mudar Portas

Edite o arquivo `.env`:
```bash
POSTGRES_PORT=5434
APP_PORT=8081
```

Depois reinicie:
```bash
docker-compose down
docker-compose up -d
```

### Documentação Completa

Veja o arquivo `ENV_VARS_GUIDE.md` para:
- Lista completa de variáveis
- Configurações para produção
- Boas práticas de segurança
- Troubleshooting

---

### Opção 2: Modo Desenvolvimento (Live Reload)

```bash
# 1. Inicie o PostgreSQL
docker run --name postgres-dev \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=vehicle_resale \
  -p 5432:5432 \
  -d postgres:15-alpine

# 2. Execute em modo dev
./mvnw quarkus:dev

# 3. Acesse
# API: http://localhost:8082
# Swagger: http://localhost:8082/swagger-ui
```

**Vantagens:**
- Live reload (mudanças no código refletem automaticamente)
- Dev UI em http://localhost:8082/q/dev
- Mais rápido para desenvolvimento

---

### Opção 3: Kubernetes (Produção)

```bash
# Build e Deploy automatizado
./build-and-deploy.sh

# Ou manualmente:
# 1. Compile
./mvnw clean package

# 2. Build da imagem
docker build -t vehicle-resale-api:1.0.0 .

# 3. Deploy no K8s
cd k8s
./deploy.sh

# 4. Verifique o deploy
kubectl get all -n vehicle-resale

# 5. Obtenha o IP do serviço
kubectl get service vehicle-resale-api-service -n vehicle-resale

# 6. Acesse
# API: http://<EXTERNAL-IP>
# Swagger: http://<EXTERNAL-IP>/swagger-ui
```

---

## Scripts Auxiliares

### maven-build.sh
Script para executar o Maven com as versões corretas do Java (21) e Maven (3.9.6):
```bash
./maven-build.sh clean install
./maven-build.sh clean package -DskipTests
```

### reset-database.sh
Script para reinicializar o banco de dados com dados limpos do `init-data.sql`:
```bash
./reset-database.sh
```

Este script:
1. Para os containers
2. Remove os volumes
3. Reinicia os containers
4. Executa o `init-data.sql` automaticamente

### init-data.sql
Arquivo de inicialização do banco de dados contendo:
- Criação das tabelas (vehicles e sales)
- Criação de índices para performance
- **20+ veículos de exemplo** (Toyota, Honda, VW, etc.)
- **3 vendas de exemplo** com status aprovado

O arquivo é executado automaticamente na primeira inicialização do PostgreSQL via Docker Compose.

**Nota:** Para reexecutar o script, é necessário remover os volumes:
```bash
docker-compose down -v
docker-compose up
```

---

## Testando a API

### Via Swagger UI (Mais Fácil)

1. Acesse: `http://localhost:8082/swagger-ui`
2. Explore os endpoints disponíveis
3. Clique em "Try it out" para testar
4. Execute as requisições diretamente pela interface

### Via cURL

#### 1. Cadastrar um veículo

```bash
curl -X POST http://localhost:8082/api/vehicles \
  -H "Content-Type: application/json" \
  -d '{
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2023,
    "color": "Prata",
    "price": 95000.00
  }'
```

#### 2. Listar veículos disponíveis

```bash
curl http://localhost:8082/api/vehicles/available
```

#### 3. Listar com paginação e filtros

```bash
curl "http://localhost:8082/api/vehicles/available?brand=Toyota&page=0&size=10"
```

#### 4. Efetuar uma venda

```bash
curl -X POST http://localhost:8082/api/sales \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 1,
    "buyerName": "João Silva",
    "buyerEmail": "joao.silva@email.com",
    "buyerCpf": "12345678901",
    "saleDate": "2024-01-15"
  }'
```

#### 5. Processar pagamento (webhook)

```bash
curl -X POST http://localhost:8082/api/webhook/payment \
  -H "Content-Type: application/json" \
  -d '{
    "paymentCode": "<codigo-retornado-na-venda>",
    "paid": true
  }'
```

---

## Executando Testes

### Todos os testes

```bash
./run-tests.sh
```

### Apenas testes unitários

```bash
./mvnw test
```

### Apenas testes de integração

```bash
./mvnw verify
```

### Teste específico

```bash
./mvnw test -Dtest=VehicleServiceTest
```

---

## Verificando Health e Métricas

```bash
# Health check geral
curl http://localhost:8082/health

# Liveness (está vivo?)
curl http://localhost:8082/health/live

# Readiness (está pronto?)
curl http://localhost:8082/health/ready

# Métricas Prometheus
curl http://localhost:8082/metrics
```

---

## Logs

### Docker Compose

```bash
# Ver logs em tempo real
docker-compose logs -f vehicle-resale-api

# Logs do PostgreSQL
docker-compose logs -f postgres
```

### Kubernetes

```bash
# Logs da API
kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale

# Logs do PostgreSQL
kubectl logs -f -l app=postgres -n vehicle-resale

# Eventos
kubectl get events -n vehicle-resale --sort-by='.lastTimestamp'
```

---

## Troubleshooting

### Problema: Porta 8082 já está em uso

```bash
# Descobrir o que está usando a porta
lsof -i :8082

# Ou mude a porta no docker-compose.yml
ports:
  - "8081:8082"  # Usar porta 8081 externamente
```

### Problema: PostgreSQL não conecta

```bash
# Verificar se está rodando
docker ps | grep postgres

# Ver logs do PostgreSQL
docker logs vehicle-resale-postgres

# Testar conexão
docker exec -it vehicle-resale-postgres psql -U postgres -d vehicle_resale
```

### Problema: Build falha

```bash
# Limpar e recompilar
./mvnw clean
./mvnw clean package -DskipTests

# Se der erro de memória
export MAVEN_OPTS="-Xmx1024m"
./mvnw clean package
```

### Problema: Kubernetes pods não iniciam

```bash
# Ver status dos pods
kubectl get pods -n vehicle-resale

# Ver detalhes do pod
kubectl describe pod <pod-name> -n vehicle-resale

# Ver logs
kubectl logs <pod-name> -n vehicle-resale

# Verificar eventos
kubectl get events -n vehicle-resale
```

---

## Acessos Rápidos

| Recurso | URL | Descrição |
|---------|-----|-----------|
| API Base | http://localhost:8082 | Endpoint raiz |
| Swagger UI | http://localhost:8082/swagger-ui | Documentação interativa |
| OpenAPI JSON | http://localhost:8082/openapi | Especificação OpenAPI |
| Health Check | http://localhost:8082/health | Status da aplicação |
| Métricas | http://localhost:8082/metrics | Métricas Prometheus |
| Dev UI | http://localhost:8082/q/dev | Interface de dev (modo dev) |

---

## Dados de Exemplo

### Inserir dados de teste

```bash
# Executar script de teste
./TESTE_MELHORIAS.md  # Ver exemplos completos

# Ou manualmente:
curl -X POST http://localhost:8082/api/vehicles \
  -H "Content-Type: application/json" \
  -d '{
    "brand": "Honda",
    "model": "Civic",
    "year": 2022,
    "color": "Preto",
    "price": 110000.00
  }'

curl -X POST http://localhost:8082/api/vehicles \
  -H "Content-Type: application/json" \
  -d '{
    "brand": "Volkswagen",
    "model": "Gol",
    "year": 2021,
    "color": "Branco",
    "price": 55000.00
  }'
```

---

## Limpando o Ambiente

### Docker Compose

```bash
# Parar e remover containers
docker-compose down

# Remover volumes também
docker-compose down -v

# Remover imagens
docker rmi vehicle-resale-api:1.0.0
```

### Kubernetes

```bash
# Remover tudo
cd k8s
./undeploy.sh

# Ou manualmente
kubectl delete namespace vehicle-resale
```

---

## Comandos Úteis

### Maven

```bash
# Compilar
./mvnw clean package

# Compilar sem testes
./mvnw clean package -DskipTests

# Limpar
./mvnw clean

# Ver dependências
./mvnw dependency:tree
```

### Docker

```bash
# Ver containers rodando
docker ps

# Ver todas as imagens
docker images

# Ver logs
docker logs <container-name>

# Entrar no container
docker exec -it <container-name> /bin/sh
```

### Kubernetes

```bash
# Ver todos os recursos
kubectl get all -n vehicle-resale

# Ver pods
kubectl get pods -n vehicle-resale

# Ver services
kubectl get services -n vehicle-resale

# Ver logs
kubectl logs -f <pod-name> -n vehicle-resale

# Port forward (acesso local)
kubectl port-forward -n vehicle-resale service/vehicle-resale-api-service 8082:80
```
---

## Suporte

Para dúvidas:
1. Consulte a documentação no repositório
2. Acesse o Swagger UI para testar interativamente
3. Verifique os logs para debugging

