package com.vehicleresale.api.resource;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;

@QuarkusTest
class PaymentWebhookResourceIT {

    @Test
    void testProcessPayment_NotFound() {
        String webhookJson = """
            {
                "paymentCode": "invalid-code-12345",
                "paid": true
            }
            """;

        given()
            .contentType(ContentType.JSON)
            .body(webhookJson)
        .when()
            .post("/api/webhook/payment")
        .then()
            .statusCode(404);
    }

    @Test
    void testProcessPayment_InvalidData() {
        String webhookJson = """
            {
                "paymentCode": "",
                "paid": true
            }
            """;

        given()
            .contentType(ContentType.JSON)
            .body(webhookJson)
        .when()
            .post("/api/webhook/payment")
        .then()
            .statusCode(400);
    }
}

