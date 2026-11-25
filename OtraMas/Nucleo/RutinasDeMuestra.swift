import Foundation

// Rutinas de muestra: las de Lucía («Mías») y las plantillas listas para usar, con ids del catálogo.

extension DatosDeMuestra {
    /// Un ejercicio de rutina a partir del catálogo: series, reps (o segundos), kilos y pausa.
    static func x(_ id: String, _ series: Double, _ reps: Double, _ kilos: Double = 0, _ pausa: Int = 60,
                  t: Bool = false, n: String? = nil) -> EjercicioDeRutina {
        let nombre = ejercicios.first { $0.id == id }?.nombre ?? id
        return EjercicioDeRutina(id: "\(id)-\(UUID().uuidString.prefix(6))", ejercicioId: id, nombre: nombre, foto: "foto-detalle",
                                 focoX: 0.5, focoY: 0.5, series: series, reps: reps, kilos: kilos, pausa: pausa, porTiempo: t, notas: n)
    }

    static func dia(_ letra: String, _ e: [EjercicioDeRutina]) -> DiaRutina {
        DiaRutina(id: letra, nombre: "Día \(letra)", ejercicios: e)
    }

    private static func asignar(_ ids: [String], _ desde: String = "2026-11-02") -> [Asignacion] {
        ids.map { Asignacion(alumnoId: $0, desde: desde) }
    }

    static let rutinasMias: [Rutina] = [
        rutina,
        Rutina(id: "r2", nombre: "Fuerza de la tarde", plan: "Fuerza general · 2 días", dias: [
            dia("A", [x("sentadilla-goblet", 4, 10, 16, 90), x("press-banca", 4, 8, 30, 90), x("remo-mancuerna", 4, 10, 14, 90),
                      x("puente-gluteos", 3, 12, 20), x("plancha", 3, 30, t: true)]),
            dia("B", [x("peso-muerto-rumano", 4, 8, 40, 90), x("press-militar", 3, 10, 20, 90), x("jalon-pecho", 4, 10, 35, 90),
                      x("estocada", 3, 12, 10), x("bicho-muerto", 3, 10)]),
        ], objetivo: "Fuerza", nivel: "Intermedio",
           asignaciones: asignar(["lautaro", "julieta", "franco", "antonella", "agostina", "emiliano", "florencia", "matias", "paula", "rocio", "micaela"], "2026-10-05")),
        Rutina(id: "r3", nombre: "Nico · fuerza", plan: "Particular · 3 días", dias: [
            dia("A", [x("sentadilla-barra", 5, 5, 70, 150), x("press-banca", 5, 5, 55, 150), x("remo-barra", 4, 8, 45, 90)]),
            dia("B", [x("peso-muerto-rumano", 4, 8, 50, 120, n: "Espalda neutra, la barra pegada a las piernas."), x("press-militar", 4, 6, 30, 120), x("dominadas", 4, 6, 0, 120)]),
            dia("C", [x("bulgara", 3, 8, 14, 90), x("hip-thrust", 4, 10, 70, 90), x("face-pull", 3, 15, 15), x("rueda-abdominal", 3, 10)]),
        ], objetivo: "Fuerza", nivel: "Avanzado", notas: "Subí 2,5 kg cuando completes todas las series con buena técnica.",
           asignaciones: asignar(["nico"], "2026-08-04")),
        Rutina(id: "r4", nombre: "Funcional sábado", plan: "Circuito · 1 día", dias: [
            dia("A", [x("burpee", 4, 10, 0, 45), x("swing-pesa-rusa", 4, 15, 12, 45), x("escaladores", 4, 30, 0, 45, t: true),
                      x("thruster", 4, 10, 10, 45), x("remo-invertido", 4, 10, 0, 45), x("plancha-lateral", 3, 30, 0, 30, t: true)]),
        ], objetivo: "Resistencia", nivel: "Todos los niveles", notas: "Circuito: pasá de un ejercicio al otro y descansá al final de la vuelta.",
           asignaciones: asignar(["joaquin", "gonzalo", "diego", "santiago", "bruno", "facundo", "milagros", "daniela"], "2026-09-12")),
        Rutina(id: "r5", nombre: "Verano 2025", plan: "Circuito · 2 días", dias: [
            dia("A", [x("salto-cajon", 4, 10), x("wall-ball", 4, 15, 6), x("sogas-batalla", 4, 30, 0, 45, t: true)]),
            dia("B", [x("soga", 5, 60, 0, 30, t: true), x("caminata-granjero", 4, 40, 20, 60, t: true), x("abdominal", 3, 20)]),
        ], objetivo: "Resistencia", nivel: "Intermedio", archivada: true),
    ]

