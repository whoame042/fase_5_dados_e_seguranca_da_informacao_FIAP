package com.vehicleresale.domain.service;

import com.vehicleresale.api.dto.PageDTO;
import com.vehicleresale.api.dto.VehicleFilterDTO;
import com.vehicleresale.api.dto.VehicleRequestDTO;
import com.vehicleresale.api.dto.VehicleResponseDTO;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import com.vehicleresale.domain.repository.VehicleRepositoryEnhanced;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.panache.common.Page;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import jakarta.transaction.Transactional;
import jakarta.ws.rs.NotFoundException;
import java.util.List;
import java.util.stream.Collectors;

@ApplicationScoped
public class VehicleService {

    @Inject
    VehicleRepositoryEnhanced vehicleRepository;

    public List<Vehicle> findAllAvailableVehicles() {
        return vehicleRepository.findAvailableVehicles();
    }

    public List<Vehicle> findAllSoldVehicles() {
        return vehicleRepository.findSoldVehicles();
    }

    public PageDTO<VehicleResponseDTO> findAvailableVehiclesPaginated(int page, int size, VehicleFilterDTO filter) {
        PanacheQuery<Vehicle> query;
        
        if (filter != null && hasFilters(filter)) {
            query = vehicleRepository.findWithFilters(filter, VehicleStatus.AVAILABLE);
        } else {
            query = vehicleRepository.findAvailableVehiclesPaginated();
        }
        
        query.page(Page.of(page, size));
        
        List<VehicleResponseDTO> content = query.list().stream()
                .map(VehicleResponseDTO::new)
                .collect(Collectors.toList());
        
        long totalElements = query.count();
        
        return new PageDTO<>(content, page, size, totalElements);
    }

    public PageDTO<VehicleResponseDTO> findSoldVehiclesPaginated(int page, int size, VehicleFilterDTO filter) {
        PanacheQuery<Vehicle> query;
        
        if (filter != null && hasFilters(filter)) {
            query = vehicleRepository.findWithFilters(filter, VehicleStatus.SOLD);
        } else {
            query = vehicleRepository.findSoldVehiclesPaginated();
        }
        
        query.page(Page.of(page, size));
        
        List<VehicleResponseDTO> content = query.list().stream()
                .map(VehicleResponseDTO::new)
                .collect(Collectors.toList());
        
        long totalElements = query.count();
        
        return new PageDTO<>(content, page, size, totalElements);
    }

    private boolean hasFilters(VehicleFilterDTO filter) {
        return filter.brand != null || filter.model != null || filter.year != null ||
               filter.yearFrom != null || filter.yearTo != null || filter.color != null ||
               filter.priceFrom != null || filter.priceTo != null;
    }

    public Vehicle findById(Long id) {
        Vehicle vehicle = vehicleRepository.findByIdOptional(id)
                .orElseThrow(() -> new NotFoundException("Veículo não encontrado com ID: " + id));
        
        if (vehicle.isDeleted()) {
            throw new NotFoundException("Veículo não encontrado com ID: " + id);
        }
        
        return vehicle;
    }

    @Transactional
    public Vehicle create(VehicleRequestDTO dto) {
        Vehicle vehicle = new Vehicle();
        vehicle.brand = dto.brand;
        vehicle.model = dto.model;
        vehicle.year = dto.year;
        vehicle.color = dto.color;
        vehicle.price = dto.price;
        vehicle.status = VehicleStatus.AVAILABLE;
        
        vehicleRepository.persist(vehicle);
        return vehicle;
    }

    @Transactional
    public Vehicle update(Long id, VehicleRequestDTO dto) {
        Vehicle vehicle = findById(id);
        
        if (vehicle.status == VehicleStatus.SOLD) {
            throw new IllegalStateException("Não é possível editar um veículo já vendido");
        }
        
        vehicle.brand = dto.brand;
        vehicle.model = dto.model;
        vehicle.year = dto.year;
        vehicle.color = dto.color;
        vehicle.price = dto.price;
        
        vehicleRepository.persist(vehicle);
        return vehicle;
    }

    @Transactional
    public void markAsSold(Long vehicleId) {
        Vehicle vehicle = findById(vehicleId);
        
        if (vehicle.status == VehicleStatus.SOLD) {
            throw new IllegalStateException("Veículo já foi vendido");
        }
        
        vehicle.status = VehicleStatus.SOLD;
        vehicleRepository.persist(vehicle);
    }

    @Transactional
    public void delete(Long id) {
        Vehicle vehicle = findById(id);
        
        if (vehicle.status == VehicleStatus.SOLD) {
            throw new IllegalStateException("Não é possível excluir um veículo já vendido");
        }
        
        // Soft delete
        vehicle.softDelete();
        vehicleRepository.persist(vehicle);
    }
}

