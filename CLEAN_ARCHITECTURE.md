# Clean Architecture - Análise e Melhorias

Este documento analisa a implementação atual da Clean Architecture no projeto e propõe melhorias para um alinhamento mais rigoroso com os conceitos fundamentais.

## Status Atual da Implementação

### ✅ Pontos Positivos

1. **Entities (Domain)** ✅
   - Bem definidas em `domain/entity/`
   - Regras de negócio encapsuladas
   - Validações no domínio

2. **Use Cases** ✅
   - Implementados como `Services` em `domain/service/`
   - Lógica de negócio centralizada
   - Independentes de frameworks

3. **Repositories** ✅
   - Interfaces bem definidas em `domain/repository/`
   - Abstração do acesso a dados

4. **DTOs** ✅
   - Request/Response separados do domínio
   - Validações de entrada

### 🟡 Pontos de Melhoria

1. **Controllers** 🟡
   - Atualmente os `Resources` (controllers REST) injetam diretamente os `Services`
   - Deveria haver uma camada de Controllers Clean Architecture

2. **Gateway** 🟡
   - Repositories atualmente não isolam completamente o domínio
   - Falta conversão explícita Entity → DTO/DAO

3. **Presenters** ❌
   - Não implementados
   - Conversão Entity → DTO feita nos Controllers REST

## Arquitetura Atual

```
┌─────────────────────────────────────────────────────────┐
│  REST Controllers (api/resource)                        │
│  - VehicleResource                                      │
│  - SaleResource                                         │
│  - PaymentWebhookResource                              │
└───────────────┬─────────────────────────────────────────┘
                │ @Inject
                ↓
┌─────────────────────────────────────────────────────────┐
│  Services (domain/service) = Use Cases                  │
│  - VehicleService                                       │
│  - SaleService                                          │
└───────────────┬─────────────────────────────────────────┘
                │ @Inject
                ↓
┌─────────────────────────────────────────────────────────┐
│  Repositories (domain/repository)                       │
│  - VehicleRepository                                    │
│  - SaleRepository                                       │
└───────────────┬─────────────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────────────┐
│  Entities (domain/entity)                               │
│  - Vehicle                                              │
│  - Sale                                                 │
└─────────────────────────────────────────────────────────┘
```

**Problema:** REST Controller conhece diretamente o Use Case. Deveria haver uma camada intermediária.

## Arquitetura Proposta (Clean Architecture Ideal)

```
┌─────────────────────────────────────────────────────────┐
│  Adapter: REST Controllers (api/resource)               │
│  - VehicleResource                                      │
│  - SaleResource                                         │
│  - PaymentWebhookResource                              │
└───────────────┬─────────────────────────────────────────┘
                │ instancia e injeta
                ↓
┌─────────────────────────────────────────────────────────┐
│  Interface Adapter: Controllers                         │
│  - VehicleController                                    │
│  - SaleController                                       │
│  - PaymentController                                    │
└─────┬───────────────────────────┬───────────────────────┘
      │ instancia                 │ instancia
      ↓                           ↓
┌─────────────────┐         ┌─────────────────┐
│  Gateway        │         │  Presenter      │
│  (Repository    │         │  (Entity→DTO)   │
│   Adapter)      │         │                 │
└────────┬────────┘         └────────┬────────┘
         │                           │
         │ injeta                    │ usa
         ↓                           │
┌─────────────────────────────────────────────────────────┐
│  Use Cases (domain/service)                             │
│  - VehicleService                                       │
│  - SaleService                                          │
└───────────────┬─────────────────────────────────────────┘
                │
                ↓
┌─────────────────────────────────────────────────────────┐
│  Entities (domain/entity)                               │
│  - Vehicle                                              │
│  - Sale                                                 │
└─────────────────────────────────────────────────────────┘
```

## Melhorias Propostas

### 1. Criar Controllers Clean Architecture

**Localização:** `src/main/java/com/vehicleresale/application/controller/`

```java
public class VehicleController {
    private final VehicleService useCase;
    private final VehicleGateway gateway;
    private final VehiclePresenter presenter;
    
    public VehicleController(VehicleGateway gateway, VehiclePresenter presenter) {
        this.gateway = gateway;
        this.presenter = presenter;
        this.useCase = new VehicleService(gateway);
    }
    
    public VehicleResponseDTO createVehicle(VehicleRequestDTO request) {
        Vehicle vehicle = useCase.create(request);
        return presenter.toResponse(vehicle); // Presenter converte Entity → DTO
    }
}
```

**Responsabilidade:**
- Instanciar Use Cases
- Instanciar Gateways e Presenters
- Fazer injeção de dependências
- Não conhecer detalhes de HTTP/REST

### 2. Implementar Gateway Pattern

**Localização:** `src/main/java/com/vehicleresale/application/gateway/`

