<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use App\Models\Feriado;
use Carbon\Carbon;

class FeriadoSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $startDate = Carbon::create(2025, 02, 01);

        // Offsets fijos y distintos: la columna fecha es unica, asi que fechas
        // al azar hacian fallar el seed de forma intermitente.
        $offsets = [3, 17, 24, 38, 52];

        foreach ($offsets as $i => $days) {
            Feriado::create([
                'fecha' => $startDate->copy()->addDays($days)->toDateString(),
                'descripcion' => 'Feriado de prueba #' . ($i + 1),
            ]);
        }
    }
}
