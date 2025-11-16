# Arquitetura da Solução - API de Revenda de Veículos

## Visão Geral

A API de Revenda de Veículos foi desenvolvida seguindo os princípios da **Clean Architecture** e **Domain-Driven Design (DDD)**, utilizando Quarkus como framework e preparada para deploy em ambientes Kubernetes.

## Diagrama de Arquitetura

```
┌─────────────────────────────────────────────────────────────┐
│                      KUBERNETES CLUSTER                      │
│                                                               │
│  ┌────────────────────────────────────────────────────────┐ │
│  │              LoadBalancer Service (Port 80)             │ │
│  └───────────────────────┬────────────────────────────────┘ │
│                          │                                   │
│  ┌───────────────────────▼────────────────────────────────┐ │
│  │          Vehicle Resale API Pods (x2 replicas)         │ │
│  │                                                          │ │
│  │  ┌──────────────────────────────────────────────────┐  │ │
│  │  │         Quarkus Application (Port 8082)          │  │ │
│  │  │                                                    │  │ │
│  │  │  ┌─────────────────────────────────────────────┐ │  │ │
│  │  │  │         API Layer (Resources)               │ │  │ │
│  │  │  │  - VehicleResource                          │ │  │ │
│  │  │  │  - SaleResource                             │ │  │ │
│  │  │  │  - PaymentWebhookResource                   │ │  │ │
│  │  │  └──────────────┬──────────────────────────────┘ │  │ │
│  │  │                 │                                 │  │ │
│  │  │  ┌──────────────▼──────────────────────────────┐ │  │ │
│  │  │  │       Service Layer (Business Logic)        │ │  │ │
│  │  │  │  - VehicleService                           │ │  │ │
│  │  │  │  - SaleService                              │ │  │ │
│  │  │  └──────────────┬──────────────────────────────┘ │  │ │
│  │  │                 │                                 │  │ │
│  │  │  ┌──────────────▼──────────────────────────────┐ │  │ │
│  │  │  │     Repository Layer (Data Access)          │ │  │ │
│  │  │  │  - VehicleRepository                        │ │  │ │
│  │  │  │  - SaleRepository                           │ │  │ │
│  │  │  │  (Hibernate ORM with Panache)               │ │  │ │
│  │  │  └──────────────┬──────────────────────────────┘ │  │ │
│  │  └─────────────────┼──────────────────────────────────┘  │ │
│  └────────────────────┼─────────────────────────────────────┘ │
│                       │                                        │
│                       │ JDBC                                   │
│                       │                                        │
│  ┌────────────────────▼─────────────────────────────────────┐ │
│  │              ClusterIP Service (Port 5432)                │ │
│  └───────────────────────┬───────────────────────────────────┘ │
│                          │                                      │
│  ┌───────────────────────▼───────────────────────────────────┐ │
│  │            PostgreSQL Pod                                  │ │
│  │                                                             │ │
│  │  ┌──────────────────────────────────────────────────────┐ │ │
│  │  │        PostgreSQL 15 Alpine                          │ │ │
│  │  │        Database: vehicle_resale                      │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  │                          │                                 │ │
│  │  ┌───────────────────────▼──────────────────────────────┐ │ │
│  │  │        PersistentVolume (5Gi)                        │ │ │
│  │  └──────────────────────────────────────────────────────┘ │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              ConfigMaps & Secrets                         │  │
│  │  - vehicle-resale-config    - postgres-config            │  │
│  │  - vehicle-resale-secret    - postgres-secret            │  │
│  └──────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

## Camadas da Aplicação

### 1. API Layer (Camada de Apresentação)

**Responsabilidade:** Expor endpoints REST e validar requisições HTTP.

**Componentes:**
- `VehicleResource`: Endpoints para gerenciamento de veículos
- `SaleResource`: Endpoints para gerenciamento de vendas
- `PaymentWebhookResource`: Webhook para processamento de pagamentos
- `GlobalExceptionHandler`: Tratamento centralizado de exceções

**Tecnologias:**
- RESTEasy Reactive
- JAX-RS annotations
- Bean Validation
- OpenAPI/Swagger

**Características:**
- Validação de entrada com annotations (`@Valid`, `@NotNull`, etc.)
- Documentação automática com OpenAPI
- Respostas padronizadas (DTOs)
- Tratamento de erros centralizado

### 2. Service Layer (Camada de Negócio)

**Responsabilidade:** Implementar regras de negócio e orquestrar operações.

**Componentes:**
- `VehicleService`: Lógica de negócio para veículos
- `SaleService`: Lógica de negócio para vendas

**Regras de Negócio Implementadas:**
- Não permitir edição de veículos já vendidos
- Não permitir exclusão de veículos já vendidos
- Marcar veículo como vendido automaticamente ao criar venda
- Gerar código de pagamento único para cada venda
- Validar que pagamento só pode ser processado uma vez
- Validar que veículo está disponível antes de vender

### 3. Repository Layer (Camada de Dados)

**Responsabilidade:** Acesso e persistência de dados.

**Componentes:**
- `VehicleRepository`: Operações de banco para veículos
- `SaleRepository`: Operações de banco para vendas

**Tecnologias:**
- Hibernate ORM
- Panache (Active Record pattern)
- JPA annotations

**Características:**
- Queries tipadas e type-safe
- Métodos customizados para consultas específicas
- Ordenação automática por preço
- Transações gerenciadas automaticamente

### 4. Domain Layer (Camada de Domínio)

**Responsabilidade:** Representar os conceitos do negócio.

**Componentes:**
- `Vehicle`: Entidade principal do domínio (veículo)
- `Sale`: Entidade de venda
- `VehicleStatus`: Enum para status do veículo
- `PaymentStatus`: Enum para status de pagamento

**Características:**
- Entidades com campos públicos (Panache style)
- Lifecycle callbacks (`@PrePersist`, `@PreUpdate`)
- Relacionamentos JPA
- Auditoria automática (createdAt, updatedAt)

## Fluxo de Dados

### Fluxo de Cadastro de Veículo

```
Cliente → API Resource → Service → Repository → Database
  POST      validate      create     persist     INSERT
           VehicleDTO     Vehicle    Vehicle     vehicles
