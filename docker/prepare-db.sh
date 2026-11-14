#!/bin/sh
# Deja la base lista: carga el schema dump si la base esta vacia, corre las
# migraciones pendientes y siembra los datos de referencia si no hay usuarios.
# Es idempotente: sobre una base ya cargada no cambia nada.
set -e

cd /app

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
