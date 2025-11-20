#!/bin/bash

# Moverse a la carpeta del script
cd "$(dirname "$0")"

echo "🔍 Buscando archivos .v en ../Design y en Simulation..."

# Archivos Verilog de diseño (recursivo)
DESIGN_FILES=$(find ../Design -type f -name "*.v")

# Testbench ubicado en esta carpeta
TB_FILE="testbench.v"

echo "   Archivos de diseño:"
echo "$DESIGN_FILES"
echo ""
echo "   Testbench:"
echo "$TB_FILE"
echo ""

# Compilar con Icarus Verilog
echo "⚙️  Compilando..."
iverilog -o sim.out $DESIGN_FILES $TB_FILE

if [ $? -ne 0 ]; then
    echo "❌ Error en compilación"
    exit 1
fi

# Ejecutar simulación con vvp
echo "▶️ Ejecutando simulación..."
vvp sim.out

# Abrir waveform si existe
if [ -f "dump.vcd" ]; then
    echo "📈 Abriendo GTKWave..."
    gtkwave dump.vcd &
else
    echo "⚠️ No se generó dump.vcd (¿agregaste \$dumpfile y \$dumpvars en el testbench?)"
fi
