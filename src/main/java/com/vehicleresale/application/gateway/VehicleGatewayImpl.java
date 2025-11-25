package com.vehicleresale.application.gateway;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleFilterDTO;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import com.vehicleresale.domain.repository.VehicleRepositoryEnhanced;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import java.util.List;
import java.util.Optional;

/**
 * Implementação do Gateway que isola a persistência.
 * 
 * Responsabilidades:
 * - Usar o Repository para acessar dados
 * - Converter Entity ↔ DAO (neste caso, Panache já retorna Entity pura)
 * - Não expor detalhes do Hibernate/JPA para o Use Case
 * - Garantir que o domínio permaneça isolado
 */
@ApplicationScoped
public class VehicleGatewayImpl implements VehicleGateway {
    
    @Inject
    VehicleRepositoryEnhanced repository;
    
    @Override
    @Transactional
    public Vehicle save(Vehicle vehicle) {
        // Panache já gerencia a entidade e retorna Entity pura
        // Em outros ORMs, seria necessário converter DAO → Entity
        repository.persist(vehicle);
        return vehicle;
    }
    
    @Override
    public Optional<Vehicle> findById(Long id) {
        return repository.findByIdOptional(id)
                .filter(v -> !v.isDeleted()); // Filtra soft deleted
    }
    
    @Override
    public PageDTO<Vehicle> findAvailableVehicles(int page, int size, VehicleFilterDTO filter) {
        PanacheQuery<Vehicle> query;
        
        if (filter != null && hasFilters(filter)) {
            query = repository.findWithFilters(filter, VehicleStatus.AVAILABLE);
        } else {
            query = repository.findAvailableVehiclesPaginated();
        }
        
        query.page(Page.of(page, size));
        
        List<Vehicle> content = query.list();
        long totalElements = query.count();
        
        // Retorna Entity pura, sem DTO
        return new PageDTO<>(content, page, size, totalElements);
    }
    
    @Override
    public PageDTO<Vehicle> findSoldVehicles(int page, int size, VehicleFilterDTO filter) {
        PanacheQuery<Vehicle> query;
        
        if (filter != null && hasFilters(filter)) {
            query = repository.findWithFilters(filter, VehicleStatus.SOLD);
        } else {
            query = repository.findSoldVehiclesPaginated();
        }
        
        query.page(Page.of(page, size));
        
        List<Vehicle> content = query.list();
        long totalElements = query.count();
        
        // Retorna Entity pura, sem DTO
        return new PageDTO<>(content, page, size, totalElements);
    }
    
    @Override
    @Transactional
    public void delete(Vehicle vehicle) {
        vehicle.softDelete();
        repository.persist(vehicle);
    }
    
    private boolean hasFilters(VehicleFilterDTO filter) {
        return filter.brand != null || filter.model != null || filter.year != null ||
               filter.yearFrom != null || filter.yearTo != null || filter.color != null ||
               filter.priceFrom != null || filter.priceTo != null;
    }
}

