<?php
/**
 * Carga database/schema/mysql-schema.sql usando la conexion PDO de Laravel.
 *
 * Reemplaza al cliente `mysql` de linea de comandos que usa `artisan migrate`
 * para cargar el schema dump, que en la imagen Alpine no puede autenticarse
 * contra MySQL 8 (plugin caching_sha2_password ausente en el cliente MariaDB).
 *
 * - Si la tabla `users` ya existe, no hace nada.
 * - Respeta las directivas DELIMITER del dump (procedimientos y triggers).
 * - Quita las clausulas DEFINER para no depender del usuario original.
 */

require __DIR__ . '/../vendor/autoload.php';

$app = require __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

if (Schema::hasTable('users')) {
    echo "Schema ya cargado (existe la tabla users), no se hace nada.\n";
    exit(0);
}

$path = __DIR__ . '/../database/schema/mysql-schema.sql';
if (! is_file($path)) {
    fwrite(STDERR, "No se encontro el schema dump en {$path}\n");
    exit(1);
}

$delimiter = ';';
$buffer = '';
$statements = [];

foreach (file($path, FILE_IGNORE_NEW_LINES) as $line) {
    $trimmed = trim($line);

    if (preg_match('/^DELIMITER\s+(\S+)/i', $trimmed, $m)) {
        $delimiter = $m[1];
        continue;
    }

    if ($buffer === '' && ($trimmed === '' || str_starts_with($trimmed, '--'))) {
        continue;
    }

    $buffer .= $line . "\n";

    if (str_ends_with(rtrim($trimmed), $delimiter)) {
        $statement = rtrim(substr(rtrim($buffer), 0, -strlen($delimiter)));
        $statement = preg_replace('/\bDEFINER\s*=\s*`[^`]*`@`[^`]*`\s*/i', '', $statement);

        if (trim($statement) !== '') {
            $statements[] = $statement;
        }
        $buffer = '';
    }
}

if (trim($buffer) !== '') {
    $statements[] = $buffer;
}

echo 'Ejecutando ' . count($statements) . " sentencias del schema dump...\n";

DB::unprepared('SET FOREIGN_KEY_CHECKS=0');

foreach ($statements as $i => $sql) {
    try {
        DB::unprepared($sql);
    } catch (\Throwable $e) {
        $preview = preg_replace('/\s+/', ' ', substr($sql, 0, 160));
        fwrite(STDERR, "Fallo la sentencia #" . ($i + 1) . ": {$preview}\n{$e->getMessage()}\n");
        exit(1);
    }
}

DB::unprepared('SET FOREIGN_KEY_CHECKS=1');

echo "Schema cargado correctamente.\n";
