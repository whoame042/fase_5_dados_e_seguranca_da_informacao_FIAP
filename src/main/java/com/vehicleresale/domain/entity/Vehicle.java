package com.vehicleresale.domain.entity;

import com.vehicleresale.domain.enums.VehicleStatus;
import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "vehicles", indexes = {
    @Index(name = "idx_vehicle_brand", columnList = "brand"),
    @Index(name = "idx_vehicle_model", columnList = "model"),
    @Index(name = "idx_vehicle_year", columnList = "year"),
    @Index(name = "idx_vehicle_price", columnList = "price"),
    @Index(name = "idx_vehicle_status", columnList = "status"),
    @Index(name = "idx_vehicle_deleted_at", columnList = "deleted_at")
})
public class Vehicle extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;

    @Column(nullable = false, length = 100)
    public String brand;

    @Column(nullable = false, length = 100)
    public String model;

    @Column(nullable = false)
    public Integer year;

    @Column(nullable = false, length = 50)
    public String color;

    @Column(nullable = false, precision = 10, scale = 2)
    public BigDecimal price;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    public VehicleStatus status;

    @Column(name = "deleted_at")
    public LocalDateTime deletedAt;

    @Column(name = "created_at", nullable = false, updatable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at")
    public LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.status == null) {
            this.status = VehicleStatus.AVAILABLE;
        }
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }

    public boolean isDeleted() {
        return this.deletedAt != null;
    }

    public void softDelete() {
        this.deletedAt = LocalDateTime.now();
    }
}

