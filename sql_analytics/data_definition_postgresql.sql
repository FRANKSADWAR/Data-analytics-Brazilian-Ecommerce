CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix BIGINT NOT NULL PRIMARY KEY,
    geolocation_lat DECIMAL(10,7) NOT NULL,
    geolocation_lng DECIMAL(10, 7) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state VARCHAR(100) NOT NULL
)
CREATE INDEX idx_geolocation ON olist_geolocation(geolocation_zip_code_prefix);

CREATE TABLE olist_customers (
    customer_id VARCHAR(255) NOT NULL PRIMARY KEY,
    customer_zip_code_prefix BIGINT NOT NULL,
);