package com.vehicleresale.domain.entity;

import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.time.LocalDateTime;

/**
 * Entidade Customer - Representa um comprador cadastrado no sistema.
 * 
 * O cadastro de clientes deve ser feito ANTES da compra do veiculo.
 * O userId referencia o usuario no Keycloak (servico de autenticacao separado).
 */
@Entity
@Table(name = "customers", indexes = {
    @Index(name = "idx_customer_cpf", columnList = "cpf", unique = true),
    @Index(name = "idx_customer_email", columnList = "email", unique = true),
    @Index(name = "idx_customer_user_id", columnList = "user_id", unique = true),
    @Index(name = "idx_customer_active", columnList = "active")
})
public class Customer extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;

    /**
     * ID do usuario no Keycloak (UUID)
     * Vincula o cadastro do cliente ao servico de autenticacao separado
     */
    @Column(name = "user_id", unique = true, length = 100)
    public String userId;

    @Column(nullable = false, length = 200)
    public String name;

    @Column(nullable = false, unique = true, length = 200)
    public String email;

    @Column(nullable = false, unique = true, length = 11)
    public String cpf;

    @Column(length = 20)
    public String phone;

    @Column(length = 500)
    public String address;

    @Column(length = 100)
    public String city;

    @Column(length = 2)
    public String state;

    @Column(name = "zip_code", length = 10)
    public String zipCode;

    @Column(nullable = false)
    public Boolean active = true;

    @Column(name = "created_at", nullable = false, updatable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at")
    public LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.active == null) {
            this.active = true;
        }
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}

