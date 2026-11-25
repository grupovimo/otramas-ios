import Foundation

/// Los datos exactos del diseño aprobado (app-v4.html): Lucía, Carla, Nico, $1.215.000, 24 de 30…
extension DatosDeMuestra {
    static let lucia = Profe(nombre: "Lucía", foto: "foto-estudio-ella", alias: "lucia.entrena.mdp")

    /// Los 30 alumnos de Lucía: 24 al día, 2 con comprobante por confirmar y 4 que deben.
    static let alumnos: [Alumno] = {
        let manana = "lun, mié y vie 8:00", tarde = "mar y jue 18:00", tardeLmv = "lun, mié y vie 18:00"
        func a(_ id: String, _ nombre: String, _ tono: TonoAvatar, _ plan: String, _ horario: String,
               _ cuota: EstadoCuota = .alDia, asis: Int = 7, mes: Int = 9, racha: Int = 4, ultima: Int = 1) -> Alumno {
            Alumno(id: id, nombre: nombre, tono: tono, plan: plan, horario: horario, cuota: cuota, asistencias: asis,
                   clasesDelMes: mes, racha: racha, progreso: nil, pasos: nil, ultimaVez: ultima)
        }
        var carla = a("carla", "Carla Benítez", .yemaFuerte, "Mensual", manana, asis: 8, mes: 9, racha: 11)
        carla.progreso = Progreso(ejercicio: "Sentadilla goblet", actual: 24, valores: [8, 10, 10, 12, 14, 16, 18, 20, 24],
                                  meses: ["MAR", "ABR", "MAY", "JUN", "JUL", "AGO", "SEP", "OCT", "NOV"], desde: "marzo")
        carla.pasos = [6200, 9100, 7400, 10200, 8800, 5400, 8200]
        var nico = a("nico", "Nico Paredes", .yema, "Pack de 8 clases", "Particular · jue 10:30", asis: 7, mes: 8, racha: 7)
        nico.progreso = Progreso(ejercicio: "Peso muerto rumano", actual: 50, valores: [30, 35, 42.5, 50],
                                 meses: ["AGO", "SEP", "OCT", "NOV"], desde: "agosto")
        nico.pasos = [7800, 8432, 9900, 6100, 10400, 7300, 8432]
        return [
            carla, nico,
            a("camila", "Camila Herrera", .berenjena, "Mensual", manana, .porConfirmar(Comprobante(id: "cp1", monto: 45000, cuando: "hoy 7:12"))),
            a("agustin", "Agustín López", .arena, "Mensual", manana, .porConfirmar(Comprobante(id: "cp2", monto: 45000, cuando: "ayer 21:40"))),
            a("martina", "Martina Sosa", .berenjena, "Mensual", manana, .debe(Deuda(monto: 45000, dias: 14)), asis: 2, racha: 0, ultima: 9),
            a("florencia", "Florencia Díaz", .yema, "Mensual · 5 días", "lun a vie 18:00", .debe(Deuda(monto: 72000, dias: 9)), asis: 5, mes: 15, racha: 1, ultima: 8),
            a("joaquin", "Joaquín Ruiz", .arena, "Mensual", manana, .debe(Deuda(monto: 45000, dias: 4)), asis: 6),
            a("ezequiel", "Ezequiel Romero", .berenjena, "Mensual", tarde, .debe(Deuda(monto: 45000, dias: 4)), asis: 4, mes: 6),
            a("sofia", "Sofía Méndez", .yema, "Mensual", manana, asis: 9, racha: 9),
            a("tomas", "Tomás Acosta", .arena, "Mensual", manana, asis: 6),
            a("valentina", "Valentina Ríos", .berenjena, "Mensual", manana, asis: 8, racha: 6),
            a("lautaro", "Lautaro Gómez", .yema, "Mensual", tarde, asis: 5, mes: 6),
            a("julieta", "Julieta Castro", .arena, "Mensual", tarde, asis: 6, mes: 6, racha: 8),
            a("matias", "Matías Fernández", .berenjena, "Mensual", tardeLmv),
            a("paula", "Paula Giménez", .yema, "Mensual", tardeLmv, asis: 9, racha: 12),
            a("diego", "Diego Molina", .arena, "Pack de 8 clases", "a elección", asis: 5, mes: 8),
            a("lucila", "Lucila Torres", .berenjena, "Mensual", manana, asis: 8),
            a("franco", "Franco Medina", .yema, "Mensual", tarde, asis: 5, mes: 6),
            a("rocio", "Rocío Suárez", .arena, "Mensual", tardeLmv, asis: 8, racha: 5),
            a("gonzalo", "Gonzalo Vera", .berenjena, "Mensual", manana, asis: 7),
            a("antonella", "Antonella Rojas", .yema, "Mensual", tarde, asis: 6, mes: 6, racha: 3),
            a("santiago", "Santiago Ortiz", .arena, "Pack de 8 clases", "a elección", asis: 4, mes: 8),
            a("micaela", "Micaela Luna", .berenjena, "Mensual", tardeLmv, asis: 9, racha: 10),
            a("bruno", "Bruno Aguirre", .yema, "Mensual", manana, asis: 6),
            a("agostina", "Agostina Peralta", .arena, "Mensual", tarde, asis: 6, mes: 6),
            a("facundo", "Facundo Silva", .berenjena, "Mensual", tardeLmv, asis: 7),
            a("milagros", "Milagros Cabrera", .yema, "Mensual", manana, asis: 8, racha: 2),
            a("emiliano", "Emiliano Ponce", .arena, "Mensual", tarde, asis: 5, mes: 6),
            a("daniela", "Daniela Correa", .berenjena, "Mensual", tardeLmv, asis: 8, racha: 7),
            a("ramiro", "Ramiro Godoy", .yema, "Mensual", manana, asis: 7),
        ]
    }()

