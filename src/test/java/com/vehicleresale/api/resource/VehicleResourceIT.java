package com.vehicleresale.api.resource;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.Order;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.*;
import static org.hamcrest.Matchers.greaterThanOrEqualTo;

@QuarkusTest
class VehicleResourceIT {

    @Test
    @Order(1)
    void testCreateVehicle() {
        String vehicleJson = """
            {
                "brand": "Toyota",
                "model": "Corolla",
                "year": 2023,
                "color": "Prata",
                "price": 95000.00
            }
            """;

        given()
            .contentType(ContentType.JSON)
            .body(vehicleJson)
        .when()
            .post("/api/vehicles")
        .then()
            .statusCode(201)
            .body("brand", equalTo("Toyota"))
            .body("model", equalTo("Corolla"))
            .body("status", equalTo("AVAILABLE"));
    }

    @Test
    @Order(2)
    void testCreateVehicle_InvalidData() {
        String vehicleJson = """
            {
                "brand": "Toyota",
                "model": "Corolla",
                "year": 1800,
                "color": "Prata",
                "price": -1000.00
            }
            """;

        given()
            .contentType(ContentType.JSON)
            .body(vehicleJson)
        .when()
            .post("/api/vehicles")
        .then()
            .statusCode(400);
    }

    @Test
    @Order(3)
    void testListAvailableVehicles() {
        given()
        .when()
            .get("/api/vehicles/available")
        .then()
            .statusCode(200)
            .body("content", notNullValue())
            .body("totalElements", greaterThanOrEqualTo(0));
    }

    @Test
    @Order(4)
    void testListAvailableVehiclesWithPagination() {
        given()
            .queryParam("page", 0)
            .queryParam("size", 5)
        .when()
            .get("/api/vehicles/available")
        .then()
            .statusCode(200)
            .body("pageNumber", equalTo(0))
            .body("pageSize", equalTo(5));
    }

    @Test
    @Order(5)
    void testListAvailableVehiclesWithFilters() {
        given()
            .queryParam("brand", "Toyota")
            .queryParam("yearFrom", 2020)
            .queryParam("yearTo", 2024)
        .when()
            .get("/api/vehicles/available")
        .then()
            .statusCode(200)
            .body("content", notNullValue());
    }

    @Test
    @Order(6)
    void testGetVehicleById_NotFound() {
        given()
        .when()
            .get("/api/vehicles/99999")
        .then()
            .statusCode(404);
    }

    @Test
    @Order(7)
    void testUpdateVehicle_NotFound() {
        String updateJson = """
            {
                "brand": "Honda",
                "model": "Civic",
                "year": 2022,
                "color": "Preto",
                "price": 110000.00
            }
            """;

        given()
            .contentType(ContentType.JSON)
            .body(updateJson)
        .when()
            .put("/api/vehicles/99999")
        .then()
            .statusCode(404);
    }

    @Test
    @Order(8)
    void testDeleteVehicle_NotFound() {
        given()
        .when()
            .delete("/api/vehicles/99999")
        .then()
            .statusCode(404);
    }
}

