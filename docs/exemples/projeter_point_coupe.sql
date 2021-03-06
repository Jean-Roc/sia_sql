-- table contenant l'axe de la coupe
CREATE TABLE ed_operations.lecluse_coupes_geol (
  id integer NOT NULL,
  geom geometry(LineString,2154),
  CONSTRAINT lecluse_coupes_geol_pkey PRIMARY KEY (id)
  );
  
-- table contenant les ISO
CREATE TABLE ed_operations.lecluse_coupes_geol_iso (
  id serial NOT NULL,
  geom geometry(Point,2154),
  coupe integer,
  "X" double precision,
  "Y" double precision,
  "Z" double precision,
  numero_iso integer
  );
  
/*

* buffer_iso permet de sélectionner les points se situant à l'intérieur d'une zone tampon d'une coupe
* project_iso va projeter les points sélectionnés le long de cette coupe et créer une nouvelle géométrie à cet emplacement
* axe_iso va calculer la distance cartésienne entre le début de la coupe et l'iso

* ed_operations.lecluse_coupes_geol correspond à une couche contenant les lignes, il est important qu'elles soient créées dans le bon sens pour que la reqûete iso parte toujours du point A vers B
* ed_operations.lecluse_coupes_geol_iso correspond à la sélection de points faite par cyril

*/
WITH 
buffer_iso AS (
SELECT 
  coupes.id AS numero_coupe,
  iso.numero_iso,
  CAST(iso."Z" AS NUMERIC(5,2)) AS axe_z,
  iso.geom
FROM
  ed_operations.lecluse_coupes_geol_iso AS iso,
  ed_operations.lecluse_coupes_geol AS coupes
WHERE 
  ST_Within(iso.geom, ST_Buffer(coupes.geom, 1))
),

project_iso AS (
SELECT
  buffer_iso.numero_coupe,
  buffer_iso.numero_iso,
  buffer_iso.axe_z,
  ST_Line_Interpolate_Point(
	coupes.geom,
	ST_Line_Locate_Point(
		coupes.geom,
		ST_GeometryN(buffer_iso.geom, 1)
	)
  ) AS geom
FROM buffer_iso
JOIN ed_operations.lecluse_coupes_geol AS coupes ON coupes.id = buffer_iso.numero_coupe
)

SELECT 
  project_iso.numero_coupe,
  project_iso.numero_iso,
  CAST(ST_Distance(ST_StartPoint(coupes.geom), project_iso.geom) AS NUMERIC(5,2)) AS axe_x,
  project_iso.axe_z
FROM project_iso
JOIN ed_operations.lecluse_coupes_geol AS coupes ON coupes.id = project_iso.numero_coupe
ORDER BY numero_coupe, axe_x