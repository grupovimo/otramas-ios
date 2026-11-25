#!/bin/zsh
# Pasa las ilustraciones a la app: <origen>/recortes/<sexo>/<id>.png → OtraMas/Recursos/Ejercicios/ej-<sexo>-<id>.jpg
# (400×400, JPG: pesa un décimo que los PNG) y regenera el catálogo Swift desde catalogo.json.
set -e
cd "$(dirname "$0")"
ORIGEN=${1:-/Users/nahuelsantillan/Trabajo/vimo/propuestas/entrenadores/ejercicios}
DESTINO=OtraMas/Recursos/Ejercicios
mkdir -p "$DESTINO"
n=0
for sexo in mujer hombre; do
  for f in "$ORIGEN/recortes/$sexo"/*.png(N); do
    sips -s format jpeg -s formatOptions 78 -Z 400 "$f" --out "$DESTINO/ej-$sexo-$(basename "$f" .png).jpg" >/dev/null
    n=$((n+1))
  done
done
echo "$n ilustraciones en $DESTINO"
python3 - "$ORIGEN/catalogo.json" OtraMas/Nucleo/Catalogo.swift <<'PY'
import json, sys
grupos = {"Piernas y glúteos": "piernas", "Pecho, hombros y tríceps": "empuje", "Espalda y bíceps": "tiron",
          "Core y funcional": "core", "Pilates": "pilates"}
c = json.load(open(sys.argv[1]))
filas = ",\n".join(f'        Ejercicio(id: "{e["id"]}", nombre: "{e["nombre"]}", grupo: .{grupos[e["grupo"]]})' for e in c)
open(sys.argv[2], "w").write(f"""// Generado por importar-ejercicios.sh desde ejercicios/catalogo.json. No editar a mano.

extension DatosDeMuestra {{
    static let ejercicios: [Ejercicio] = [
{filas},
    ]
}}
""")
print(len(c), "ejercicios en el catálogo")
PY
