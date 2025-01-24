-- Create a new database
CREATE DATABASE ny_taxi;

-- FIXME: taxi_user gets permission error on schema public
-- for now not using (using superuser kestra)

-- Create a new user
CREATE USER taxi_user WITH PASSWORD 't4x1_us3r';

-- Grant privileges on the database to the user
GRANT ALL PRIVILEGES ON DATABASE ny_taxi TO taxi_user;
GRANT USAGE, CREATE ON SCHEMA public TO taxi_user;
