-- CREATE THE RELATIONAL DATA MODEL

CREATE DATABASE brazil_ecommerce;


CREATE TABLE olist_geolocation (
    geolocation_zip_code_prefix BIGINT NOT NULL PRIMARY KEY,
    geolocation_lat DECIMAL(10, 7) NOT NULL,
    geolocation_lng DECIMAL(10, 7) NOT NULL,
    geolocation_city VARCHAR(100) NOT NULL,
    geolocation_state VARCHAR(100) NOT NULL,
    INDEX(geolocation_zip_code_prefix)
)
ALTER TABLE olist_geolocation DROP INDEX idx_geolocation_zip_code;



CREATE TABLE olist_customers (
    customer_id VARCHAR(255) NOT NULL PRIMARY KEY,
    customer_zip_code_prefix BIGINT NOT NULL
)
CREATE INDEX customer_idx ON olist_customers(customer_zip_code);


CREATE TABLE olist_sellers(
    seller_id VARCHAR(255) NOT NULL PRIMARY KEY,
    seller_zip_code_prefix BIGINT NOT NULL,
    FOREIGN KEY(seller_zip_code_prefix) REFERENCES olist_geolocation(geolocation_zip_code_prefix) ON DELETE CASCADE
)
CREATE INDEX idx_olist_sellers ON olist_sellers(seller_id);


CREATE TABLE olist_products(
    product_id VARCHAR(255) NOT NULL PRIMARY KEY,
    product_name_length VARCHAR(255),
    product_description_length DECIMAL(10, 1),
    product_photos_qty DECIMAL(10, 1),
    product_weight_g DECIMAL(10, 1),
    product_length_cm DECIMAL(10, 1),
    product_height_cm DECIMAL(10,1),
    product_width_cm DECIMAL(10,1),
    product_category VARCHAR(255)
)
CREATE INDEX product_category_idx ON olist_products(product_category);


CREATE TABLE olist_orders(
    order_id VARCHAR(255) NOT NULL PRIMARY KEY,
    customer_id VARCHAR(255) NOT NULL,
    order_status VARCHAR(100),
    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    FOREIGN KEY(customer_id) REFERENCES olist_customers(customer_id) ON UPDATE CASCADE
)
CREATE INDEX purchase_time_idx ON olist_orders(order_purchase_timestamp);
CREATE INDEX customer_ids ON olist_orders(customer_id);


CREATE TABLE olist_order_items (
    order_id VARCHAR(255) NOT NULL,
    order_item_id INT NOT NULL,
    product_id VARCHAR(255),
    seller_id VARCHAR(255),
    shipping_limit_date TIMESTAMP,
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2)
)
CREATE INDEX item_id_idx ON olist_order_items(order_item_id);
  


CREATE TABLE olist_order_reviews(
    review_id VARCHAR(255) NOT NULL PRIMARY KEY,
    order_id VARCHAR(255),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message VARCHAR(255),
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP
)
CREATE INDEX order_id_idx ON olist_order_reviews(order_id);

CREATE TABLE olist_order_payments(
    order_id VARCHAR(255) NOT NULL,
    payment_sequential INT,
    payment_type VARCHAR(100),
    payment_installments INT,
    payment_value DECIMAL(10, 2)
)


-- Index the tables to have a better query perfomance
ALTER TABLE olist_orders
ADD INDEX orders_idx (order_id, customer_id);
ALTER TABLE olist_orders
ADD INDEX orders_idx (order_id);


-- Insert example to test datetime

INSERT INTO olist_orders (order_id, customer_id, order_status, order_purchase_timestamp, order_approved_at, order_delivered_carrier_date,order_delivered_customer_date,order_estimated_delivery_date)  
VALUES ('e481f51cbdc54678b7cc49136f2d6af7','9ef432eb6251297304e76186b10a928d','delivered','2017-10-02 10:56:33','2017-10-02 11:07:15','2017-10-04 19:55:00','2017-10-10 21:25:13','2017-10-18 00:00:00');

