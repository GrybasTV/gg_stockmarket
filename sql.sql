CREATE TABLE IF NOT EXISTS stocks (
    stock_id VARCHAR(50) PRIMARY KEY,
    price INT NOT NULL
);

INSERT INTO stocks (stock_id, price) VALUES 
('bond1', 1000),
('bond2', 1000),
('bond3', 1000);
