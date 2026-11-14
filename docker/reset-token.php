<?php
/**
 * Decide si hay que reiniciar la base segun la variable RESET_DB_TOKEN.
 *
 *   php docker/reset-token.php check   -> exit 10 si el token cambio (hay que resetear),
 *                                         exit 0 si no hay nada que hacer.
 *   php docker/reset-token.php mark    -> guarda el token actual como aplicado.
 *
 * El token aplicado se guarda en la tabla `deploy_meta`, asi un mismo valor
 * nunca dispara dos resets aunque el servicio se reinicie.
 */

require __DIR__ . '/../vendor/autoload.php';

$app = require __DIR__ . '/../bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

$action = $argv[1] ?? 'check';
$token = trim((string) getenv('RESET_DB_TOKEN'));

if ($token === '') {
    echo "RESET_DB_TOKEN vacio: no se reinicia la base.\n";
    exit(0);
}

if (! Schema::hasTable('deploy_meta')) {
    DB::statement('CREATE TABLE deploy_meta (`key` VARCHAR(64) PRIMARY KEY, `value` TEXT NULL, updated_at TIMESTAMP NULL)');
}

$stored = DB::table('deploy_meta')->where('key', 'reset_db_token')->value('value');

if ($action === 'mark') {
    DB::table('deploy_meta')->updateOrInsert(
        ['key' => 'reset_db_token'],
        ['value' => $token, 'updated_at' => now()]
    );
    echo "Token de reset '{$token}' marcado como aplicado.\n";
    exit(0);
}

if ($stored === $token) {
    echo "RESET_DB_TOKEN sin cambios ('{$token}'): no se reinicia la base.\n";
    exit(0);
}

echo "RESET_DB_TOKEN cambio (antes: " . ($stored ?? 'ninguno') . ", ahora: {$token}): se reinicia la base.\n";
exit(10);
