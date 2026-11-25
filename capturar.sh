#!/bin/zsh
# Saca capturas de cada pantalla en el simulador ya instalado (no crea ni borra simuladores).
# Uso: ./capturar.sh [pantalla ...]   (sin argumentos, todas)
set -e
SIM=${SIM:-762618FE-D6AB-4A56-BC66-248224D158DC}
APP=${APP:-build/dd/Build/Products/Debug-iphonesimulator/OtraMas.app}
cd "$(dirname "$0")"
mkdir -p capturas
xcrun simctl boot "$SIM" 2>/dev/null || true
xcrun simctl bootstatus "$SIM" -b >/dev/null
xcrun simctl install "$SIM" "$APP"
typeset -A horas=(rutinas 9:30 rutina-detalle 9:31 asignar 9:32 enviar 9:33 pdf 9:34 carga 9:41 ajustes 7:35 ejercicios 9:20 ejercicio 9:21 selector 9:41 inicio 7:35 menu 7:35 tumes 7:36 cuotas 7:41 horario 15:20 suspender 15:20 alumnos 9:10 ficha 9:12 rutina 21:05 cobrar 7:50 lista 9:05 nuevo 9:15 hoy 19:05 logros 19:40 miplan 19:42)
if (( $# )); then lista=($@); else lista=(carga inicio menu tumes cuotas horario suspender alumnos ficha rutina cobrar lista nuevo ajustes ejercicios ejercicio rutinas rutina-detalle asignar enviar pdf hoy logros miplan); fi
for p in $lista; do
  xcrun simctl status_bar "$SIM" override --time "${horas[$p]:-9:41}" --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null
  xcrun simctl terminate "$SIM" ar.com.otramas.app 2>/dev/null || true
  xcrun simctl launch "$SIM" ar.com.otramas.app -pantalla "$p" >/dev/null
  sleep ${ESPERA:-3}
  xcrun simctl io "$SIM" screenshot "capturas/$p.png" >/dev/null 2>&1
  echo "capturas/$p.png"
done
# Onboarding: cada paso de cada lado (ONB=0 para saltearlo).
if [[ "${ONB:-1}" == 1 && $# -eq 0 ]]; then
  typeset -A cant=(alumno 12 profe 7)
  for l in profe alumno; do
    for ((i=0; i<${cant[$l]}; i++)); do
      xcrun simctl status_bar "$SIM" override --time 9:41 --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3 --dataNetwork wifi >/dev/null
      xcrun simctl terminate "$SIM" ar.com.otramas.app 2>/dev/null || true
      xcrun simctl launch "$SIM" ar.com.otramas.app -pantalla onboarding -paso $i -ladoOnb $l >/dev/null
      sleep ${ESPERA:-3}
      f=$(printf "capturas/onboarding-%s-%02d.png" $l $((i+1)))
      xcrun simctl io "$SIM" screenshot "$f" >/dev/null 2>&1
      echo "$f"
    done
  done
fi
