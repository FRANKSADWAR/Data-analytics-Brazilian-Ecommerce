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

CREATE TABLE olist_sellers (
    seller_id VARCHAR(255) NOT NULL,
    seller_zip_code_prefix BIGINT NOT NULL,
    FOREIGN KEY (seller_zip_code_prefix) REFERENCES olist_geolocation(geolocation_zip_code_prefix) ON DELETE CASCADE
);

ALTER TABLE olist_sellers ADD CONSTRAINT seller_id_pkey PRIMARY KEY (seller_id);


CREATE TABLE olist_products (
    product_id VARCHAR(255) NOT NULL PRIMARY KEY,
    product_name_length VARCHAR(255),
    product_description_length DECIMAL(10,1),
    product_photos_qty DECIMAL(10,1),
    product_weight_g DECIMAL(10,1),
    product_height_cm DECIMAL(10,1),
    product_width_cm DECIMAL(10,1) CONSTRAINT positive_width CHECK (product_width_cm > 0),
    product_category VARCHAR (255)
)