    static let rutina = Rutina(
        id: "r1", nombre: "Piernas y zona media", plan: "Fuerza general · 3 días",
        dias: [
            DiaRutina(id: "a", nombre: "Día A", ejercicios: [
                EjercicioDeRutina(id: "e1", ejercicioId: "sentadilla-goblet", nombre: "Sentadilla goblet", foto: "foto-domicilio", focoX: 0.62, focoY: 0.62, series: 4, reps: 10, kilos: 20, pausa: 90),
                EjercicioDeRutina(id: "e2", ejercicioId: "peso-muerto-rumano", nombre: "Peso muerto rumano", foto: "foto-tecnica", focoX: 0.66, focoY: 0.70, series: 4, reps: 8, kilos: 50, pausa: 90),
                EjercicioDeRutina(id: "e3", ejercicioId: "estocada", nombre: "Estocadas", foto: "foto-domicilio", focoX: 0.3, focoY: 0.6, series: 3, reps: 12, kilos: 12, pausa: 60),
                EjercicioDeRutina(id: "e4", ejercicioId: "puente-gluteos", nombre: "Puente de glúteos", foto: "foto-tecnica", focoX: 0.4, focoY: 0.5, series: 3, reps: 12, kilos: 30, pausa: 60),
                EjercicioDeRutina(id: "e5", ejercicioId: "plancha", nombre: "Plancha frontal", foto: "foto-detalle", focoX: 0.5, focoY: 0.5, series: 3, reps: 30, kilos: 0, pausa: 60),
            ]),
            DiaRutina(id: "b", nombre: "Día B", ejercicios: [
                EjercicioDeRutina(id: "e6", ejercicioId: "bulgara", nombre: "Sentadilla búlgara", foto: "foto-domicilio", focoX: 0.5, focoY: 0.6, series: 3, reps: 10, kilos: 10, pausa: 90),
                EjercicioDeRutina(id: "e7", ejercicioId: "hip-thrust", nombre: "Hip thrust", foto: "foto-tecnica", focoX: 0.6, focoY: 0.6, series: 4, reps: 10, kilos: 40, pausa: 90),
                EjercicioDeRutina(id: "e8", ejercicioId: "bicho-muerto", nombre: "Bicho muerto", foto: "foto-detalle", focoX: 0.5, focoY: 0.5, series: 3, reps: 10, kilos: 0, pausa: 60),
            ]),
            DiaRutina(id: "c", nombre: "Día C", ejercicios: [
                EjercicioDeRutina(id: "e9", ejercicioId: "swing-pesa-rusa", nombre: "Swing con pesa rusa", foto: "foto-tecnica", focoX: 0.66, focoY: 0.7, series: 4, reps: 8, kilos: 24, pausa: 120),
                EjercicioDeRutina(id: "e10", ejercicioId: "step-up", nombre: "Subida al cajón", foto: "foto-domicilio", focoX: 0.4, focoY: 0.6, series: 3, reps: 10, kilos: 8, pausa: 60),
            ]),
        ])

