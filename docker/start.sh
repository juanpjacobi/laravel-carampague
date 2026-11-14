#!/bin/sh
# Arranque del backend en Railway.
# 1. Espera a que MySQL acepte conexiones.
# 2. Si RESET_DB_TOKEN cambio desde el ultimo arranque, vuelve la base a cero
#    (docker/reset-db.sh) y marca el token como aplicado.
# 3. Carga schema / migraciones / seeders si hacen falta (docker/prepare-db.sh).
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

set +e
php docker/reset-token.php check
RESET_STATUS=$?
set -e

if [ "$RESET_STATUS" -eq 10 ]; then
  sh docker/reset-db.sh
  php docker/reset-token.php mark
elif [ "$RESET_STATUS" -ne 0 ]; then
  echo "No se pudo evaluar RESET_DB_TOKEN (codigo $RESET_STATUS)."
  exit 1
else
  sh docker/prepare-db.sh
fi

php artisan storage:link || true
php artisan config:cache
php artisan route:cache

echo "==> Servidor en puerto ${PORT:-8080}"
exec php artisan serve --host=0.0.0.0 --port="${PORT:-8080}"
