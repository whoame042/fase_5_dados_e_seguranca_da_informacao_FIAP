package com.vehicleresale.api.resource;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Order;

import java.time.LocalDate;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.*;

@QuarkusTest
class SaleResourceIT {

    @Test
    @Order(1)
    void testCreateSale_VehicleNotFound() {
        String saleJson = String.format("""
            {
                "vehicleId": 99999,
                "buyerCpf": "12345678901",
                "saleDate": "%s"
            }
            """, LocalDate.now());

        given()
            .contentType(ContentType.JSON)
            .body(saleJson)
        .when()
            .post("/api/sales")
        .then()
            .statusCode(404);
    }

    @Test
    @Order(2)
    void testCreateSale_InvalidCPF() {
        String saleJson = String.format("""
            {
                "vehicleId": 1,
                "buyerCpf": "123",
                "saleDate": "%s"
            }
            """, LocalDate.now());

        given()
            .contentType(ContentType.JSON)
            .body(saleJson)
        .when()
            .post("/api/sales")
        .then()
            .statusCode(400);
    }

    @Test
    @Order(3)
    void testGetSale_NotFound() {
        given()
        .when()
            .get("/api/sales/99999")
        .then()
            .statusCode(404);
    }
}

