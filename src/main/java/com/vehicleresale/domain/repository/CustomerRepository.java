package com.vehicleresale.domain.repository;

import com.vehicleresale.domain.entity.Customer;
import io.quarkus.hibernate.orm.panache.PanacheRepository;
import jakarta.enterprise.context.ApplicationScoped;

import java.util.List;
import java.util.Optional;

@ApplicationScoped
public class CustomerRepository implements PanacheRepository<Customer> {

    public Optional<Customer> findByCpf(String cpf) {
        return find("cpf = ?1 and active = true", cpf).firstResultOptional();
    }

    public Optional<Customer> findByEmail(String email) {
        return find("email = ?1 and active = true", email).firstResultOptional();
    }

    public Optional<Customer> findByUserId(String userId) {
        return find("userId = ?1 and active = true", userId).firstResultOptional();
    }

    public List<Customer> findAllActive() {
        return list("active = true order by name");
    }

    public boolean existsByCpf(String cpf) {
        return count("cpf = ?1", cpf) > 0;
    }

    public boolean existsByEmail(String email) {
        return count("email = ?1", email) > 0;
    }

    public boolean existsByCpfExcludingId(String cpf, Long id) {
        return count("cpf = ?1 and id != ?2", cpf, id) > 0;
    }

    public boolean existsByEmailExcludingId(String email, Long id) {
        return count("email = ?1 and id != ?2", email, id) > 0;
    }
}

