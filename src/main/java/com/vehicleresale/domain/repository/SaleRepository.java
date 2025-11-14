package com.vehicleresale.domain.repository;

import com.vehicleresale.domain.entity.Sale;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.Optional;

@ApplicationScoped
public class SaleRepository implements PanacheRepository<Sale> {

    public Optional<Sale> findByPaymentCode(String paymentCode) {
        return find("paymentCode", paymentCode).firstResultOptional();
    }
}

