CREATE USER fv_admin PASSWORD 'password';
CREATE USER fv_cache PASSWORD 'password';
CREATE USER fv_mapserv PASSWORD 'password';

CREATE DATABASE fv WITH OWNER fv_admin;
\c fv
CREATE EXTENSION postgis;