```java
public interface VehicleGateway {
    Vehicle save(Vehicle vehicle);
    Optional<Vehicle> findById(Long id);
    List<Vehicle> findAvailable();
}

public class VehicleGatewayImpl implements VehicleGateway {
    @Inject
    VehicleRepository repository;
    
    @Override
    public Vehicle save(Vehicle vehicle) {
        // Converte Entity → DAO (se necessário)
        // Persiste
        // Converte DAO → Entity
        Vehicle persisted = repository.persist(vehicle);
        return persisted; // Retorna Entity pura, sem vazamento de detalhes do ORM
    }
}
```

**Responsabilidade:**
- Isolar o domínio de detalhes de persistência
- Converter Entity ↔ DAO (se necessário)
- Não expor detalhes do Hibernate/JPA para o Use Case

### 3. Implementar Presenters

**Localização:** `src/main/java/com/vehicleresale/application/presenter/`

```java
public interface VehiclePresenter {
    VehicleResponseDTO toResponse(Vehicle vehicle);
    List<VehicleResponseDTO> toResponseList(List<Vehicle> vehicles);
    PageDTO<VehicleResponseDTO> toPageResponse(List<Vehicle> vehicles, long total, int page, int size);
}

public class VehiclePresenterImpl implements VehiclePresenter {
    @Override
    public VehicleResponseDTO toResponse(Vehicle vehicle) {
        // Converte Entity → DTO
        // SEM expor regras de negócio internas
        // SEM expor métodos de validação do domínio
        VehicleResponseDTO dto = new VehicleResponseDTO();
        dto.id = vehicle.getId();
        dto.brand = vehicle.getBrand();
        dto.model = vehicle.getModel();
        dto.year = vehicle.getYear();
        dto.color = vehicle.getColor();
        dto.price = vehicle.getPrice();
        dto.status = vehicle.getStatus().name();
        return dto;
    }
}
```

**Responsabilidade:**
- Converter Entity → DTO para apresentação
- Isolar o domínio dos formatos externos
- Não expor validações internas ou regras de negócio

### 4. Separar Controllers REST dos Controllers Clean

**Estrutura proposta:**

```
src/main/java/com/vehicleresale/
├── api/                          # Camada de Adaptadores REST
│   ├── resource/                 # REST Controllers (HTTP)
│   │   ├── VehicleResource.java
│   │   ├── SaleResource.java
│   │   └── PaymentWebhookResource.java
│   └── dto/                      # Request/Response DTOs
│       ├── VehicleRequestDTO.java
│       └── VehicleResponseDTO.java
│
├── application/                  # Camada de Aplicação (Clean)
│   ├── controller/               # Controllers Clean Architecture
│   │   ├── VehicleController.java
│   │   ├── SaleController.java
│   │   └── PaymentController.java
│   ├── gateway/                  # Gateway Adapters
│   │   ├── VehicleGateway.java
│   │   ├── VehicleGatewayImpl.java
│   │   ├── SaleGateway.java
│   │   └── SaleGatewayImpl.java
│   └── presenter/                # Presenters
│       ├── VehiclePresenter.java
│       ├── VehiclePresenterImpl.java
│       ├── SalePresenter.java
│       └── SalePresenterImpl.java
│
└── domain/                       # Camada de Domínio (Core)
    ├── entity/                   # Entidades
    │   ├── Vehicle.java
    │   └── Sale.java
    ├── service/                  # Use Cases
    │   ├── VehicleService.java
    │   └── SaleService.java
    ├── repository/               # Interfaces de Repositório
    │   ├── VehicleRepository.java
    │   └── SaleRepository.java
    └── enums/
        ├── VehicleStatus.java
        └── PaymentStatus.java
```

## Exemplo de Implementação Completa

### REST Controller (Adapter)

```java
@Path("/api/vehicles")
public class VehicleResource {
    
    @Inject
    VehicleGateway gateway;
    
    @Inject
    VehiclePresenter presenter;
    
    @POST
    public Response createVehicle(@Valid VehicleRequestDTO request) {
        // 1. Instancia Controller Clean
        VehicleController controller = new VehicleController(gateway, presenter);
        
        // 2. Delega para Controller Clean
        VehicleResponseDTO response = controller.createVehicle(request);
        
        // 3. Retorna resposta HTTP
        return Response.status(201).entity(response).build();
    }
}
```

### Controller Clean Architecture

```java
public class VehicleController {
    private final VehicleService useCase;
    private final VehiclePresenter presenter;
    
    public VehicleController(VehicleGateway gateway, VehiclePresenter presenter) {
        this.presenter = presenter;
        this.useCase = new VehicleService(gateway);
    }
    
    public VehicleResponseDTO createVehicle(VehicleRequestDTO request) {
        // 1. Converte DTO → Entity
        Vehicle vehicle = new Vehicle();
        vehicle.setBrand(request.brand);
        vehicle.setModel(request.model);
        vehicle.setYear(request.year);
        vehicle.setColor(request.color);
        vehicle.setPrice(request.price);
        
        // 2. Chama Use Case
        Vehicle created = useCase.create(vehicle);
        
        // 3. Usa Presenter para converter Entity → DTO
        return presenter.toResponse(created);
    }
}
```

### Gateway

