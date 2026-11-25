# Otra Más · iOS

Maqueta navegable de alta fidelidad de la app (SwiftUI, iOS 17+, solo iPhone y vertical). No tiene backend: todo corre en memoria con los datos del diseño aprobado (`propuestas/entrenadores/pantallas/app-v4.html`).

## Generar y compilar

```sh
brew install xcodegen          # una vez
xcodegen generate              # crea OtraMas.xcodeproj (no se versiona)
xcodebuild -project OtraMas.xcodeproj -scheme OtraMas \
  -destination 'platform=iOS Simulator,name=<tu simulador>' CODE_SIGNING_ALLOWED=NO test
```

Para correr los tests de humo en Release (allí se cerraba Tu Local Web): sumá `-configuration Release ENABLE_TESTABILITY=YES`.

Ilustraciones de ejercicios: `./importar-ejercicios.sh` pasa `propuestas/entrenadores/ejercicios/recortes/<sexo>/<id>.png` a JPG de 400×400 en `OtraMas/Recursos/Ejercicios/` y regenera `Nucleo/Catalogo.swift` desde `catalogo.json`. Después hay que correr `xcodegen generate`.

Capturas de cada pantalla: `./capturar.sh` (o `./capturar.sh inicio cuotas`). Quedan en `capturas/`. Para abrir una pantalla directo, pasá el argumento de arranque `-pantalla <nombre>`. Los nombres posibles son `rutinas`, `rutina-detalle`, `asignar`, `enviar`, `pdf`, `perfil`, `editar-perfil`, `asi-te-ven`, `qr`, `planes`, `cobros-pantalla`, `clases`, `avisos`, `ajustes-profe`, `ficha-progreso`, `ficha-pagos`, `ficha-asistencia`, `mas`, `historial`, `progreso`, `mis-clases`, `pagos`, `avisos-alumno`, `perfil-alumno`, `onboarding` (con `-paso N -ladoOnb profe|alumno`), `carga`, `ajustes`, `ejercicios`, `ejercicio`, `inicio`, `menu`, `tumes`, `cuotas`, `horario`, `suspender`, `alumnos`, `ficha`, `rutina`, `cobrar`, `lista`, `nuevo`, `hoy`, `logros` y `miplan`.

## Estructura

- `OtraMas/App`: el punto de entrada, el onboarding (una pregunta por pantalla; el resultado es un `Perfil` guardado en el teléfono), la carga con un tip y el acceso a Ajustes (se toca la foto) y al cambio de lado (se deja apretada). Desde Ajustes se puede rehacer el onboarding.
- `OtraMas/Nucleo`: los modelos, `Perfil`, la biblioteca `Ejercicio` (con `ilustracion(para: Sexo)`), los tips, el protocolo `Datos`, `DatosDeMuestra` y `Estado` (`@Observable`), que es lo único que leen las pantallas.
- `OtraMas/Tema`: los colores, la tipografía (Archivo y Figtree variables, con `wght` y `wdth`), los radios, los espacios y las sombras.
- `OtraMas/Componentes`: la banda, la tarjeta, los botones, el stepper, el anillo (el algoritmo `data-anillo` porteado), los gráficos, la medalla, la barra flotante con el +1 y los íconos.
- `OtraMas/Pantallas/Profe` y `OtraMas/Pantallas/Alumno`: las pantallas de cada lado.
  - **Profe:** la barra es Inicio · Alumnos · +1 · Rutinas · Cuotas.
    - Desde Inicio: Horario (con la próxima clase o «Semana»), Tu mes y la grilla «Tu negocio» (Cobros, Planes, Clases, Avisos, Tu mes y Ajustes).
    - Ficha con pestañas: Resumen, Progreso, Pagos, Asistencia y Notas.
    - Rutinas: plantillas, detalle, asignar, enviar y PDF A4.
    - Tu perfil: editor por secciones, «Así te ven» y QR. Se abre tocando la foto.
  - **Alumno:** pestañas Hoy, Logros, Mi plan y Más. En «Más» están Historial, Progreso, Mis clases, Pagos, Avisos y Perfil.
- Las clases salen del horario semanal fijo (`ClaseFija`) más los cambios puntuales (`AjusteClase`), así que cualquier fecha tiene sus clases.

## Conectar datos reales

1. Escribí una implementación nueva del protocolo `Datos` (`Nucleo/Datos.swift`), por ejemplo `DatosApi`. Tiene que devolver `PanelProfe` y `PanelAlumno` y persistir las acciones: confirmar, cobrar, suspender, pasar lista, guardar la rutina, etcétera.
2. Pasala al crear el estado: en `OtraMasApp`, `Estado(datos: DatosApi())`.

Con eso alcanza: las pantallas no cambian. `Estado` aplica cada acción en memoria al instante y después llama a `datos`. Al arrancar, `Estado.cargar()` trae lo último.

Regla: nunca uses `async let`, porque cierra la app en Release. Las cargas van una detrás de otra.
