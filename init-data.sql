-- Script de inicializacao do banco de dados
-- Este script sera executado automaticamente quando o container PostgreSQL for iniciado pela primeira vez

-- Criacao das tabelas (caso nao existam)
CREATE TABLE IF NOT EXISTS vehicles (
    id BIGSERIAL PRIMARY KEY,
    brand VARCHAR(100) NOT NULL,
    model VARCHAR(100) NOT NULL,
    year INTEGER NOT NULL,
    color VARCHAR(50) NOT NULL,
    price NUMERIC(10,2) NOT NULL,
    status VARCHAR(20) NOT NULL CHECK (status IN ('AVAILABLE', 'SOLD')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE TABLE IF NOT EXISTS sales (
    id BIGSERIAL PRIMARY KEY,
    vehicle_id BIGINT NOT NULL,
    buyer_name VARCHAR(200) NOT NULL,
    buyer_email VARCHAR(200) NOT NULL,
    buyer_cpf VARCHAR(14) NOT NULL,
    sale_price NUMERIC(10,2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL CHECK (payment_status IN ('PENDING', 'APPROVED', 'REJECTED')),
    payment_id VARCHAR(100),
    sale_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP,
    CONSTRAINT fk_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicles(id)
);

-- Indices para melhor performance
CREATE INDEX IF NOT EXISTS idx_vehicle_brand ON vehicles (brand);
CREATE INDEX IF NOT EXISTS idx_vehicle_model ON vehicles (model);
CREATE INDEX IF NOT EXISTS idx_vehicle_year ON vehicles (year);
CREATE INDEX IF NOT EXISTS idx_vehicle_price ON vehicles (price);
CREATE INDEX IF NOT EXISTS idx_vehicle_status ON vehicles (status);
CREATE INDEX IF NOT EXISTS idx_vehicle_deleted_at ON vehicles (deleted_at);
CREATE INDEX IF NOT EXISTS idx_sale_vehicle_id ON sales (vehicle_id);
CREATE INDEX IF NOT EXISTS idx_sale_payment_status ON sales (payment_status);

-- Dados iniciais de veiculos
INSERT INTO vehicles (brand, model, year, color, price, status, created_at) VALUES
('Toyota', 'Corolla', 2022, 'Prata', 98000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Honda', 'Civic', 2021, 'Preto', 92000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Volkswagen', 'Gol', 2023, 'Branco', 58000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Chevrolet', 'Onix', 2022, 'Vermelho', 65000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Fiat', 'Argo', 2023, 'Azul', 62000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Ford', 'Ka', 2021, 'Prata', 48000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Hyundai', 'HB20', 2022, 'Branco', 68000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Nissan', 'Kicks', 2023, 'Cinza', 98000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Renault', 'Kwid', 2021, 'Amarelo', 42000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Jeep', 'Compass', 2022, 'Preto', 158000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('BMW', 'X1', 2021, 'Branco', 185000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Mercedes-Benz', 'Classe A', 2023, 'Prata', 195000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Audi', 'A3', 2022, 'Cinza', 172000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Volkswagen', 'T-Cross', 2023, 'Verde', 128000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Toyota', 'Hilux', 2022, 'Branco', 248000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Chevrolet', 'S10', 2021, 'Preto', 235000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Fiat', 'Toro', 2023, 'Vermelho', 168000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Honda', 'HR-V', 2022, 'Azul', 118000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Hyundai', 'Creta', 2023, 'Branco', 128000.00, 'AVAILABLE', CURRENT_TIMESTAMP),
('Nissan', 'Versa', 2021, 'Prata', 78000.00, 'AVAILABLE', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- Exemplo de veiculos vendidos
INSERT INTO vehicles (brand, model, year, color, price, status, created_at) VALUES
('Toyota', 'Corolla', 2020, 'Branco', 85000.00, 'SOLD', CURRENT_TIMESTAMP),
('Honda', 'Civic', 2019, 'Prata', 78000.00, 'SOLD', CURRENT_TIMESTAMP),
('Volkswagen', 'Polo', 2021, 'Azul', 68000.00, 'SOLD', CURRENT_TIMESTAMP)
ON CONFLICT DO NOTHING;

-- Exemplo de vendas
INSERT INTO sales (vehicle_id, buyer_name, buyer_email, buyer_cpf, sale_price, payment_status, payment_id, sale_date, created_at)
SELECT 
    v.id,
    'João Silva',
    'joao.silva@email.com',
    '123.456.789-00',
    v.price,
    'APPROVED',
    'PAY-' || v.id || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::TEXT,
    CURRENT_TIMESTAMP - INTERVAL '5 days',
    CURRENT_TIMESTAMP - INTERVAL '5 days'
FROM vehicles v
WHERE v.status = 'SOLD'
LIMIT 1
ON CONFLICT DO NOTHING;

INSERT INTO sales (vehicle_id, buyer_name, buyer_email, buyer_cpf, sale_price, payment_status, payment_id, sale_date, created_at)
SELECT 
    v.id,
    'Maria Santos',
    'maria.santos@email.com',
    '987.654.321-00',
    v.price,
    'APPROVED',
    'PAY-' || v.id || '-' || EXTRACT(EPOCH FROM CURRENT_TIMESTAMP)::TEXT,
    CURRENT_TIMESTAMP - INTERVAL '3 days',
    CURRENT_TIMESTAMP - INTERVAL '3 days'
FROM vehicles v
WHERE v.status = 'SOLD'
OFFSET 1
LIMIT 1
ON CONFLICT DO NOTHING;

-- Log de finalizacao
DO $$
BEGIN
    RAISE NOTICE 'Banco de dados inicializado com sucesso!';
    RAISE NOTICE 'Total de veiculos: %', (SELECT COUNT(*) FROM vehicles);
    RAISE NOTICE 'Total de vendas: %', (SELECT COUNT(*) FROM sales);
END $$;