    static let plantillas: [Rutina] = [
        Rutina(id: "p-fuerza", nombre: "Fuerza general", plan: "Plantilla · 3 días", dias: [
            dia("A", [x("sentadilla-barra", 4, 6, 60, 120), x("press-banca", 4, 6, 40, 120), x("remo-barra", 4, 8, 40, 90), x("plancha", 3, 30, t: true)]),
            dia("B", [x("peso-muerto", 4, 5, 70, 150), x("press-militar", 4, 6, 25, 120), x("dominadas", 4, 6, 0, 120), x("giro-ruso", 3, 16)]),
            dia("C", [x("bulgara", 3, 8, 12, 90), x("press-inclinado", 3, 10, 14, 90), x("remo-mancuerna", 3, 10, 16, 90),
                      x("hip-thrust", 3, 10, 50, 90), x("bicho-muerto", 3, 10)]),
        ], objetivo: "Fuerza", nivel: "Intermedio", notas: "Calentá 10 minutos y hacé dos series livianas antes de la primera pesada.", plantilla: true),
        Rutina(id: "p-principiante", nombre: "Principiante cuerpo completo", plan: "Plantilla · 2 días", dias: [
            dia("A", [x("sentadilla-goblet", 3, 12, 8), x("flexiones", 3, 8, n: "Con las rodillas apoyadas si hace falta."), x("remo-polea", 3, 12, 20),
                      x("puente-gluteos", 3, 15, 0, 45), x("plancha", 3, 20, 0, 45, t: true)]),
            dia("B", [x("step-up", 3, 10), x("press-hombros", 3, 12, 6), x("jalon-pecho", 3, 12, 25), x("bicho-muerto", 3, 10, 0, 45), x("gemelos-de-pie", 3, 15, 0, 45)]),
        ], objetivo: "Salud", nivel: "Principiante", notas: "Que la técnica salga limpia antes de subir peso.", plantilla: true),
        Rutina(id: "p-gluteos", nombre: "Glúteos y piernas", plan: "Plantilla · 2 días", dias: [
            dia("A", [x("hip-thrust", 4, 10, 60, 90), x("sentadilla-sumo", 4, 12, 20, 90), x("peso-muerto-rumano", 4, 10, 40, 90),
                      x("estocada", 3, 12, 10), x("gemelos-de-pie", 4, 15, 0, 45)]),
            dia("B", [x("bulgara", 3, 10, 10, 90), x("prensa", 4, 12, 100, 90), x("curl-femoral", 3, 12, 25),
                      x("extension-cuadriceps", 3, 15, 25), x("peso-muerto-una-pierna", 3, 10, 10)]),
        ], objetivo: "Glúteos", nivel: "Intermedio", plantilla: true),
        Rutina(id: "p-superior", nombre: "Tren superior", plan: "Plantilla · 2 días", dias: [
            dia("A", [x("press-banca", 4, 8, 40, 90), x("aperturas", 3, 12, 10), x("press-militar", 4, 8, 25, 90),
                      x("vuelos-laterales", 3, 15, 6, 45), x("triceps-polea", 3, 12, 20, 45), x("press-frances", 3, 10, 15)]),
            dia("B", [x("dominadas", 4, 6, 0, 120), x("remo-barra", 4, 8, 40, 90), x("jalon-pecho", 3, 10, 40),
                      x("face-pull", 3, 15, 15, 45), x("curl-barra", 3, 10, 20, 45), x("curl-martillo", 3, 12, 10, 45)]),
        ], objetivo: "Hipertrofia", nivel: "Intermedio", plantilla: true),
        Rutina(id: "p-plaza", nombre: "Funcional en plaza", plan: "Plantilla · 2 días · sin máquinas", dias: [
            dia("A", [x("burpee", 4, 10, 0, 45), x("escaladores", 4, 30, 0, 45, t: true), x("flexiones", 4, 12, 0, 45),
                      x("estocada", 4, 12, 0, 45), x("salto-cajon", 4, 10, 0, 45, n: "En el banco de la plaza, con cuidado al bajar.")]),
            dia("B", [x("remo-invertido", 4, 10, 0, 60, n: "En la barra baja de la plaza."), x("sentadilla-sumo", 4, 15, 0, 45),
                      x("plancha", 4, 40, 0, 30, t: true), x("soga", 4, 60, 0, 30, t: true), x("bicho-muerto", 3, 12, 0, 30)]),
        ], objetivo: "Funcional", nivel: "Todos los niveles", notas: "Sin máquinas: banco, barra baja y el peso del cuerpo.", plantilla: true),
        Rutina(id: "p-pilates", nombre: "Pilates mat", plan: "Plantilla · 1 día", dias: [
            dia("A", [x("pilates-hundred", 1, 100, 0, 30), x("pilates-roll-up", 2, 6, 0, 30), x("pilates-circulo-pierna", 2, 8, 0, 30),
                      x("pilates-rodar-pelota", 2, 8, 0, 30), x("pilates-estiramiento-una-pierna", 2, 10, 0, 30),
                      x("pilates-estiramiento-dos-piernas", 2, 8, 0, 30), x("pilates-sierra", 2, 6, 0, 30), x("pilates-cisne", 2, 6, 0, 30),
                      x("pilates-natacion", 2, 30, 0, 30, t: true), x("pilates-teaser", 2, 5, 0, 30), x("pilates-foca", 2, 8, 0, 30)]),
        ], objetivo: "Movilidad", nivel: "Todos los niveles", notas: "Respiración lenta y controlada en cada movimiento.", plantilla: true),
        Rutina(id: "p-movilidad", nombre: "Movilidad y core", plan: "Plantilla · 1 día", dias: [
            dia("A", [x("bicho-muerto", 3, 10, 0, 30), x("plancha-lateral", 3, 30, 0, 30, t: true), x("pilates-cisne", 2, 8, 0, 30),
                      x("hiperextensiones", 3, 12, 0, 45), x("buenos-dias", 3, 12, 10, 45), x("plancha", 3, 40, 0, 30, t: true),
                      x("rueda-abdominal", 3, 8, 0, 45), x("elevacion-piernas-colgado", 3, 10, 0, 45)]),
        ], objetivo: "Core", nivel: "Todos los niveles", plantilla: true),
        Rutina(id: "p-hipertrofia", nombre: "Hipertrofia 4 días", plan: "Plantilla · 4 días", dias: [
            dia("A", [x("press-banca", 4, 8, 45, 90), x("press-inclinado", 3, 10, 18, 90), x("cruce-poleas", 3, 12, 10, 60),
                      x("fondos", 3, 10, 0, 90), x("triceps-polea", 3, 12, 25, 60)]),
            dia("B", [x("dominadas", 4, 8, 0, 120), x("remo-t", 4, 10, 30, 90), x("pullover", 3, 12, 14, 60),
                      x("curl-barra", 3, 10, 25, 60), x("curl-concentrado", 3, 12, 10, 45)]),
            dia("C", [x("sentadilla-barra", 4, 8, 70, 150), x("prensa", 4, 12, 120, 90), x("curl-femoral", 3, 12, 30, 60),
                      x("extension-cuadriceps", 3, 15, 30, 60), x("gemelos-de-pie", 4, 15, 40, 45)]),
            dia("D", [x("press-militar", 4, 8, 30, 90), x("vuelos-laterales", 4, 15, 8, 45), x("pajaro", 3, 15, 6, 45),
                      x("encogimientos", 3, 12, 40, 60), x("elevacion-piernas-colgado", 3, 12, 0, 45)]),
        ], objetivo: "Hipertrofia", nivel: "Avanzado", notas: "Cerca del fallo en la última serie de cada ejercicio.", plantilla: true),
    ]

