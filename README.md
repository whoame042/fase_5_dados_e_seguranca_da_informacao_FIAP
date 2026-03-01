# API de Revenda de Veiculos

Sistema de gerenciamento de revenda de veiculos automotores, desenvolvido com Quarkus e pronto para deploy em Kubernetes.

## Sumario

- [Sobre o Projeto](#sobre-o-projeto)
- [Requisitos de Negocio](#requisitos-de-negocio)
- [Arquitetura da Solucao](#arquitetura-da-solucao)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Modelo de Dados](#modelo-de-dados)
- [Pre-requisitos](#pre-requisitos)
- [Instalacao e Execucao Local](#instalacao-e-execucao-local)
- [Autenticacao (Keycloak)](#autenticacao-keycloak)
- [Endpoints da API](#endpoints-da-api)
- [Fluxo Completo de Uso](#fluxo-completo-de-uso)
- [Testando a Compensacao SAGA](#testando-a-compensacao-saga)
- [Testes](#testes)
- [CI/CD](#cicd)
- [Deploy com Kubernetes](#deploy-com-kubernetes)

## Sobre o Projeto

Este projeto foi desenvolvido como parte do Tech Challenge da Pos-Tech FIAP - Arquitetura de Software (SOAT). O sistema permite o gerenciamento completo do ciclo de vida dos veiculos, desde o cadastro ate a venda e processamento de pagamentos.

**Trabalho Substitutivo - Fase 3**

## Requisitos de Negocio

O sistema atende aos seguintes requisitos:

1. **Cadastro de Veiculos**: Cadastrar veiculos para venda com marca, modelo, ano, cor e preco
2. **Edicao de Veiculos**: Permitir a edicao dos dados de veiculos disponiveis
3. **Compra de Veiculos**: Permitir a compra via internet para pessoas cadastradas
4. **Cadastro Previo de Compradores**: O cadastro do cliente deve ser feito ANTES da compra
5. **Listagem de Veiculos a Venda**: Ordenados por preco (mais barato para mais caro)
6. **Listagem de Veiculos Vendidos**: Ordenados por preco (mais barato para mais caro)

### Requisito de Autenticacao Separada

O processo de registro e autorizacao de compradores e feito de forma separada atraves do **Keycloak**, garantindo que os dados de clientes estejam separados dos dados transacionais relacionados as vendas dos veiculos.

## Arquitetura da Solucao

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|   Frontend       +---->+  Vehicle API     +---->+   PostgreSQL     |
|   (Opcional)     |     |  (Quarkus)       |     |   (Transacional) |
|                  |     |                  |     |                  |
+--------+---------+     +--------+---------+     +------------------+
         |                        |
         |                        |
         v                        v
+--------+---------+     +--------+---------+
|                  |     |                  |
|   Keycloak       |     |   PostgreSQL     |
|   (Auth Server)  |     |   (Keycloak)     |
|                  |     |                  |
+------------------+     +------------------+

Servicos Separados:
- API de Veiculos: Dados transacionais (veiculos, vendas)
- Keycloak: Autenticacao e autorizacao de usuarios
```

### Estrutura do Projeto

```
vehicle-resale-api/
├── .github/
│   └── workflows/           # Pipelines CI/CD
│       ├── ci.yml           # Build e testes
│       ├── cd.yml           # Deploy automatizado
│       └── pr-check.yml     # Validacao de Pull Requests
├── keycloak/
│   └── realm-export.json    # Configuracao do realm Keycloak
├── k8s/                     # Manifestos Kubernetes
├── src/main/java/com/vehicleresale/
│   ├── api/
│   │   ├── dto/             # Data Transfer Objects
│   │   ├── resource/        # REST Controllers
│   │   └── exception/       # Exception Handlers
│   ├── application/
│   │   ├── controller/      # Clean Architecture Controllers
│   │   ├── gateway/         # Gateways
│   │   └── presenter/       # Presenters
│   └── domain/
│       ├── entity/          # Entidades JPA (Vehicle, Sale, Customer)
│       ├── repository/      # Repositorios de dados
│       ├── service/         # Regras de negocio
│       └── enums/           # Enumeracoes
└── docker-compose.yml       # Ambiente completo com Keycloak
```

## Tecnologias Utilizadas

- **Quarkus 3.6.4** - Framework Java nativo para Kubernetes
- **Java 17** - Linguagem de programacao
- **Hibernate ORM com Panache** - Persistencia de dados
- **PostgreSQL 15** - Banco de dados relacional
- **Keycloak 23** - Servidor de autenticacao (OAuth2/OIDC)
- **OpenAPI/Swagger** - Documentacao da API
- **Docker** - Containerizacao
- **Kubernetes** - Orquestracao de containers
- **GitHub Actions** - CI/CD
- **Maven** - Gerenciamento de dependencias

## Modelo de Dados

### Entidade Vehicle (Veiculo)
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | Long | Identificador unico |
| brand | String | Marca do veiculo |
| model | String | Modelo do veiculo |
| year | Integer | Ano de fabricacao |
| color | String | Cor do veiculo |
| price | BigDecimal | Preco do veiculo |
| status | VehicleStatus | Status (AVAILABLE, SOLD) |
| createdAt | LocalDateTime | Data de criacao |
| updatedAt | LocalDateTime | Data de atualizacao |

### Entidade Customer (Cliente/Comprador)
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | Long | Identificador unico |
| userId | String | ID do usuario no Keycloak |
| name | String | Nome completo |
| email | String | Email (unico) |
| cpf | String | CPF (unico, 11 digitos) |
| phone | String | Telefone |
| address | String | Endereco |
| city | String | Cidade |
| state | String | Estado (UF) |
| zipCode | String | CEP |
| active | Boolean | Status ativo |

### Entidade Sale (Venda)
| Campo | Tipo | Descricao |
|-------|------|-----------|
| id | Long | Identificador unico |
| vehicle | Vehicle | Veiculo vendido |
| buyerName | String | Nome do comprador |
| buyerEmail | String | Email do comprador |
| buyerCpf | String | CPF do comprador |
| saleDate | LocalDate | Data da venda |
| salePrice | BigDecimal | Preco da venda |
| paymentCode | String | Codigo do pagamento (UUID) |
| paymentStatus | PaymentStatus | Status (PENDING, APPROVED, REJECTED) |

## Pre-requisitos

| Ferramenta | Versao minima | Observacao |
|------------|---------------|------------|
| Java | 17 | Obrigatorio para execucao local sem Docker |
| Maven | 3.8+ | Ou use o wrapper `./mvnw` incluido no projeto |
| Docker | 20.10+ | Obrigatorio para o ambiente local completo |
| Docker Compose | 1.29+ ou v2 | v1: `docker-compose`; v2 (embutido no Docker): `docker compose` |
| curl | qualquer | Para testar endpoints no terminal |
| jq | 1.6+ | Para extrair tokens automaticamente nos exemplos (`apt install jq` / `brew install jq`) |

> **Nota sobre Docker Compose v2:** se o comando `docker-compose` nao for encontrado, use `docker compose` (sem hifen), disponivel no Docker Desktop e no Docker Engine 20.10+.

## Instalacao e Execucao Local

### 1. Clone o repositorio

```bash
git clone <url-do-repositorio>
cd vehicle-resale-api
```

### 2. Iniciar ambiente com Docker Compose

Este comando inicia todos os servicos necessarios:
- PostgreSQL (banco de dados da API)
- Keycloak (servidor de autenticacao)
- PostgreSQL do Keycloak

```bash
docker-compose up -d
```

Aguarde os servicos iniciarem (pode levar alguns minutos na primeira vez).

### 3. Verificar status dos servicos

```bash
docker-compose ps
```

Todos os servicos devem aparecer como `healthy` ou `Up`. O Keycloak pode levar **1-2 minutos** para ficar pronto na primeira execucao (importa o realm automaticamente).

```bash
# Aguardar Keycloak ficar saudavel (repita ate retornar {"status":"UP",...})
curl -s http://localhost:8180/health/ready

# Verificar saude da API (modo dev local ou docker-compose com a API incluida)
curl -s http://localhost:8082/health/ready
# Resposta esperada: {"status":"UP","checks":[...]}
```

### 4. Executar a aplicacao em modo desenvolvimento

**Opção 1: Usando o script automatizado (recomendado)**
```bash
./dev-mode.sh
```

**Opção 2: Usando Maven diretamente**
```bash
./mvnw quarkus:dev
```

**Opção 3: Usando o script maven-build.sh**
```bash
./maven-build.sh quarkus:dev
```

A aplicacao estara disponivel em:
- **API**: http://localhost:8082
- **Swagger UI**: http://localhost:8082/swagger-ui (interface grafica para testar todos os endpoints)
- **OpenAPI JSON**: http://localhost:8082/openapi
- **Health Check**: http://localhost:8082/health/ready
- **Keycloak Console**: http://localhost:8180

> **Dica:** O Swagger UI e a forma mais rapida para um novo desenvolvedor explorar e testar todos os endpoints sem precisar escrever comandos curl. Acesse, clique em "Authorize", cole o Bearer token e execute as requisicoes diretamente pelo navegador.

### Comandos Maven Comuns

| Comando | Descrição |
|---------|-----------|
| `./mvnw clean compile` | Limpa e compila o projeto |
| `./mvnw clean package` | Compila e empacota o projeto (gera JAR) |
| `./mvnw clean install` | Compila, empacota e instala no repositório local |
| `./mvnw quarkus:dev` | Inicia em modo desenvolvimento (hot reload) |
| `./mvnw test` | Executa testes unitários |
| `./mvnw verify` | Executa testes e validações |
| `./mvnw clean package -DskipTests` | Build sem executar testes |

**Usando scripts auxiliares:**
- `./dev-mode.sh` - Inicia em modo desenvolvimento (configura Java/Maven automaticamente)
- `./maven-build.sh <goal>` - Executa Maven com configuração correta de Java/Maven
- `./build-and-deploy.sh` - Build completo e deploy
- `./run-tests.sh` - Executa todos os testes

## Autenticacao (Keycloak)

A autenticacao e feita via **OAuth2/OIDC** pelo Keycloak. A API valida o token JWT em cada requisicao protegida. O realm `vehicle-resale` e importado automaticamente na primeira inicializacao do container Keycloak.

### Acessar Console Administrativo do Keycloak

- URL: http://localhost:8180
- Usuario: `admin`
- Senha: `admin123`

### Usuarios Pre-configurados

| Usuario | Senha | Role | Descricao |
|---------|-------|------|-----------|
| admin@vehicleresale.com | admin123 | admin | Cadastra/edita/exclui veiculos; ve todas as vendas e clientes |
| comprador@teste.com | comprador123 | buyer | Visualiza veiculos, cadastra-se como cliente e realiza compras |

### Obter Token de Acesso (salvar em variavel de ambiente)

```bash
# Token de administrador
ADMIN_TOKEN=$(curl -s -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=admin@vehicleresale.com" \
  -d "password=admin123" | jq -r '.access_token')

echo "Admin token: ${ADMIN_TOKEN:0:50}..."   # exibe os primeiros 50 caracteres

# Token de comprador
BUYER_TOKEN=$(curl -s -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=comprador@teste.com" \
  -d "password=comprador123" | jq -r '.access_token')

echo "Buyer token: ${BUYER_TOKEN:0:50}..."
```

### Obter o userId do Keycloak (necessario para cadastro de cliente)

O campo `userId` da entidade `Customer` deve ser o ID do usuario no Keycloak. Para obtê-lo a partir do proprio token:

```bash
# Decodifica o payload do token e extrai o sub (= userId no Keycloak)
BUYER_USER_ID=$(echo $BUYER_TOKEN | cut -d'.' -f2 | base64 -d 2>/dev/null | jq -r '.sub')
echo "Buyer userId: $BUYER_USER_ID"
```

> O campo `userId` e opcional no cadastro; se omitido, a API aceita o cadastro sem vinculo explicito ao Keycloak.

### Usar Token nas Requisicoes

```bash
curl -X GET "http://localhost:8082/api/customers/me" \
  -H "Authorization: Bearer $BUYER_TOKEN"
```

## Endpoints da API

### Veiculos (Publicos para leitura)

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| GET | /api/vehicles/available | Listar veiculos disponiveis | Nao |
| GET | /api/vehicles/sold | Listar veiculos vendidos | Nao |
| GET | /api/vehicles/{id} | Buscar veiculo por ID | Nao |
| POST | /api/vehicles | Cadastrar veiculo | Sim (admin) |
| PUT | /api/vehicles/{id} | Atualizar veiculo | Sim (admin) |
| DELETE | /api/vehicles/{id} | Excluir veiculo | Sim (admin) |

### Clientes

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| GET | /api/customers | Listar todos os clientes | Sim (admin) |
| GET | /api/customers/{id} | Buscar cliente por ID | Sim |
| GET | /api/customers/me | Buscar meu cadastro | Sim |
| GET | /api/customers/cpf/{cpf} | Buscar cliente por CPF | Sim (admin) |
| GET | /api/customers/check/{cpf} | Verificar se CPF esta cadastrado | Sim |
| POST | /api/customers | Cadastrar novo cliente | Sim |
| PUT | /api/customers/{id} | Atualizar cliente | Sim |
| DELETE | /api/customers/{id} | Desativar cliente | Sim (admin) |

### Vendas

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| GET | /api/sales/{id} | Buscar venda por ID | Sim |
| POST | /api/sales | Efetuar venda | Sim |

### Webhook de Pagamento

| Metodo | Endpoint | Descricao | Autenticacao |
|--------|----------|-----------|--------------|
| POST | /api/webhook/payment | Processar status de pagamento | Nao |

## Fluxo Completo de Uso

O fluxo completo envolve **dois perfis**: o **administrador** (gerencia o estoque de veiculos) e o **comprador** (se cadastra e efetua a compra). Execute os passos abaixo em sequencia.

### Passo 0 — Obter tokens

```bash
# Token do administrador (role: admin)
ADMIN_TOKEN=$(curl -s -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=admin@vehicleresale.com" \
  -d "password=admin123" | jq -r '.access_token')

# Token do comprador (role: buyer)
BUYER_TOKEN=$(curl -s -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api" \
  -d "client_secret=vehicle-resale-secret" \
  -d "grant_type=password" \
  -d "username=comprador@teste.com" \
  -d "password=comprador123" | jq -r '.access_token')
```

### Passo 1 — Cadastrar veiculo (admin)

```bash
VEHICLE_ID=$(curl -s -X POST "http://localhost:8082/api/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2023,
    "color": "Prata",
    "price": 95000.00
  }' | jq -r '.id')

echo "Veiculo criado com ID: $VEHICLE_ID"
```

### Passo 2 — Listar veiculos disponiveis (publico, sem token)

```bash
curl -s "http://localhost:8082/api/vehicles/available" | jq '.[] | {id, brand, model, price, status}'
```

### Passo 3 — Cadastrar cliente/comprador (buyer) — OBRIGATORIO antes da compra

> O sistema exige que o comprador esteja cadastrado com CPF valido antes de efetuar qualquer venda.

```bash
CUSTOMER_ID=$(curl -s -X POST "http://localhost:8082/api/customers" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -d '{
    "name": "Joao Silva",
    "email": "joao@email.com",
    "cpf": "12345678901",
    "phone": "11999999999",
    "address": "Rua Exemplo, 123",
    "city": "Sao Paulo",
    "state": "SP",
    "zipCode": "01234567"
  }' | jq -r '.id')

echo "Cliente cadastrado com ID: $CUSTOMER_ID"
```

### Passo 4 — Efetuar a compra do veiculo (buyer)

O sistema valida que o CPF informado na venda esta cadastrado. Ao criar a venda, o veiculo e marcado como `SOLD` e um `paymentCode` e gerado.

```bash
PAYMENT_CODE=$(curl -s -X POST "http://localhost:8082/api/sales" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -d "{
    \"vehicleId\": $VEHICLE_ID,
    \"buyerName\": \"Joao Silva\",
    \"buyerEmail\": \"joao@email.com\",
    \"buyerCpf\": \"12345678901\",
    \"saleDate\": \"$(date +%Y-%m-%d)\"
  }" | jq -r '.paymentCode')

echo "Codigo de pagamento: $PAYMENT_CODE"
```

### Passo 5 — Processar pagamento aprovado (webhook)

```bash
curl -s -X POST "http://localhost:8082/api/webhook/payment" \
  -H "Content-Type: application/json" \
  -d "{\"paymentCode\": \"$PAYMENT_CODE\", \"paid\": true}" | jq .
```

Resultado esperado: `paymentStatus` passa de `PENDING` para `APPROVED`.

### Passo 6 — Confirmar veiculo como vendido (publico)

```bash
curl -s "http://localhost:8082/api/vehicles/sold" | jq '.[] | {id, brand, model, status}'
```

## Testando a Compensacao SAGA

O sistema implementa **SAGA de compensacao**: se o pagamento for rejeitado, o veiculo e revertido automaticamente para `AVAILABLE` (liberando o estoque). Este e o cenario de falha do fluxo de compra.

### Cenario: pagamento rejeitado → veiculo volta ao estoque

```bash
# 1. Cadastrar um novo veiculo para o teste
VEHICLE2_ID=$(curl -s -X POST "http://localhost:8082/api/vehicles" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"brand":"Honda","model":"Civic","year":2022,"color":"Preto","price":85000.00}' \
  | jq -r '.id')

echo "Veiculo para teste de rejeicao: $VEHICLE2_ID"

# 2. Confirmar que o veiculo esta AVAILABLE
curl -s "http://localhost:8082/api/vehicles/$VEHICLE2_ID" | jq '{id, status}'

# 3. Criar a venda (veiculo passa para SOLD)
PAYMENT_CODE2=$(curl -s -X POST "http://localhost:8082/api/sales" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $BUYER_TOKEN" \
  -d "{
    \"vehicleId\": $VEHICLE2_ID,
    \"buyerName\": \"Joao Silva\",
    \"buyerEmail\": \"joao@email.com\",
    \"buyerCpf\": \"12345678901\",
    \"saleDate\": \"$(date +%Y-%m-%d)\"
  }" | jq -r '.paymentCode')

echo "Payment code: $PAYMENT_CODE2"

# 4. Confirmar que veiculo esta SOLD apos criacao da venda
curl -s "http://localhost:8082/api/vehicles/$VEHICLE2_ID" | jq '{id, status}'
# Esperado: status = "SOLD"

# 5. Simular pagamento REJEITADO (paid: false)
curl -s -X POST "http://localhost:8082/api/webhook/payment" \
  -H "Content-Type: application/json" \
  -d "{\"paymentCode\": \"$PAYMENT_CODE2\", \"paid\": false}" | jq .
# Esperado: paymentStatus = "REJECTED"

# 6. Verificar compensacao: veiculo deve estar AVAILABLE novamente
curl -s "http://localhost:8082/api/vehicles/$VEHICLE2_ID" | jq '{id, status}'
# Esperado: status = "AVAILABLE" (compensacao SAGA executada com sucesso)
```

> **Como funciona:** `SaleService.updatePaymentStatus()` detecta `paid=false`, persiste `REJECTED` e chama `VehicleController.markAsAvailable()`, revertendo o veículo ao estoque. Ver `docs/RELATORIO_SAGA_FASE5.md` para detalhes completos.

## Testes

### Executar todos os testes unitarios

```bash
./mvnw test
```

### Executar testes com relatorio de cobertura (JaCoCo)

```bash
./mvnw verify
# Relatorio gerado em: target/site/jacoco/index.html
```

### Executar testes via script auxiliar

```bash
./run-tests.sh
```

### Teste end-to-end (script automatizado)

O projeto inclui um script que executa o fluxo completo de ponta a ponta com curl:

```bash
./test-e2e.sh
```

### Estrutura dos testes

```
src/test/java/com/vehicleresale/
├── domain/service/
│   ├── VehicleServiceTest.java    # Testes unitarios do servico de veiculos
│   ├── CustomerServiceTest.java   # Testes unitarios do servico de clientes
│   └── SaleServiceTest.java       # Testes unitarios do servico de vendas
│                                  # (inclui teste da compensacao SAGA)
└── api/resource/
    └── ...                        # Testes de integracao dos endpoints REST
```

## CI/CD

O projeto possui pipelines automatizados com GitHub Actions:

### Pipeline de CI (ci.yml)
- Executa em push/PR para branches main e develop
- Build do projeto
- Execucao de testes
- Verificacao de qualidade do codigo

### Pipeline de CD (cd.yml)
- Executa em push para main ou tags de versao
- Build da imagem Docker
- Push para GitHub Container Registry
- Deploy automatizado em staging/producao

### Pipeline de PR (pr-check.yml)
- Validacao de Pull Requests
- Lint e validacao
- Testes unitarios
- Build da imagem Docker (sem push)
- Scan de seguranca

### Configurar Deploy Automatico

1. Configure os secrets no repositorio GitHub:
   - `KUBECONFIG`: Configuracao do cluster Kubernetes

2. Configure os environments no GitHub:
   - `staging`: Para deploys em ambiente de staging
   - `production`: Para deploys em producao (requer aprovacao)

## Deploy com Kubernetes

### Deploy Local (Minikube) - Modo Automatico ✅

Use o script automatizado (recomendado):

```bash
./deploy-minikube-auto.sh
```

Este script faz:
- ✅ Verifica e inicia o Minikube
- ✅ Compila a aplicacao
- ✅ Cria a imagem Docker
- ✅ Aplica recursos do Kubernetes
- ✅ Aguarda todos os pods ficarem prontos
- ✅ Mostra instrucoes de acesso

**Tempo estimado:** 5-10 minutos (primeira vez)

### Deploy Manual (Minikube)

Se preferir fazer passo a passo:

```bash
# 1. Iniciar Minikube
minikube start --driver=docker --memory=4096 --cpus=2

# 2. Configurar Docker do Minikube
eval $(minikube docker-env)

# 3. Build da aplicacao
./mvnw clean package -DskipTests
./mvnw quarkus:build -DskipTests

# 4. Build da imagem Docker
docker build -t vehicle-resale-api:1.0.1 .

# 5. Criar ConfigMap do Keycloak
kubectl create configmap keycloak-realm-config \
  --from-file=realm-export.json=keycloak/realm-export.json \
  -n vehicle-resale

# 6. Deploy dos recursos
cd k8s
kubectl apply -k .
cd ..

# 7. Aguardar pods
kubectl wait --for=condition=ready pod -l app=vehicle-resale-api -n vehicle-resale --timeout=120s
```

### Acessar a Aplicacao no Kubernetes

**Terminal 1 - API:**
```bash
kubectl port-forward -n vehicle-resale svc/vehicle-resale-api-service 8082:80
```
Acesse: http://localhost:8082/swagger-ui

**Terminal 2 - Keycloak:**
```bash
kubectl port-forward -n vehicle-resale svc/keycloak-service 8180:8180
```
Acesse: http://localhost:8180 (admin/admin123)

**Ver Status:**
```bash
kubectl get all -n vehicle-resale
kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale
```

Para detalhes adicionais sobre acesso e depuracao no Kubernetes, consulte os manifestos em `k8s/`.

### Deploy em Cloud

Consulte os overlays disponiveis em `k8s/overlays/` para:
- AWS (EKS)
- Azure (AKS)
- GCP (GKE)

## Troubleshooting

### Keycloak nao inicia ou fica em loop

```bash
# Ver logs em tempo real
docker-compose logs -f keycloak

# Aguardar o realm ser importado (normal levar 60-120s na primeira vez)
# Mensagem de sucesso esperada nos logs: "Realm vehicle-resale imported"

# Se travar, reiniciar apenas o Keycloak
docker-compose restart keycloak
```

### Erro de conexao com banco de dados (`Connection refused` ou `FATAL`)

```bash
# Verificar se PostgreSQL da API esta rodando e healthy
docker-compose ps postgres

# Ver logs do banco
docker-compose logs postgres

# Verificar porta exposta (padrao: 5433 no host -> 5432 no container)
# A aplicacao local (./mvnw quarkus:dev) conecta em localhost:5433
# Dentro do Docker Compose, a API conecta em postgres:5432
```

### Token invalido, expirado ou `401 Unauthorized`

```bash
# Tokens expiram apos alguns minutos. Obtenha um novo:
ADMIN_TOKEN=$(curl -s -X POST "http://localhost:8180/realms/vehicle-resale/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=vehicle-resale-api&client_secret=vehicle-resale-secret&grant_type=password&username=admin@vehicleresale.com&password=admin123" \
  | jq -r '.access_token')
```

### Erro `403 Forbidden` em endpoints de veiculos (POST/PUT/DELETE)

Esses endpoints exigem role `admin`. Certifique-se de usar o `ADMIN_TOKEN` (nao o `BUYER_TOKEN`):

```bash
# Correto: usa token com role admin
curl -X POST "http://localhost:8082/api/vehicles" \
  -H "Authorization: Bearer $ADMIN_TOKEN" ...
```

### Erro `400 Bad Request` ao criar venda ("CPF nao cadastrado")

O CPF informado na venda deve estar previamente cadastrado em `/api/customers`. Execute o Passo 3 do Fluxo Completo antes de tentar criar a venda.

### Aplicacao nao conecta ao Keycloak (`OIDC server not available`)

```bash
# Verificar se o Keycloak esta acessivel
curl -s http://localhost:8180/realms/vehicle-resale/.well-known/openid-configuration | jq .issuer

# Se rodar a API fora do Docker Compose (modo dev), garantir que a URL do OIDC aponta para localhost:
# Em application.properties: quarkus.oidc.auth-server-url=http://localhost:8180/realms/vehicle-resale
```

### Resetar todo o ambiente (dados e containers)

```bash
# Para e remove containers + volumes (apaga todos os dados)
docker-compose down -v

# Sobe novamente do zero
docker-compose up -d
```

## Seguranca

- Autenticacao via OAuth2/OIDC (Keycloak 23)
- Tokens JWT para autorizacao (roles: `admin`, `buyer`)
- Endpoints publicos: listagem de veiculos disponiveis/vendidos, health, swagger
- Endpoints protegidos (autenticado): clientes, vendas
- Endpoints restritos (role admin): criar/editar/excluir veiculos
- Senhas armazenadas em Secrets do Kubernetes em producao
- Aplicacao roda como usuario nao-root (UID 185) no container
- Validacoes de entrada (Bean Validation) em todos os DTOs

## Documentacao Adicional (Fase 5)

| Documento | Descricao |
|-----------|-----------|
| `docs/ARQUITETURA_FASE5.md` | Desenho da arquitetura, servicos de nuvem (AWS) e decisoes arquiteturais |
| `docs/RELATORIO_SEGURANCA_DADOS_FASE5.md` | Dados sensiveis, politicas de acesso, riscos e LGPD |
| `docs/RELATORIO_SAGA_FASE5.md` | Tipo de SAGA utilizada (compensacao), justificativa e implementacao |
| `docs/FASE_5_VALIDACAO_REQUISITOS.md` | Checklist completo de requisitos atendidos |
| `docs/MCP_SETUP.md` | Configuracao dos perfis MCP para agentes SDLC |
| `mcp-profiles/` | Perfis MCP especializados (Backend, Arquiteto, QA, DevOps) |

## Licenca

Projeto desenvolvido para fins educacionais - FIAP Pos-Tech Arquitetura de Software.
