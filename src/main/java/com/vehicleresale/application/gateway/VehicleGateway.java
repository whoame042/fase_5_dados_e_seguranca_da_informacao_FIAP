package com.vehicleresale.application.gateway;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleFilterDTO;
import com.vehicleresale.domain.entity.Vehicle;
import java.util.List;
import java.util.Optional;

/**
 * Gateway interface para isolar o domínio dos detalhes de persistência.
 * 
 * Responsabilidades:
 * - Abstrair o acesso a dados
 * - Converter Entity ↔ DAO (se necessário)
 * - Não expor detalhes do ORM para o Use Case
 * - Garantir que Entity não vaze para camadas externas
 */
public interface VehicleGateway {
    
    /**
     * Persiste um veículo e retorna a entidade persistida
     */
    Vehicle save(Vehicle vehicle);
    
    /**
     * Busca um veículo por ID
     */
    Optional<Vehicle> findById(Long id);
    
    /**
     * Lista veículos disponíveis com paginação e filtros
     */
    PageDTO<Vehicle> findAvailableVehicles(int page, int size, VehicleFilterDTO filter);
    
    /**
     * Lista veículos vendidos com paginação e filtros
     */
    PageDTO<Vehicle> findSoldVehicles(int page, int size, VehicleFilterDTO filter);
    
    /**
     * Exclui logicamente um veículo (soft delete)
     */
    void delete(Vehicle vehicle);
}

