# Guia de Desenvolvimento Local

## Inicio Rápido

### Opção 1: Gerenciador Interativo (Mais Fácil)
```bash
./manage-dev.sh
```
Menu interativo que permite:
- Iniciar/parar containers
- Ver logs e status
- Conectar ao banco
- Iniciar Quarkus
- Gerenciar todo o ambiente

### Opção 2: Script Automático (Mais Rápido)
```bash
./start-dev.sh
```
Este script:
1. Inicia o PostgreSQL via Docker Compose
2. Aguarda o banco ficar pronto
3. Verifica se há dados carregados
4. Inicia o Quarkus automaticamente

### Opção 3: Manual
```bash
# 1. Iniciar PostgreSQL
docker-compose up -d postgres

# 2. Aguardar alguns segundos
sleep 10

# 3. Iniciar Quarkus
./dev-mode.sh
```

### Opção 3: Comando Maven Direto
```bash
# Com PostgreSQL já rodando
mvn clean quarkus:dev \
  -Dquarkus.http.port=8082 \
  -Dquarkus.datasource.jdbc.url=jdbc:postgresql://localhost:5433/vehicle_resale \
  -Dquarkus.datasource.username=postgres \
  -Dquarkus.datasource.password=postgres123 \
  -DskipTests
```

## Configuração

### Portas
- **API**: `localhost:8082`
- **PostgreSQL**: `localhost:5433` (externa) → `5432` (interna)

### Credenciais do Banco
- **Host**: `localhost:5433`
- **Database**: `vehicle_resale`
- **User**: `postgres`
- **Password**: `postgres123`

## URLs Importantes

| Serviço | URL | Descrição |
|---------|-----|-----------|
| Swagger UI | http://localhost:8082/swagger-ui | Documentação interativa da API |
| Dev UI | http://localhost:8082/q/dev | Interface de desenvolvimento do Quarkus |
| Health Check | http://localhost:8082/health/ready | Status da aplicação |
| Veículos | http://localhost:8082/api/vehicles/available | Lista de veículos disponíveis |

## Comandos Úteis

### Verificar Status
```bash
# Status dos containers
docker-compose ps

# Logs do PostgreSQL
docker-compose logs postgres

# Logs em tempo real
docker-compose logs -f postgres

# Verificar dados no banco
docker exec vehicle-resale-postgres psql -U postgres -d vehicle_resale -c "SELECT COUNT(*) FROM vehicles;"
```

### Reiniciar Serviços
```bash
# Reiniciar PostgreSQL
docker-compose restart postgres

# Parar tudo
docker-compose down

# Limpar volumes (CUIDADO: apaga dados)
docker-compose down -v
```

### Testar API
```bash
# Health check
curl http://localhost:8082/health/ready

# Listar veículos
curl http://localhost:8082/api/vehicles/available | jq .

# Criar venda
curl -X POST http://localhost:8082/api/sales \
  -H "Content-Type: application/json" \
  -d '{
    "vehicleId": 3,
    "buyerName": "João Silva",
    "buyerEmail": "joao@email.com",
    "buyerCpf": "123.456.789-00",
    "saleDate": "2024-01-15"
  }'
```

## Resolução de Problemas

### Erro: "Port 8082 already in use"
```bash
# Encontrar processo usando a porta
lsof -i :8082

# Matar processo
kill -9 <PID>
```

### Erro: "UnknownHostException: postgres"
O script `dev-mode.sh` já resolve isso passando as propriedades explícitas. Se ainda ocorrer:
```bash
# Limpar cache
rm -rf target/ .quarkus/

# Iniciar novamente
./dev-mode.sh
```

### Erro: "Connection refused" ao PostgreSQL
```bash
# Verificar se PostgreSQL está rodando
docker-compose ps

# Reiniciar PostgreSQL
docker-compose restart postgres

# Ver logs
docker-compose logs postgres
```

### Banco de dados vazio
```bash
# Reiniciar com dados iniciais
docker-compose down -v
docker-compose up -d postgres
```

## Live Reload