WITH
    customer_table AS (
        SELECT 
            name, 
            customer_name, 
            payment_terms ,
            CASE
                WHEN payment_terms = 'Advance Payment' THEN 0
                WHEN payment_terms = 'Cash On Delivery' THEN 0
                WHEN payment_terms = '7 Days Credit' THEN 7 
                WHEN payment_terms = '14 Days Customer' THEN 14
                WHEN payment_terms = '30 Days Credit' THEN 30
                WHEN payment_terms = '45 Days Customer' THEN 45
                WHEN payment_terms = '60 Days Customers' THEN 60
                WHEN payment_terms = '90 Days Customer' THEN 90
                WHEN payment_terms = '37 Days' THEN 37
                WHEN payment_terms = '120 Days' THEN 120
                ELSE 0
            END AS credit_days
        FROM `tabCustomer`
    ),
    
    -- Get the invoices for each customer
    invoices_list AS (
        SELECT 
            `tabSales Invoice`.name,
            `tabSales Invoice`.posting_date,
            `tabSales Invoice`.due_date AS erp_due_date,
            DATE_ADD(`tabSales Invoice`.posting_date, INTERVAL cu.credit_days DAY) AS computed_due_date,
            `tabSales Invoice`.customer AS customer_id,
            cu.customer_name,
            cu.credit_days,
            `tabSales Invoice`.party_account_currency,
            `tabSales Invoice`.conversion_rate,
            (CASE 
                WHEN `tabSales Invoice`.party_account_currency = 'USD' 
                THEN `tabSales Invoice`.outstanding_amount * `tabSales Invoice`.conversion_rate 
                ELSE `tabSales Invoice`.outstanding_amount END) AS outstanding_amount_converted,
            `tabSales Invoice`.base_grand_total
        FROM `tabSales Invoice`
        LEFT JOIN customer_table AS cu ON `tabSales Invoice`.customer = cu.name
        WHERE 
            `tabSales Invoice`.docstatus = 1 
            AND `tabSales Invoice`.status NOT IN ('Paid','Return')
    ),
    
    invoices_list_computed AS (
        SELECT
            name,
            customer_id,
            customer_name,
            posting_date,
            erp_due_date,
            DATEDIFF(erp_due_date, posting_date) AS difference_posting_erp_due_date,
            DATEDIFF(computed_due_date, posting_date) AS difference_posting_computed_due_date,
            computed_due_date,
            credit_days,
            party_account_currency,
            outstanding_amount_converted,
            base_grand_total
        FROM invoices_list
        WHERE outstanding_amount_converted > 0
    ),
    
    due_date_tables AS (
        SELECT
            name, 
            customer_id,
            customer_name,
            posting_date,
            erp_due_date,
            difference_posting_erp_due_date,
            difference_posting_computed_due_date,
            (difference_posting_computed_due_date - difference_posting_erp_due_date) AS difference_in_days,
            computed_due_date,
            credit_days,
            outstanding_amount_converted,
            base_grand_total
        FROM invoices_list_computed
        WHERE difference_posting_erp_due_date <> difference_posting_computed_due_date
        ORDER BY posting_date DESC
    ),
    
    payment_schedule_table AS (
        SELECT
            ps.name,
            ps.due_date,
            ps.parent,
            ps.parenttype
            FROM `tabPayment Schedule` AS ps 
        WHERE ps.parenttype = 'Sales Invoice'
    )
    
    SELECT 
        ddt.name AS invoice_id,
        ddt.posting_date,
        ddt.erp_due_date,
        ddt.computed_due_date,
        ddt.credit_days,
        pst.name AS payment_schedule_id,
        pst.due_date AS payment_schedule_due_date,
        pst.parent 
    FROM due_date_tables AS ddt 
    LEFT JOIN payment_schedule_table AS pst ON ddt.name = pst.parent
    
    
    