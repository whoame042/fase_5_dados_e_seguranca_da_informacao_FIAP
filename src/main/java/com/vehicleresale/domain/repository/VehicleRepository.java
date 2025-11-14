package com.vehicleresale.domain.repository;

import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import io.quarkus.panache.common.Sort;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.List;

@ApplicationScoped
public class VehicleRepository implements PanacheRepository<Vehicle> {

    public List<Vehicle> findByStatus(VehicleStatus status) {
        return list("status", Sort.by("price").ascending(), status);
    }

    public List<Vehicle> findAvailableVehicles() {
        return findByStatus(VehicleStatus.AVAILABLE);
    }

    public List<Vehicle> findSoldVehicles() {
        return findByStatus(VehicleStatus.SOLD);
    }
}