```

### Fluxo de Venda de Veículo

```
Cliente → SaleResource → SaleService → [VehicleService]
  POST    validate       create         markAsSold
          SaleDTO        Sale           Vehicle.status = SOLD
                         ↓
                    SaleRepository → Database
                    persist          INSERT sales
                                    UPDATE vehicles
```

### Fluxo de Processamento de Pagamento (Webhook)

```
Processadora → PaymentWebhookResource → SaleService
de Pagamento   validate                 updatePaymentStatus
               PaymentDTO                Sale.paymentStatus
                                         ↓
                                    SaleRepository → Database
                                    persist          UPDATE sales
```

## Padrões de Design Utilizados

### 1. Repository Pattern
Abstração do acesso a dados, facilitando testes e mudança de implementação.

### 2. Service Layer Pattern
Centralização da lógica de negócio, separada da camada de apresentação.

### 3. DTO Pattern
Objetos de transferência de dados para desacoplar camadas e controlar exposição.

### 4. Dependency Injection
Injeção de dependências com CDI (Contexts and Dependency Injection).

### 5. Exception Handling Pattern
Tratamento centralizado de exceções com mapeamento para respostas HTTP.

## Decisões de Arquitetura

### Por que Quarkus?

1. **Cloud Native**: Otimizado para containers e Kubernetes
2. **Performance**: Startup rápido e baixo consumo de memória
3. **Produtividade**: Dev mode com live reload
4. **Padrões**: Suporte nativo a MicroProfile e Jakarta EE
5. **GraalVM**: Possibilidade de compilação nativa

### Por que Panache?

1. **Simplicidade**: Reduz boilerplate do Hibernate
2. **Produtividade**: Menos código para escrever
3. **Type-safe**: Queries tipadas em compile-time
4. **Flexibilidade**: Permite métodos personalizados

### Por que PostgreSQL?

1. **Robustez**: Banco de dados confiável e maduro
2. **Features**: Suporte completo a ACID
3. **Open Source**: Sem custos de licença
4. **Kubernetes**: Fácil deployment em containers

## Configuração Kubernetes

### Namespace Isolation
Recursos isolados em namespace dedicado (`vehicle-resale`).

### ConfigMaps
Configurações externalizadas:
- URL do banco de dados
- Configurações de logging
- Configurações do Hibernate

### Secrets
Dados sensíveis:
- Senha do banco de dados
- (Futuro) Tokens de API
- (Futuro) Certificados

### Deployment Strategy
- **Replicas**: 2 instâncias da aplicação para alta disponibilidade
- **Rolling Update**: Deployment sem downtime
- **Resource Limits**: CPU e memória limitados

### Health Checks
- **Liveness Probe**: Verifica se aplicação está viva
- **Readiness Probe**: Verifica se aplicação está pronta para receber tráfego

### Persistent Storage
- **PVC**: Volume persistente para PostgreSQL
- **Size**: 5Gi para dados
- **Access Mode**: ReadWriteOnce

### Service Types
- **LoadBalancer**: Para API (acesso externo)
- **ClusterIP**: Para PostgreSQL (apenas interno)

## Segurança

### Aplicação
- Roda como usuário não-root (UID 185)
- Validação de entrada em todas as requisições
- Tratamento de erros sem expor detalhes internos

### Banco de Dados
- Credenciais em Secrets
- Acesso apenas dentro do cluster
- Senha não hardcoded

### Rede
- PostgreSQL não exposto externamente
- Comunicação intra-cluster

## Observabilidade

### Logging
- Logs estruturados
- Níveis configuráveis via ConfigMap
- Logs de SQL para debug

### Health Checks
- `/health` - Status geral
- `/health/live` - Liveness
- `/health/ready` - Readiness

### Metrics
- `/metrics` - Métricas Prometheus
- Coleta automática de métricas da JVM
- Métricas HTTP

### API Documentation
- `/swagger-ui` - Interface interativa
- `/openapi` - Especificação OpenAPI JSON

## Escalabilidade

### Horizontal Scaling
- Múltiplas réplicas da aplicação
- LoadBalancer distribui tráfego
- Stateless design permite escalar facilmente

### Vertical Scaling
- Ajustar resources (CPU/Memory) no Deployment
- Kubernetes gerencia recursos automaticamente

### Database Scaling
- (Futuro) PostgreSQL HA com replicação
- (Futuro) Connection pooling otimizado
- (Futuro) Read replicas

## Performance

### Otimizações Implementadas
- Queries com índices automáticos (JPA)
- Eager loading de relacionamentos necessários
- Connection pooling configurado
- Transações gerenciadas eficientemente

### Otimizações Futuras
- Cache com Redis
- Paginação nas listagens
- Query optimization com índices customizados
- CDN para assets estáticos

## Resiliência

### Implementado
- Health checks para restart automático
- Múltiplas réplicas
- Tratamento de exceções

### Futuro
- Circuit breaker
- Retry policies
- Timeout configuration
- Graceful shutdown

## Monitoramento

### Kubernetes
```bash
# Ver pods
kubectl get pods -n vehicle-resale

