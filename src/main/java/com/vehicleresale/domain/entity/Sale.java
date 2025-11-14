package com.vehicleresale.domain.entity;

import com.vehicleresale.domain.enums.PaymentStatus;
import io.quarkus.hibernate.orm.panache.PanacheEntityBase;
import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "sales", indexes = {
    @Index(name = "idx_sale_payment_code", columnList = "payment_code"),
    @Index(name = "idx_sale_payment_status", columnList = "payment_status"),
    @Index(name = "idx_sale_date", columnList = "sale_date"),
    @Index(name = "idx_sale_buyer_cpf", columnList = "buyer_cpf")
})
public class Sale extends PanacheEntityBase {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    public Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "vehicle_id", nullable = false)
    public Vehicle vehicle;

    @Column(name = "buyer_name", nullable = false, length = 200)
    public String buyerName;

    @Column(name = "buyer_email", nullable = false, length = 200)
    public String buyerEmail;

    @Column(name = "buyer_cpf", nullable = false, length = 11)
    public String buyerCpf;

    @Column(name = "sale_date", nullable = false)
    public LocalDate saleDate;

    @Column(name = "sale_price", nullable = false, precision = 10, scale = 2)
    public BigDecimal salePrice;

    @Column(name = "payment_code", unique = true, length = 100)
    public String paymentCode;

    @Enumerated(EnumType.STRING)
    @Column(name = "payment_status", nullable = false, length = 20)
    public PaymentStatus paymentStatus;

    @Column(name = "created_at", nullable = false, updatable = false)
    public LocalDateTime createdAt;

    @Column(name = "updated_at")
    public LocalDateTime updatedAt;

    @PrePersist
    public void prePersist() {
        this.createdAt = LocalDateTime.now();
        this.updatedAt = LocalDateTime.now();
        if (this.paymentStatus == null) {
            this.paymentStatus = PaymentStatus.PENDING;
        }
    }

    @PreUpdate
    public void preUpdate() {
        this.updatedAt = LocalDateTime.now();
    }
}

