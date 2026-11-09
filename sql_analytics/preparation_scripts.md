## Loading the data into PostgreSQL Database
```
\copy olist_geolocation (geolocation_zip_code, geolocation_lat, geolocation_lng, geolocation_city, geolocation_state) FROM 
    '/home/billy/Documents/olist_geolocation.csv'
    DELIMITER ',' CSV HEADER;
```