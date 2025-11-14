package com.vehicleresale.api.dto;

import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public class VehicleResponseDTO {

    public Long id;
    public String brand;
    public String model;
    public Integer year;
    public String color;
    public BigDecimal price;
    public VehicleStatus status;
    public LocalDateTime createdAt;
    public LocalDateTime updatedAt;

    public VehicleResponseDTO() {
    }

    public VehicleResponseDTO(Vehicle vehicle) {
        this.id = vehicle.id;
        this.brand = vehicle.brand;
        this.model = vehicle.model;
        this.year = vehicle.year;
        this.color = vehicle.color;
        this.price = vehicle.price;
        this.status = vehicle.status;
        this.createdAt = vehicle.createdAt;
        this.updatedAt = vehicle.updatedAt;
    }
}