O Quarkus possui live reload automático. Ao salvar alterações nos arquivos `.java`, a aplicação recompila automaticamente.

Para forçar rebuild:
- No terminal do Quarkus, pressione `s` (scan) ou `r` (rebuild)

## Parar Desenvolvimento

```bash
# Parar Quarkus: Ctrl+C no terminal

# Parar PostgreSQL (mantém dados)
docker-compose stop postgres

# Parar e remover tudo (mantém dados)
docker-compose down

# Parar e remover TUDO incluindo dados
docker-compose down -v
```

## Estrutura de Arquivos Importante

```
vehicle-resale-api/
├── dev-mode.sh              # Script para iniciar Quarkus
├── start-dev.sh             # Script completo (PostgreSQL + Quarkus)
├── docker-compose.yml       # Definição do PostgreSQL
├── init-data.sql            # Dados iniciais (usado no primeiro start)
└── src/
    └── main/
        └── resources/
            └── application.properties  # Configuração base
```

## Dicas

1. **Primeira vez**: Use `./start-dev.sh` para garantir que tudo seja configurado corretamente
2. **Desenvolvimento diário**: Use `./dev-mode.sh` se o PostgreSQL já estiver rodando
3. **Problemas de cache**: Sempre limpe com `rm -rf target/ .quarkus/` antes de iniciar
4. **Performance**: Use `-DskipTests` para compilar mais rápido durante desenvolvimento

## Requisitos

- Java 21
- Maven 3.9.6
- Docker e Docker Compose
- curl (para testes)
- jq (opcional, para formatação JSON)

## Gerenciamento de Containers

### Scripts Disponíveis

| Script | Descrição | Uso |
|--------|-----------|-----|
| `manage-dev.sh` | Gerenciador interativo | Menu completo para gerenciar tudo |
| `start-dev.sh` | Inicia ambiente completo | Containers + Quarkus automaticamente |
| `dev-mode.sh` | Apenas Quarkus | Para quando containers já estão rodando |

### Adicionar Novos Containers

Para adicionar serviços como Redis, Mailhog, etc:

1. **Edite `docker-compose.yml` ou `docker-compose.dev.yml`**:
```yaml
services:
  redis:
    image: redis:7-alpine
    container_name: vehicle-resale-redis-dev
    ports:
      - "6379:6379"
    networks:
      - vehicle-resale-network
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5
    restart: unless-stopped
```

2. **Inicie o novo serviço**:
```bash
docker-compose up -d redis
```

3. **Verifique se está rodando**:
```bash
docker-compose ps
```

### Containers Opcionais Pré-configurados

O arquivo `docker-compose.dev.yml` já contém configurações comentadas para:

- **Redis**: Cache em memória
- **Mailhog**: Servidor SMTP para testes de email
- **pgAdmin**: Interface web para PostgreSQL

Para habilitar, descomente no arquivo e execute:
```bash
docker-compose -f docker-compose.dev.yml up -d
```

## Arquivos de Configuração

```
vehicle-resale-api/
├── docker-compose.yml          # Configuração básica (PostgreSQL)
├── docker-compose.dev.yml      # Configuração completa com serviços opcionais
├── manage-dev.sh               # Gerenciador interativo
├── start-dev.sh                # Inicialização automática
├── dev-mode.sh                 # Apenas Quarkus
└── GUIA_DEV_LOCAL.md          # Este guia
```

## Fluxo de Trabalho Recomendado

### Primeira Vez
```bash
./start-dev.sh
```

### Dia a Dia
```bash
# Se containers já estão rodando
./dev-mode.sh

# Ou use o gerenciador
./manage-dev.sh
```

### Problemas?
```bash
# Use o gerenciador interativo
./manage-dev.sh
# Opção 6: Ver status
# Opção 4: Ver logs
# Opção 3: Reiniciar containers
```

## Suporte

Para mais informações, consulte:
- `README.md` - Documentação completa do projeto
- `INSTRUCOES_USO.md` - Instruções detalhadas de uso
- `ARCHITECTURE.md` - Arquitetura do projeto
- `docker-compose.dev.yml` - Exemplos de containers adicionais

