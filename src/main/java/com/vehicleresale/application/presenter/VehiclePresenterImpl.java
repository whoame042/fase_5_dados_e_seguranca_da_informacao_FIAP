package com.vehicleresale.application.presenter;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleResponseDTO;
import com.vehicleresale.domain.entity.Vehicle;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Implementação do Presenter que converte Entity → DTO.
 * 
 * Responsabilidades:
 * - Converter Vehicle (Entity) → VehicleResponseDTO
 * - Expor APENAS atributos necessários para apresentação
 * - NÃO expor métodos de validação do domínio
 * - NÃO expor regras de negócio internas
 * - Manter o domínio isolado
 */
@ApplicationScoped
public class VehiclePresenterImpl implements VehiclePresenter {
    
    @Override
    public VehicleResponseDTO toResponse(Vehicle vehicle) {
        if (vehicle == null) {
            return null;
        }
        
        // Converte Entity → DTO
        // Expõe apenas atributos necessários
        // NÃO expõe métodos como vehicle.validate(), vehicle.softDelete(), etc.
        VehicleResponseDTO dto = new VehicleResponseDTO();
        dto.id = vehicle.id;
        dto.brand = vehicle.brand;
        dto.model = vehicle.model;
        dto.year = vehicle.year;
        dto.color = vehicle.color;
        dto.price = vehicle.price;
        dto.status = vehicle.status;
        dto.createdAt = vehicle.createdAt;
        dto.updatedAt = vehicle.updatedAt;
        
        return dto;
    }
    
    @Override
    public List<VehicleResponseDTO> toResponseList(List<Vehicle> vehicles) {
        if (vehicles == null) {
            return List.of();
        }
        
        return vehicles.stream()
                .map(this::toResponse)
                .collect(Collectors.toList());
    }
    
    @Override
    public PageDTO<VehicleResponseDTO> toPageResponse(PageDTO<Vehicle> vehiclePage) {
        if (vehiclePage == null) {
            return new PageDTO<>(List.of(), 0, 0, 0L);
        }
        
        List<VehicleResponseDTO> content = toResponseList(vehiclePage.content);
        
        return new PageDTO<>(
            content,
            vehiclePage.pageNumber,
            vehiclePage.pageSize,
            vehiclePage.totalElements
        );
    }
}

