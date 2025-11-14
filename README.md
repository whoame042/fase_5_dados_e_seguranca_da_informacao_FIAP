# API de Revenda de Veículos

Sistema de gerenciamento de revenda de veículos automotores, desenvolvido com Quarkus e pronto para deploy em Kubernetes.

## Sumário

- [Sobre o Projeto](#sobre-o-projeto)
- [Tecnologias Utilizadas](#tecnologias-utilizadas)
- [Arquitetura da Solução](#arquitetura-da-solução)
- [Modelo de Dados](#modelo-de-dados)
- [Funcionalidades](#funcionalidades)
- [Pré-requisitos](#pré-requisitos)
- [Instalação e Execução](#instalação-e-execução)
- [Build e Deploy com Kubernetes](#build-e-deploy-com-kubernetes)
- [Documentação da API](#documentação-da-api)
- [Endpoints da API](#endpoints-da-api)

## Sobre o Projeto

Este projeto foi desenvolvido para atender as necessidades de uma empresa de revenda de veículos automotores que deseja implantar uma plataforma na internet. O sistema permite o gerenciamento completo do ciclo de vida dos veículos, desde o cadastro até a venda e processamento de pagamentos.

## Tecnologias Utilizadas

- **Quarkus 3.6.4** - Framework Java nativo para Kubernetes
- **Java 17** - Linguagem de programação
- **Hibernate ORM com Panache** - Persistência de dados
- **PostgreSQL 15** - Banco de dados relacional
- **OpenAPI/Swagger** - Documentação da API
- **Docker** - Containerização
- **Kubernetes** - Orquestração de containers
- **Maven** - Gerenciamento de dependências

## Arquitetura da Solução

O projeto segue uma arquitetura em camadas:

```
vehicle-resale-api/
├── src/main/java/com/vehicleresale/
│   ├── api/
│   │   ├── dto/              # Data Transfer Objects
│   │   ├── resource/         # REST Controllers
│   │   └── exception/        # Exception Handlers
│   └── domain/
│       ├── entity/           # Entidades JPA
│       ├── repository/       # Repositórios de dados
│       ├── service/          # Regras de negócio
│       └── enums/            # Enumerações
└── k8s/                      # Manifestos Kubernetes
```

## Modelo de Dados

### Entidade Vehicle (Veículo)
- `id` (Long) - Identificador único
- `brand` (String) - Marca do veículo
- `model` (String) - Modelo do veículo
- `year` (Integer) - Ano de fabricação
- `color` (String) - Cor do veículo
- `price` (BigDecimal) - Preço do veículo
- `status` (VehicleStatus) - Status (AVAILABLE, SOLD)
- `createdAt` (LocalDateTime) - Data de criação
- `updatedAt` (LocalDateTime) - Data de atualização

### Entidade Sale (Venda)
- `id` (Long) - Identificador único
- `vehicle` (Vehicle) - Veículo vendido
- `buyerCpf` (String) - CPF do comprador
- `saleDate` (LocalDate) - Data da venda
- `salePrice` (BigDecimal) - Preço da venda
- `paymentCode` (String) - Código do pagamento
- `paymentStatus` (PaymentStatus) - Status do pagamento (PENDING, PAID, CANCELLED)
- `createdAt` (LocalDateTime) - Data de criação
- `updatedAt` (LocalDateTime) - Data de atualização

## Funcionalidades

1. **Cadastro de Veículos**
   - Cadastrar um veículo com marca, modelo, ano, cor e preço
   - Editar dados de veículos disponíveis
   - Excluir veículos não vendidos

2. **Gerenciamento de Vendas**
   - Efetuar venda de veículo informando CPF do comprador e data
   - Geração automática de código de pagamento
   - Mudança automática do status do veículo para "vendido"

3. **Listagens**
   - Listar veículos disponíveis para venda (ordenados por preço crescente)
   - Listar veículos vendidos (ordenados por preço crescente)

4. **Webhook de Pagamento**
   - Endpoint para processamento de pagamentos
   - Atualização do status do pagamento (pago ou cancelado)

5. **Documentação e Monitoramento**
   - Documentação OpenAPI/Swagger disponível em `/swagger-ui`
   - Health checks em `/health`
   - Métricas Prometheus em `/metrics`

## Pré-requisitos

- Java 17 ou superior
- Maven 3.8+
- Docker
- Kubernetes (minikube, k3s, ou cluster cloud)
- kubectl configurado

## Instalação e Execução

### Execução Local (Desenvolvimento)

1. **Clone o repositório:**
```bash
cd vehicle-resale-api
```

2. **Configure o banco de dados PostgreSQL:**
```bash
docker run --name postgres-vehicle -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=vehicle_resale -p 5432:5432 -d postgres:15-alpine
```

3. **Execute a aplicação em modo desenvolvimento:**
```bash
./mvnw quarkus:dev
```

A aplicação estará disponível em `http://localhost:8080`

### Compilação do Projeto

Para compilar o projeto:
```bash
./mvnw clean package
```

O arquivo JAR será gerado em `target/quarkus-app/`

## Build e Deploy com Kubernetes

### Opção 1: Deploy Automatizado (Recomendado)

Use o script automatizado que faz build e deploy:

```bash
chmod +x build-and-deploy.sh
./build-and-deploy.sh
```

### Opção 2: Deploy Manual

#### 1. Build da Aplicação
```bash
./mvnw clean package -DskipTests
```

#### 2. Construir Imagem Docker
```bash
docker build -t vehicle-resale-api:1.0.0 .
```

#### 3. Deploy no Kubernetes

Entre no diretório k8s e aplique os manifestos:

```bash
cd k8s
chmod +x deploy.sh
./deploy.sh
```

Ou aplique manualmente na ordem:

```bash
# Criar namespace
kubectl apply -f namespace.yaml

# PostgreSQL
kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-pvc.yaml
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Aplicação
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

### Verificar o Deploy

```bash
# Ver pods
kubectl get pods -n vehicle-resale

# Ver services
kubectl get services -n vehicle-resale

# Ver logs
kubectl logs -f -l app=vehicle-resale-api -n vehicle-resale
```

### Acessar a Aplicação

Para obter o IP/URL de acesso:

```bash
kubectl get service vehicle-resale-api-service -n vehicle-resale
```

Se estiver usando minikube:
```bash
minikube service vehicle-resale-api-service -n vehicle-resale
```

### Remover o Deploy

```bash
cd k8s
chmod +x undeploy.sh
./undeploy.sh
```

## Documentação da API

A documentação completa da API está disponível através do Swagger UI:

- **Swagger UI:** `http://<host>/swagger-ui`
- **OpenAPI JSON:** `http://<host>/openapi`

## Endpoints da API

### Veículos

#### Listar veículos disponíveis
```http
GET /api/vehicles/available
```
Retorna todos os veículos disponíveis para venda, ordenados por preço (do mais barato para o mais caro).

**Resposta de Sucesso:** `200 OK`
```json
[
  {
    "id": 1,
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2023,
    "color": "Prata",
    "price": 95000.00,
    "status": "AVAILABLE",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T10:30:00"
  }
]
```

#### Listar veículos vendidos
```http
GET /api/vehicles/sold
```
Retorna todos os veículos vendidos, ordenados por preço (do mais barato para o mais caro).

**Resposta de Sucesso:** `200 OK`

#### Buscar veículo por ID
```http
GET /api/vehicles/{id}
```

**Resposta de Sucesso:** `200 OK`

**Resposta de Erro:** `404 Not Found`

#### Cadastrar novo veículo
```http
POST /api/vehicles
Content-Type: application/json
```

**Body:**
```json
{
  "brand": "Toyota",
  "model": "Corolla",
  "year": 2023,
  "color": "Prata",
  "price": 95000.00
}
```

**Resposta de Sucesso:** `201 Created`

**Validações:**
- `brand`: obrigatório, máximo 100 caracteres
- `model`: obrigatório, máximo 100 caracteres
- `year`: obrigatório, entre 1900 e 2100
- `color`: obrigatório, máximo 50 caracteres
- `price`: obrigatório, maior que 0

#### Atualizar veículo
```http
PUT /api/vehicles/{id}
Content-Type: application/json
```

**Body:** Mesmo formato do cadastro

**Resposta de Sucesso:** `200 OK`

**Resposta de Erro:** 
- `404 Not Found` - Veículo não encontrado
- `400 Bad Request` - Veículo já vendido ou dados inválidos

#### Excluir veículo
```http
DELETE /api/vehicles/{id}
```

**Resposta de Sucesso:** `204 No Content`

**Resposta de Erro:**
- `404 Not Found` - Veículo não encontrado
- `400 Bad Request` - Não é possível excluir veículo já vendido

### Vendas

#### Buscar venda por ID
```http
GET /api/sales/{id}
```

**Resposta de Sucesso:** `200 OK`
```json
{
  "id": 1,
  "vehicle": {
    "id": 1,
    "brand": "Toyota",
    "model": "Corolla",
    "year": 2023,
    "color": "Prata",
    "price": 95000.00,
    "status": "SOLD",
    "createdAt": "2024-01-15T10:30:00",
    "updatedAt": "2024-01-15T11:00:00"
  },
  "buyerCpf": "12345678901",
  "saleDate": "2024-01-15",
  "salePrice": 95000.00,
  "paymentCode": "550e8400-e29b-41d4-a716-446655440000",
  "paymentStatus": "PENDING",
  "createdAt": "2024-01-15T11:00:00",
  "updatedAt": "2024-01-15T11:00:00"
}
```

#### Efetuar venda de veículo
```http
POST /api/sales
Content-Type: application/json
```

**Body:**
```json
{
  "vehicleId": 1,
  "buyerCpf": "12345678901",
  "saleDate": "2024-01-15"
}
```

**Resposta de Sucesso:** `201 Created` (retorna objeto Sale com paymentCode gerado)

**Validações:**
- `vehicleId`: obrigatório
- `buyerCpf`: obrigatório, 11 dígitos numéricos
- `saleDate`: obrigatório

**Resposta de Erro:**
- `404 Not Found` - Veículo não encontrado
- `400 Bad Request` - Veículo já vendido

### Webhook de Pagamento

#### Processar status de pagamento
```http
POST /api/webhook/payment
Content-Type: application/json
```

**Body:**
```json
{
  "paymentCode": "550e8400-e29b-41d4-a716-446655440000",
  "paid": true
}
```

**Campos:**
- `paymentCode`: Código do pagamento gerado na venda
- `paid`: `true` para pagamento efetuado, `false` para cancelado

**Resposta de Sucesso:** `200 OK` (retorna objeto Sale atualizado)

**Resposta de Erro:**
- `404 Not Found` - Código de pagamento não encontrado
- `400 Bad Request` - Pagamento já foi processado

### Health Check e Métricas

#### Health Check
```http
GET /health
GET /health/live
GET /health/ready
```

#### Métricas Prometheus
```http
GET /metrics
```

## Configurações do Kubernetes

### ConfigMap
O ConfigMap contém as configurações da aplicação:
- Porta da aplicação
- URL do banco de dados
- Configurações do Hibernate
- Níveis de log

### Secret
Os Secrets contêm informações sensíveis:
- Senha do banco de dados (base64 encoded)

**Nota:** Em produção, sempre altere as senhas padrão!

### Deployment
O Deployment define:
- 2 réplicas da aplicação
- Resources (requests e limits)
- Probes de liveness e readiness
- Variáveis de ambiente

### Service
O Service expõe a aplicação:
- Tipo: LoadBalancer
- Porta externa: 80
- Porta interna: 8080

### PostgreSQL
Deploy completo do PostgreSQL incluindo:
- ConfigMap e Secret
- PersistentVolumeClaim (5Gi)
- Deployment com probes
- Service interno (ClusterIP)

## Estrutura de Arquivos Kubernetes

```
k8s/
├── namespace.yaml              # Namespace vehicle-resale
├── configmap.yaml              # Configurações da aplicação
├── secret.yaml                 # Secrets da aplicação
├── deployment.yaml             # Deployment da aplicação
├── service.yaml                # Service da aplicação (LoadBalancer)
├── postgres-configmap.yaml     # Configurações do PostgreSQL
├── postgres-secret.yaml        # Secrets do PostgreSQL
├── postgres-pvc.yaml           # PersistentVolumeClaim
├── postgres-deployment.yaml    # Deployment do PostgreSQL
├── postgres-service.yaml       # Service do PostgreSQL (ClusterIP)
├── deploy.sh                   # Script de deploy
└── undeploy.sh                 # Script de remoção
```

## Recursos e Limites

### Aplicação
- **Requests:** 512Mi memória, 500m CPU
- **Limits:** 1Gi memória, 1000m CPU

### PostgreSQL
- **Requests:** 256Mi memória, 250m CPU
- **Limits:** 512Mi memória, 500m CPU

## Desenvolvimento

### Executar testes
```bash
./mvnw test
```

### Modo de desenvolvimento com live reload
```bash
./mvnw quarkus:dev
```

### Formato do código
```bash
./mvnw spotless:apply
```

## Troubleshooting

### Pods não iniciam
```bash
kubectl describe pod <pod-name> -n vehicle-resale
kubectl logs <pod-name> -n vehicle-resale
```

### Verificar conectividade com banco de dados
```bash
kubectl exec -it <app-pod-name> -n vehicle-resale -- /bin/sh
# Dentro do pod
curl postgres-service:5432
```

### Verificar configurações
```bash
kubectl get configmap vehicle-resale-config -n vehicle-resale -o yaml
kubectl get secret vehicle-resale-secret -n vehicle-resale -o yaml
```

## Segurança

- As senhas estão armazenadas em Secrets do Kubernetes
- A aplicação roda como usuário não-root (UID 185)
- CORS configurado para desenvolvimento (ajustar para produção)
- Validações de entrada em todos os endpoints

## Melhorias Futuras

- Implementar autenticação e autorização (JWT)
- Adicionar paginação nas listagens
- Implementar cache com Redis
- Adicionar testes de integração
- Implementar CI/CD com GitHub Actions ou GitLab CI
- Adicionar observabilidade com Jaeger/OpenTelemetry
- Implementar backup automático do banco de dados
- Adicionar HPA (Horizontal Pod Autoscaler)

## Suporte

Para dúvidas ou problemas, consulte a documentação do Swagger ou entre em contato com a equipe de desenvolvimento.

## Licença

Projeto desenvolvido para fins educacionais - FIAP Pós-Tech Arquitetura de Software.

