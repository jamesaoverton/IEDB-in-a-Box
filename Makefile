.PHONY: refresh clean rdump restore_upstream_maria restore_upstream_postgres

refresh: rdump restore_upstream_maria restore_upstream_postgres populate_postgres

clean:
	rm -Rf remote_dumps

remote_dumps:
	mkdir $@

rdump: | remote_dumps
	wget http://www.iedb.org/downloader.php?file_name=doc/iedb_public.sql.gz -O remote_dumps/iedb_public.sql.gz

restore_upstream_maria:
	mysql --user=root --execute "DROP DATABASE IF EXISTS upstream"
	mysql --user=root --execute "CREATE DATABASE upstream"
	zcat remote_dumps/iedb_public.sql.gz | mysql --user=root --database=upstream

restore_upstream_postgres:
	psql -U iedbadmin -d iedb -c "DROP SCHEMA IF EXISTS upstream CASCADE"
	pgloader tools/pgload_recipe.sql

populate_postgres:
	psql -U iedbadmin -d iedb -t -1 -f sql/schemas/classes.sql
	psql -U iedbadmin -d iedb -t -1 -f sql/schemas/core.sql
	psql -U iedbadmin -d iedb -t -1 -f sql/populate_core.sql
	psql -U iedbadmin -d iedb -t -1 -f sql/schemas/joined.sql
