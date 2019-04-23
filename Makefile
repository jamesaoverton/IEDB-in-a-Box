.PHONY: refresh clean rdump refresh_maria_upstream refresh_postgres_upstream

refresh: rdump refresh_maria_upstream refresh_postgres_upstream refresh_core

clean:
	rm -Rf remote_dumps

remote_dumps:
	mkdir $@

rdump: | remote_dumps
	wget http://www.iedb.org/downloader.php?file_name=doc/iedb_public.sql.gz -O remote_dumps/iedb_public.sql.gz

refresh_maria_upstream:
	mysql --user=root --execute "DROP DATABASE IF EXISTS upstream"
	mysql --user=root --execute "CREATE DATABASE upstream"
	zcat remote_dumps/iedb_public.sql.gz | mysql --user=root --database=upstream

refresh_postgres_upstream:
	psql -U iedbadmin -d iedb -c "DROP SCHEMA IF EXISTS upstream CASCADE"
	pgloader tools/pgload_recipe.sql

refresh_core:
	psql -U iedbadmin -d iedb -t -1 -f schemas/core.sql
	psql -U iedbadmin -d iedb -t -1 -f populate_core.sql
