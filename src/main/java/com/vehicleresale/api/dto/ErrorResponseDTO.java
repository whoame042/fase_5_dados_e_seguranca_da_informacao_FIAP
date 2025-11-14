package com.vehicleresale.api.dto;

import java.time.LocalDateTime;

public class ErrorResponseDTO {

    public String message;
    public LocalDateTime timestamp;
    public Integer status;

    public ErrorResponseDTO() {
        this.timestamp = LocalDateTime.now();
    }

    public ErrorResponseDTO(String message, Integer status) {
        this.message = message;
        this.status = status;
        this.timestamp = LocalDateTime.now();
    }
}