# Ver logs
kubectl logs -f <pod-name> -n vehicle-resale

# Ver eventos
kubectl get events -n vehicle-resale

# Métricas de recursos
kubectl top pods -n vehicle-resale
```

### Application
```bash
# Health check
curl http://<host>/health

# Métricas
curl http://<host>/metrics
```

## Melhorias Futuras

### Curto Prazo
1. Implementar paginação nas listagens
2. Adicionar filtros de busca (marca, modelo, ano)
3. Implementar soft delete
4. Adicionar índices no banco de dados
5. Implementar testes unitários e de integração

### Médio Prazo
1. Autenticação e autorização (JWT)
2. Rate limiting
3. Cache distribuído (Redis)
4. Mensageria (Kafka) para eventos assíncronos
5. API versioning

### Longo Prazo
1. Service mesh (Istio)
2. Distributed tracing (Jaeger)
3. ELK stack para logs centralizados
4. GitOps com ArgoCD
5. Multi-region deployment

## Conclusão

A arquitetura proposta oferece:
- **Modularidade**: Camadas bem definidas e separadas
- **Testabilidade**: Dependências injetadas facilitam testes
- **Manutenibilidade**: Código organizado e documentado
- **Escalabilidade**: Pronto para crescer horizontal e verticalmente
- **Cloud Native**: Otimizado para Kubernetes
- **Observabilidade**: Logs, métricas e health checks
- **Segurança**: Boas práticas implementadas

Esta é uma base sólida para um sistema de produção, com espaço para evolução conforme necessidades do negócio.

