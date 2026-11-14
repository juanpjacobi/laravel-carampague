#!/bin/sh
# Arranque del backend en Railway.
# 1. Espera a que MySQL acepte conexiones.
# 2. Corre migraciones (la primera vez carga database/schema/mysql-schema.sql).
# 3. Siembra la base solo si todavia no tiene usuarios.
# 4. Cachea config y rutas y levanta el servidor en $PORT.
set -e

cd /app

echo "==> Esperando a la base de datos..."
i=0
until php artisan db:monitor --databases=mysql >/dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge 30 ]; then
    echo "La base de datos no respondio despues de 30 intentos."
    exit 1
  fi
  sleep 2
done

echo "==> Schema inicial (solo si la base esta vacia)"
php docker/load-schema.php

echo "==> Migraciones"
php artisan migrate --force

USERS=$(php artisan tinker --execute='echo \App\Models\User::count();' 2>/dev/null | tail -n 1 | tr -d '[:space:]')
if [ "$USERS" = "0" ]; then
  echo "==> Base vacia: corriendo seeders"
  php artisan db:seed --force
else
  echo "==> La base ya tiene $USERS usuarios, no se corren seeders"
fi

php artisan storage:link || true
php artisan config:cache
php artisan route:cache

echo "==> Servidor en puerto ${PORT:-8080}"
exec php artisan serve --host=0.0.0.0 --port="${PORT:-8080}"
