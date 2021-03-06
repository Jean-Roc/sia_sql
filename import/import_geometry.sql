-- importation de géométrie
-- le code 900913 est utilisé à la place du 3857 pour des raisons "historiques"...


-- la commande shp2pgsql convertir un fichier .shp en une table PgSQL
-- shp2pgsql -s 900913 "FICHIER" TABLE | psql -d BASE

cd D:\Logiciels\postgis-pg94\bin

 -h, --host=HOSTNAME      database server host or socket directory
  -p, --port=PORT          database server port number
  -U, --username=NAME      connect as specified database user
  -W, --password           force password prompt (should happen automatically)
  -e, --exit-on-error 
  
psql.exe --host localhost --port 5433 -U "jrmorreale" --dbname="siacg62"

shp2pgsql --host localhost --port 5433 -U "jrmorreale" --dbname="siacg62" -s 900913 "/home/cg62/restore/emprise.shp" emprise | psql -d siacg62


shp2pgsql -s 900913 "/home/cg62/restore/emprise.shp" emprise | psql -d siacg62
shp2pgsql -s 900913 "/home/cg62/restore/emprise_point.shp" emprise_point | psql -d siacg62

shp2pgsql -s 900913 "/home/cg62/restore/ue.shp" ue | psql -d siacg62
shp2pgsql -s 900913 -S "/home/cg62/restore/ue_point.shp" ue_point | psql -d siacg62
shp2pgsql -s 900913 "/home/cg62/restore/ue_ligne.shp" ue_ligne | psql -d siacg62

shp2pgsql -s 900913 "/home/cg62/restore/sections.shp" sections | psql -d siacg62
shp2pgsql -s 900913 "/home/cg62/restore/parcelle.shp" parcelle | psql -d siacg62


-- ajout ue

UPDATE app.ue AS "a"
SET the_geom = ST_SetSRID(ST_Force_2D(b.geom), 900913)
FROM public."ue"  AS "b"
WHERE 
  a.numero = b.ue::int 
  AND a.id_projet = b.id_projet::int
  AND a.the_geom IS NULL
  AND ST_IsValid(b.geom) != 'f';
  
DROP TABLE public.ue;

UPDATE app.ue SET geom = ST_Force_2D(public."ue".geom) 
FROM public."ue" 
WHERE numero = public."ue".ue::int AND app.ue.id_projet = public."ue".id_projet::int AND app.ue.geom IS NULL;
DROP TABLE public.ue;

UPDATE app.ue SET geom = ST_Force_2D(public."ue_point".geom) 
FROM public."ue_point" 
WHERE numero = public."ue_point".ue::int AND app.ue.id_projet = public."ue_point".id_projet;
DROP TABLE public.ue_point;

UPDATE app.ue SET geom = ST_Force_2D(public."ue_ligne".geom) 
FROM public."ue_ligne" 
WHERE numero = public."ue_ligne".ue::int AND app.ue.id_projet = public."ue_ligne".id_projet;
DROP TABLE public.ue_ligne;

-- ajout emprise
UPDATE app.projet 
SET the_geom = ST_SetSRID(emprise.geom, 900913)
FROM public.emprise
WHERE projet.id = emprise.id;

DROP TABLE emprise;

SELECT ST_SRID(geom) FROM public."emprise"
SELECT ST_GeometryType(geom) FROM public."emprise"

UPDATE app.projet SET geom = public."emprise_point".geom  FROM public."emprise_point" WHERE app.projet.id = public."emprise_point".id;
DROP TABLE emprise_point;

UPDATE public.sections SET id_commune = app.commune.id FROM app.commune WHERE app.commune.code_insee LIKE public.sections.insee;

-- ajout de parcelles depuis un import
INSERT INTO app.section (id, nom, id_commune, geom) SELECT id, nom, id_commune, geom FROM public.sections;

INSERT INTO app.parcelle (numero, id_section, debut_validite, the_geom) 
SELECT numero, id_section, debut_val, ST_SetSRID(geom, 900913)
FROM public.parcelle;

DROP TABLE parcelle;

-- export des emprises
psql -d siacg62 -U "jrmorreale" -W -A -F"	" -c "SELECT id, ST_AsEWKT(geom) AS wkt_geom FROM app.projet WHERE projet.geom IS NOT NULL" > '/home/cg62/dump/export_emprise.csv'