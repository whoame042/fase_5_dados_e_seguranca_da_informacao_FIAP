package com.vehicleresale.application.controller;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleFilterDTO;
import com.vehicleresale.api.dto.VehicleRequestDTO;
import com.vehicleresale.api.dto.VehicleResponseDTO;
import com.vehicleresale.application.gateway.VehicleGateway;
import com.vehicleresale.application.presenter.VehiclePresenter;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;

/**
 * Controller Clean Architecture para Vehicle.
 * 
 * Responsabilidades:
 * - Orquestrar Use Cases
 * - Injetar Gateway e Presenter
 * - Converter DTO → Entity (input)
 * - Usar Presenter para converter Entity → DTO (output)
 * - NÃO conhecer detalhes de HTTP/REST
 * - NÃO conhecer detalhes de persistência (usa Gateway)
 */
@ApplicationScoped
public class VehicleController {
    
    @Inject
    VehicleGateway gateway;
    
    @Inject
    VehiclePresenter presenter;
    
    /**
     * Cria um novo veículo
     */
    @Transactional
    public VehicleResponseDTO createVehicle(VehicleRequestDTO request) {
        // 1. Converte DTO → Entity
        Vehicle vehicle = new Vehicle();
        vehicle.brand = request.brand;
        vehicle.model = request.model;
        vehicle.year = request.year;
        vehicle.color = request.color;
        vehicle.price = request.price;
        vehicle.status = VehicleStatus.AVAILABLE;
        
        // 2. Executa Use Case (via Gateway)
        Vehicle saved = gateway.save(vehicle);
        
        // 3. Usa Presenter para converter Entity → DTO
        return presenter.toResponse(saved);
    }
    
    /**
     * Atualiza um veículo existente
     */
    @Transactional
    public VehicleResponseDTO updateVehicle(Long id, VehicleRequestDTO request) {
        // 1. Busca entidade
        Vehicle vehicle = gateway.findById(id)
                .orElseThrow(() -> new NotFoundException("Veículo não encontrado com ID: " + id));
        
        // 2. Valida regra de negócio
        if (vehicle.status == VehicleStatus.SOLD) {
            throw new IllegalStateException("Não é possível editar um veículo já vendido");
        }
        
        // 3. Atualiza atributos
        vehicle.brand = request.brand;
        vehicle.model = request.model;
        vehicle.year = request.year;
        vehicle.color = request.color;
        vehicle.price = request.price;
        
        // 4. Persiste via Gateway
        Vehicle updated = gateway.save(vehicle);
        
        // 5. Usa Presenter para retornar DTO
        return presenter.toResponse(updated);
    }
    
    /**
     * Busca veículo por ID
     */
    public VehicleResponseDTO getVehicleById(Long id) {
        Vehicle vehicle = gateway.findById(id)
                .orElseThrow(() -> new NotFoundException("Veículo não encontrado com ID: " + id));
        
        return presenter.toResponse(vehicle);
    }
    
    /**
     * Lista veículos disponíveis com paginação e filtros
     */
    public PageDTO<VehicleResponseDTO> listAvailableVehicles(int page, int size, VehicleFilterDTO filter) {
        // 1. Busca via Gateway (retorna Page<Entity>)
        PageDTO<Vehicle> vehiclePage = gateway.findAvailableVehicles(page, size, filter);
        
        // 2. Usa Presenter para converter Page<Entity> → Page<DTO>
        return presenter.toPageResponse(vehiclePage);
    }
    
    /**
     * Lista veículos vendidos com paginação e filtros
     */
    public PageDTO<VehicleResponseDTO> listSoldVehicles(int page, int size, VehicleFilterDTO filter) {
        // 1. Busca via Gateway
        PageDTO<Vehicle> vehiclePage = gateway.findSoldVehicles(page, size, filter);
        
        // 2. Usa Presenter
        return presenter.toPageResponse(vehiclePage);
    }
    
    /**
     * Exclui logicamente um veículo (soft delete)
     */
    @Transactional
    public void deleteVehicle(Long id) {
        // 1. Busca entidade
        Vehicle vehicle = gateway.findById(id)
                .orElseThrow(() -> new NotFoundException("Veículo não encontrado com ID: " + id));
        
        // 2. Valida regra de negócio
        if (vehicle.status == VehicleStatus.SOLD) {
            throw new IllegalStateException("Não é possível excluir um veículo já vendido");
        }
        
        // 3. Executa delete via Gateway
        gateway.delete(vehicle);
    }
    
    /**
     * Marca veículo como vendido (usado pelo SaleService)
     */
    @Transactional
    public void markAsSold(Long vehicleId) {
        Vehicle vehicle = gateway.findById(vehicleId)
                .orElseThrow(() -> new NotFoundException("Veículo não encontrado com ID: " + vehicleId));
        
        if (vehicle.status == VehicleStatus.SOLD) {
            throw new IllegalStateException("Veículo já foi vendido");
        }
        
        vehicle.status = VehicleStatus.SOLD;
        gateway.save(vehicle);
    }

    /**
     * Marca veículo como disponível novamente (compensação SAGA quando pagamento é rejeitado).
     * Usado pelo SaleService ao processar webhook com paid=false.
     */
    @Transactional
    public void markAsAvailable(Long vehicleId) {
        Vehicle vehicle = gateway.findById(vehicleId)
                .orElseThrow(() -> new NotFoundException("Veículo não encontrado com ID: " + vehicleId));
        
        vehicle.status = VehicleStatus.AVAILABLE;
        gateway.save(vehicle);
    }
}

