package com.vehicleresale.application.presenter;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleResponseDTO;
import com.vehicleresale.domain.entity.Vehicle;
import java.util.List;

/**
 * Presenter interface para converter Entity em formato de apresentação.
 * 
 * Responsabilidades:
 * - Converter Entity → DTO
 * - Isolar o domínio dos formatos externos
 * - Não expor regras de negócio internas
 * - Não expor validações do domínio
 * - Apenas atributos necessários para apresentação
 */
public interface VehiclePresenter {
    
    /**
     * Converte uma entidade Vehicle para DTO de resposta
     */
    VehicleResponseDTO toResponse(Vehicle vehicle);
    
    /**
     * Converte uma lista de entidades para lista de DTOs
     */
    List<VehicleResponseDTO> toResponseList(List<Vehicle> vehicles);
    
    /**
     * Converte uma página de entidades para página de DTOs
     */
    PageDTO<VehicleResponseDTO> toPageResponse(PageDTO<Vehicle> vehiclePage);
}

