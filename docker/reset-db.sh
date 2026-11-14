#!/bin/sh
# Vuelve la base de datos a cero: borra todas las tablas, recarga el schema
# dump, corre migraciones y vuelve a sembrar los datos de referencia.
#
# Uso manual (con Railway CLI, desde la carpeta del repo):
#   railway ssh -- sh docker/reset-db.sh
#
# Tambien lo invoca docker/start.sh cuando cambia RESET_DB_TOKEN.
set -e

cd /app

echo "==> Borrando todas las tablas"
php artisan db:wipe --force

echo "==> Recargando schema y datos"
sh docker/prepare-db.sh

echo "==> Base de datos reiniciada"