```java
public class VehicleGatewayImpl implements VehicleGateway {
    @Inject
    VehicleRepository repository;
    
    @Override
    public Vehicle save(Vehicle vehicle) {
        // Persiste (Panache já retorna a entidade)
        Vehicle persisted = repository.persist(vehicle);
        
        // Garante que não há vazamento de detalhes do ORM
        // (Panache já gerencia isso, mas em outros ORMs seria necessário converter)
        return persisted;
    }
    
    @Override
    public Optional<Vehicle> findById(Long id) {
        return repository.findByIdOptional(id);
    }
}
```

### Presenter

```java
public class VehiclePresenterImpl implements VehiclePresenter {
    @Override
    public VehicleResponseDTO toResponse(Vehicle vehicle) {
        VehicleResponseDTO dto = new VehicleResponseDTO();
        dto.id = vehicle.getId();
        dto.brand = vehicle.getBrand();
        dto.model = vehicle.getModel();
        dto.year = vehicle.getYear();
        dto.color = vehicle.getColor();
        dto.price = vehicle.getPrice();
        dto.status = vehicle.getStatus().name();
        dto.createdAt = vehicle.getCreatedAt();
        dto.updatedAt = vehicle.getUpdatedAt();
        return dto;
    }
    
    @Override
    public List<VehicleResponseDTO> toResponseList(List<Vehicle> vehicles) {
        return vehicles.stream()
            .map(this::toResponse)
            .collect(Collectors.toList());
    }
}
```

## Benefícios da Arquitetura Proposta

### 1. Separação de Responsabilidades
- **REST Controller**: Lida apenas com HTTP (request/response)
- **Controller Clean**: Orquestra Use Cases
- **Gateway**: Isola persistência
- **Presenter**: Isola apresentação
- **Use Case**: Regras de negócio puras

### 2. Testabilidade
```java
@Test
void shouldCreateVehicle() {
    // Mock Gateway e Presenter
    VehicleGateway gateway = mock(VehicleGateway.class);
    VehiclePresenter presenter = mock(VehiclePresenter.class);
    
    // Testa Controller isoladamente
    VehicleController controller = new VehicleController(gateway, presenter);
    
    // Testa sem HTTP, sem banco, sem frameworks
    VehicleRequestDTO request = new VehicleRequestDTO();
    request.brand = "Toyota";
    
    controller.createVehicle(request);
    
    verify(gateway).save(any(Vehicle.class));
    verify(presenter).toResponse(any(Vehicle.class));
}
```

### 3. Independência de Frameworks
- Use Cases não conhecem Quarkus, JAX-RS, Hibernate
- Domínio é puro Java
- Fácil migração para outros frameworks

### 4. Isolamento do Domínio
- Entity nunca sai da camada de domínio
- Gateway converte Entity → DAO
- Presenter converte Entity → DTO
- Regras de negócio nunca vazam

## Implementação Atual vs. Ideal

| Aspecto | Atual | Ideal |
|---------|-------|-------|
| **Controllers** | REST injetam Services direto | REST → Controller Clean → Use Case |
| **Gateway** | Repository direto | Gateway isola persistência |
| **Presenter** | DTO construtor recebe Entity | Presenter converte explicitamente |
| **Injeção** | CDI injeta Services | Controller instancia Use Case |
| **Isolamento** | Entity vaza para REST | Entity fica no domínio |

## Próximos Passos para Melhorar

### Curto Prazo (Sem Breaking Changes)
1. ✅ Documentar conceitos de Clean Architecture (este arquivo)
2. ✅ Adicionar comentários no código atual explicando camadas
3. ✅ Criar diagramas de arquitetura

### Médio Prazo (Refactoring Gradual)
1. Criar interfaces `Gateway` e `Presenter`
2. Implementar `VehicleGatewayImpl` e `VehiclePresenterImpl`
3. Criar `Controllers Clean` na camada `application/`
4. Refatorar `Resources` para usar `Controllers Clean`

### Longo Prazo (Arquitetura Completa)
1. Separar completamente camadas
2. Remover dependências circulares
3. Testes unitários independentes de frameworks
4. Módulos Maven separados por camada

## Conclusão

A implementação atual **atende aos conceitos fundamentais** de Clean Architecture:
- ✅ Entities bem definidas
- ✅ Use Cases (Services) implementados
- ✅ Repositories como interfaces

Para um alinhamento **mais rigoroso**, as melhorias propostas incluem:
- 🎯 Controllers Clean Architecture
- 🎯 Gateway Pattern para isolamento total
- 🎯 Presenters para conversão Entity → DTO
- 🎯 Separação clara entre adapters e domínio

O código atual funciona corretamente e segue boas práticas. As melhorias propostas visam um alinhamento teórico mais próximo da Clean Architecture canônica de Robert C. Martin.

---

**Referências:**
- Clean Architecture (Robert C. Martin)
- The Clean Code Blog (Uncle Bob)
- Hexagonal Architecture (Alistair Cockburn)

**Última atualização:** 25/11/2024

