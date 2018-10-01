## %IP% = localhost ou localhost
## %PORTNUM% = 5433

## chemin du binaire
D:

cd D:\Logiciels\pgsql\bin

## creation des utilisateurs

CREATE ROLE "www-data" LOGIN ENCRYPTED PASSWORD '' NOSUPERUSER INHERIT NOCREATEDB NOCREATEROLE;
  
CREATE ROLE jrmorreale LOGIN ENCRYPTED PASSWORD '' SUPERUSER INHERIT CREATEDB CREATEROLE;

CREATE ROLE deploy LOGIN SUPERUSER INHERIT NOCREATEDB NOCREATEROLE;

# export du schéma "public" depuis DRI
# edition manuelle pour ne retenir que les enums et pas les fonctions postgis
pg_dump.exe --host localhost --port 5433 --username "jrmorreale" --schema-only --schema "public" -Fp --file="D:/SIA/fichiers/dump/2017_06_03_siacg62_public_schema_only.sql" "siacg62"

## export du schema "app"
pg_dump.exe --host localhost --port 5433 --username "jrmorreale" --schema-only --schema "app" -Fc --file="D:/SIA/fichiers/dump/2017_06_03_siacg62_app_schema_only.backup" "siacg62"

# export des données du schéma "app"
pg_dump --host localhost --port 5433 --username "jrmorreale" --data-only --schema "app" -Fc --file="D:/SIA/fichiers/dump/2017_06_03_siacg62_app_data_only.backup" "siacg62"

####################################
## creation de la nouvelle base
psql.exe --host localhost --port 5433 -U "jrmorreale" --dbname=postgres -c "CREATE DATABASE siacg62_new WITH TEMPLATE=template_postgis OWNER = postgres TABLESPACE = pg_default CONNECTION LIMIT = -1;"

# importation du schema "public" (que les enums)
psql.exe --host localhost --port 5433 -U "jrmorreale" --dbname="siacg62_new" -1 -f "D:\SIA\fichiers\dump\2017_06_02_siacg62_public_schema_only.sql"

## importation du schema "app"
psql.exe --host localhost --port 5433 --username "jrmorreale" --dbname="siacg62_new" -c "CREATE SCHEMA app AUTHORIZATION postgres;GRANT ALL ON SCHEMA app TO postgres;GRANT ALL ON SCHEMA app TO ""www-data"";GRANT ALL ON SCHEMA app TO jrmorreale;"

pg_restore.exe --host localhost --port 5433 -U "jrmorreale" --dbname="siacg62_new" --format custom --schema-only --schema=app --exit-on-error "D:/SIA/fichiers/dump/2017_06_03_siacg62_app_schema_only.backup"

## importation des données du schéma "app"
pg_restore.exe --host localhost --port 5433 --dbname "siacg62_new" --username "jrmorreale" --format custom --data-only --schema=app --single-transaction "D:\SIA\fichiers\dump\2017_06_03_siacg62_app_data_only.backup"