    /// Horario semanal fijo de Lucía: de acá salen las clases de cualquier fecha.
    static let horarioSemanal: [ClaseFija] = [
        ClaseFija(id: "fm", nombre: "Funcional mañana", dias: [1, 2, 3, 4, 5], hora: "8:00", lugar: "Plaza Mitre", cupo: 10,
                  inscriptos: ["carla", "camila", "agustin", "martina", "joaquin", "sofia", "tomas", "valentina", "lucila", "gonzalo"]),
        ClaseFija(id: "np", nombre: "Nico Paredes", dias: [2, 4], hora: "10:30", lugar: "Particular", cupo: 1, inscriptos: ["nico"], particular: "nico"),
        ClaseFija(id: "ft", nombre: "Funcional tarde", dias: [2, 4], hora: "18:00", lugar: "Plaza España", cupo: 12,
                  inscriptos: ["ezequiel", "lautaro", "julieta", "franco", "antonella", "agostina", "emiliano", "florencia", "matias", "paula", "rocio", "micaela"]),
        ClaseFija(id: "fl", nombre: "Funcional tarde", dias: [1, 3, 5], hora: "18:00", lugar: "Plaza España", cupo: 12,
                  inscriptos: ["matias", "paula", "rocio", "micaela", "facundo", "daniela", "florencia", "milagros", "bruno"]),
        ClaseFija(id: "fs", nombre: "Funcional sábado", dias: [6], hora: "9:30", lugar: "Costanera", cupo: 15,
                  inscriptos: ["joaquin", "gonzalo", "diego", "santiago", "bruno", "facundo", "milagros", "daniela", "ramiro", "sofia"]),
    ]
}
