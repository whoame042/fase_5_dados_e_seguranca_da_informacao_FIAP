package com.vehicleresale.domain.repository;

import com.vehicleresale.api.dto.VehicleFilterDTO;
import com.vehicleresale.domain.entity.Vehicle;
import com.vehicleresale.domain.enums.VehicleStatus;
import io.quarkus.hibernate.orm.panache.PanacheQuery;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import io.quarkus.panache.common.Page;
import io.quarkus.panache.common.Sort;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@ApplicationScoped
public class VehicleRepositoryEnhanced implements PanacheRepository<Vehicle> {

    public List<Vehicle> findByStatus(VehicleStatus status) {
        return list("status = ?1 and deletedAt is null", Sort.by("price").ascending(), status);
    }

    public List<Vehicle> findAvailableVehicles() {
        return findByStatus(VehicleStatus.AVAILABLE);
    }

    public List<Vehicle> findSoldVehicles() {
        return findByStatus(VehicleStatus.SOLD);
    }

    public PanacheQuery<Vehicle> findByStatusPaginated(VehicleStatus status) {
        return find("status = ?1 and deletedAt is null", Sort.by("price").ascending(), status);
    }

    public PanacheQuery<Vehicle> findAvailableVehiclesPaginated() {
        return findByStatusPaginated(VehicleStatus.AVAILABLE);
    }

    public PanacheQuery<Vehicle> findSoldVehiclesPaginated() {
        return findByStatusPaginated(VehicleStatus.SOLD);
    }

    public PanacheQuery<Vehicle> findWithFilters(VehicleFilterDTO filter, VehicleStatus status) {
        StringBuilder query = new StringBuilder("deletedAt is null");
        Map<String, Object> params = new HashMap<>();

        if (status != null) {
            query.append(" and status = :status");
            params.put("status", status);
        }

        if (filter.brand != null && !filter.brand.isBlank()) {
            query.append(" and lower(brand) like :brand");
            params.put("brand", "%" + filter.brand.toLowerCase() + "%");
        }

        if (filter.model != null && !filter.model.isBlank()) {
            query.append(" and lower(model) like :model");
            params.put("model", "%" + filter.model.toLowerCase() + "%");
        }

        if (filter.year != null) {
            query.append(" and year = :year");
            params.put("year", filter.year);
        }

        if (filter.yearFrom != null) {
            query.append(" and year >= :yearFrom");
            params.put("yearFrom", filter.yearFrom);
        }

        if (filter.yearTo != null) {
            query.append(" and year <= :yearTo");
            params.put("yearTo", filter.yearTo);
        }

        if (filter.color != null && !filter.color.isBlank()) {
            query.append(" and lower(color) like :color");
            params.put("color", "%" + filter.color.toLowerCase() + "%");
        }

        if (filter.priceFrom != null) {
            query.append(" and price >= :priceFrom");
            params.put("priceFrom", filter.priceFrom);
        }

        if (filter.priceTo != null) {
            query.append(" and price <= :priceTo");
            params.put("priceTo", filter.priceTo);
        }

        return find(query.toString(), Sort.by("price").ascending(), params);
    }

    public List<Vehicle> findAllNotDeleted() {
        return list("deletedAt is null", Sort.by("price").ascending());
    }

    public long countByStatus(VehicleStatus status) {
        return count("status = ?1 and deletedAt is null", status);
    }
}

