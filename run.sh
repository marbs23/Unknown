#!/bin/bash

# Nombre del archivo de salida de Icarus
OUT="simv.vvp"

echo "[1] Eliminando compilaciones anteriores..."
rm -f $OUT dump.vcd

echo "[2] Compilando todos los archivos .v del proyecto..."
iverilog -o $OUT *.v

if [ $? -ne 0 ]; then
    echo "[ ERROR ] Falló la compilación."
    exit 1
fi

echo "[3] Ejecutando la simulación..."
vvp $OUT

if [ $? -ne 0 ]; then
    echo "[ ERROR ] Falló la ejecución de la simulación."
    exit 1
fi

# Verifica que el testbench haya generado dump.vcd
if [ ! -f dump.vcd ]; then
    echo "[ WARN ] No se generó dump.vcd. ¿Incluiste \$dumpfile y \$dumpvars en el testbench?"
    exit 1
fi

echo "[4] Abriendo GTKWave..."
gtkwave dump.vcd &