    static let profe: PanelProfe = {
        let manana = ["carla", "camila", "agustin", "martina", "joaquin", "sofia", "tomas", "valentina", "lucila", "gonzalo"]
        let tarde = ["ezequiel", "lautaro", "julieta", "franco", "antonella", "agostina", "emiliano", "florencia", "matias", "paula", "rocio", "micaela"]
        return PanelProfe(
            profe: lucia,
            fecha: "Martes 24 de noviembre",
            hora: "7:35",
            alumnos: alumnos,
            resumen: ResumenMes(mes: "noviembre", mesAnterior: "octubre", cobrado: 1_215_000, variacion: 4,
                                ingresos: [870, 920, 1010, 1080, 1170, 1215], meses: ["JUN", "JUL", "AGO", "SEP", "OCT", "NOV"],
                                alumnosActivos: 30, asistencia: 86, nuevos: 3,
                                medios: [MedioCobrado(medio: .transferencia, cuotas: 15), MedioCobrado(medio: .efectivo, cuotas: 5),
                                         MedioCobrado(medio: .mercadoPago, cuotas: 4)],
                                noVienen: 2),
            semana: [
                DiaSemana(corto: "Lun", numero: 23, feriado: true, conClases: false),
                DiaSemana(corto: "Mar", numero: 24),
                DiaSemana(corto: "Mié", numero: 25),
                DiaSemana(corto: "Jue", numero: 26),
                DiaSemana(corto: "Vie", numero: 27),
                DiaSemana(corto: "Sáb", numero: 28),
                DiaSemana(corto: "Dom", numero: 29, conClases: false),
            ],
            hoy: 24,
            clases: [
                Clase(id: "c1", hora: "8:00", nombre: "Funcional mañana", lugar: "Plaza Mitre", estado: .termino, cupo: 10,
                      inscriptos: manana, presentes: Set(["carla", "camila", "agustin", "joaquin", "sofia", "valentina", "lucila"])),
                Clase(id: "c2", hora: "10:30", nombre: "Nico Paredes", lugar: "Particular", estado: .termino, cupo: 1,
                      inscriptos: ["nico"], presentes: ["nico"], particular: "nico"),
                Clase(id: "c3", hora: "18:00", nombre: "Funcional tarde", lugar: "Plaza España", estado: .falta("En 2 h 40"), cupo: 12,
                      inscriptos: tarde, presentes: Set(tarde.prefix(9))),
            ],
            proxima: "c1",
            proximaEn: "en 25 min",
            rutina: rutina)
    }()

    static let alumno = PanelAlumno(
        nombre: "Nico",
        profe: "Lucía",
        fotoProfe: "foto-estudio-ella",
        sesion: SesionHoy(
            ejercicios: [
                EjercicioSesion(id: "s1", ejercicioId: "sentadilla-goblet", nombre: "Sentadilla goblet", foto: "foto-domicilio", series: 4, kilos: 20, reps: 10, anterior: 20, descanso: 90),
                EjercicioSesion(id: "s2", ejercicioId: "peso-muerto-rumano", nombre: "Peso muerto rumano", foto: "foto-detalle", series: 4, kilos: 50, reps: 8, anterior: 47.5, descanso: 120),
                EjercicioSesion(id: "s3", ejercicioId: "estocada", nombre: "Estocadas", foto: "foto-domicilio", series: 3, kilos: 12, reps: 12, anterior: 10, descanso: 60),
                EjercicioSesion(id: "s4", ejercicioId: "puente-gluteos", nombre: "Puente de glúteos", foto: "foto-tecnica", series: 3, kilos: 30, reps: 12, anterior: 30, descanso: 60),
                EjercicioSesion(id: "s5", ejercicioId: "plancha", nombre: "Plancha frontal", foto: "foto-detalle", series: 3, kilos: 0, reps: 30, anterior: 0, descanso: 60),
                EjercicioSesion(id: "s6", ejercicioId: "bicho-muerto", nombre: "Bicho muerto", foto: "foto-tecnica", series: 3, kilos: 0, reps: 10, anterior: 0, descanso: 60),
            ],
            actual: 1, hechas: 2, descansoRestante: 72),
        logros: Logros(
            rachaSemanas: 7, semanaHechas: 2, semanaMeta: 3, pasosHoy: 8432, pasosMeta: 10000,
            record: Record(kilos: 50, ejercicio: "Peso muerto rumano", cuando: "hoy", valores: [30, 35, 42.5, 50], meses: ["AGO", "SEP", "OCT", "NOV"]),
            medallas: [
                Medalla(iconoNombre: "bandera", titulo: "Primera clase", ganada: true),
                Medalla(iconoNombre: "diez", titulo: "10 clases", ganada: true),
                Medalla(iconoNombre: "fuego", titulo: "4 semanas", ganada: true, deRacha: true),
                Medalla(iconoNombre: "sol", titulo: "Madrugador", ganada: true),
                Medalla(iconoNombre: "trofeo", titulo: "Récord", ganada: true),
                Medalla(iconoNombre: "estrella", titulo: "25 clases", ganada: false),
                Medalla(iconoNombre: "rayo", titulo: "12 semanas", ganada: false),
                Medalla(iconoNombre: "cal", titulo: "3 meses", ganada: false),
            ]),
        plan: PlanAlumno(
            nombre: "Pack de 8 clases", clasesTotal: 8, clasesUsadas: 7, mes: "Noviembre", vence: "Vence el 30",
            proxima: ProximaClase(diaCorto: "Jue", dia: 26, hora: "10:30", lugar: "Plaza Mitre"),
            avisoFalta: false, paraRecuperar: 1, recuperarHasta: "6/12", proximoMes: "diciembre", proximoMonto: 72000,
            alias: "lucia.entrena.mdp"))
}
