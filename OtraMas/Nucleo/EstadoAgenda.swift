import SwiftUI

/// Fechas como «2026-11-24» (sin zona horaria: son días del calendario).
enum Fecha {
    static let calendario: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Argentina/Buenos_Aires")!
        c.locale = Locale(identifier: "es_AR")
        c.firstWeekday = 2
        return c
    }()

    static func fecha(_ iso: String) -> Date {
        let p = iso.split(separator: "-").compactMap { Int($0) }
        return calendario.date(from: DateComponents(year: p[0], month: p[1], day: p[2], hour: 12)) ?? Date()
    }

    static func iso(_ d: Date) -> String {
        let c = calendario.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 2026, c.month ?? 1, c.day ?? 1)
    }

    static func sumar(_ dias: Int, a iso: String) -> String {
        Self.iso(calendario.date(byAdding: .day, value: dias, to: fecha(iso)) ?? fecha(iso))
    }

    /// 1 = lunes … 7 = domingo.
    static func diaSemana(_ iso: String) -> Int {
        let w = calendario.component(.weekday, from: fecha(iso)) // 1 = domingo
        return w == 1 ? 7 : w - 1
    }

    static func numero(_ iso: String) -> Int { calendario.component(.day, from: fecha(iso)) }

    static let cortos = ["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"]
    static let largos = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
    static let meses = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre"]

    static func mes(_ iso: String) -> String { meses[calendario.component(.month, from: fecha(iso)) - 1] }

    /// «Jueves 26 de noviembre».
    static func largo(_ iso: String) -> String { "\(largos[diaSemana(iso) - 1]) \(numero(iso)) de \(mes(iso))" }

    /// «2/11».
    static func corta(_ iso: String) -> String {
        "\(numero(iso))/\(calendario.component(.month, from: fecha(iso)))"
    }

    /// El lunes de la semana de esa fecha.
    static func lunes(_ iso: String) -> String { sumar(-(diaSemana(iso) - 1), a: iso) }

    static func dias(entre a: String, y b: String) -> Int {
        calendario.dateComponents([.day], from: fecha(a), to: fecha(b)).day ?? 0
    }
}

private func minutos(_ hora: String) -> Int {
    let p = hora.split(separator: ":").compactMap { Int($0) }
    return (p.first ?? 0) * 60 + (p.count > 1 ? p[1] : 0)
}

extension Estado {
    var hoy: String { profe.hoyISO }

    func feriado(_ iso: String) -> String? { profe.feriados[iso] }

    /// Las clases de cualquier fecha: hoy, lo que está pasando; los días pasados, la asistencia; los futuros, el
    /// horario fijo con los cambios puntuales (suspensiones, recuperaciones, faltas avisadas).
    func clases(en iso: String) -> [Clase] {
        var out: [Clase]
        if iso == hoy {
            out = profe.clases
        } else if feriado(iso) != nil {
            out = []
        } else {
            let d = Fecha.diaSemana(iso)
            out = profe.horario.filter { $0.dias.contains(d) }.map { generar($0, iso) }
        }
        out += profe.clasesUnicas.filter { $0.fecha == iso }
        return out.sorted { minutos($0.hora) < minutos($1.hora) }
    }

    /// Una clase por id: las de hoy, las únicas o «<fijaId>@<fecha>».
    func clase(_ id: String) -> Clase? {
        if let c = profe.clases.first(where: { $0.id == id }) { return c }
        if let c = profe.clasesUnicas.first(where: { $0.id == id }) { return c }
        let p = id.split(separator: "@").map(String.init)
        guard p.count == 2, let f = profe.horario.first(where: { $0.id == p[0] }) else { return nil }
        return generar(f, p[1])
    }

    private func generar(_ f: ClaseFija, _ iso: String) -> Clase {
        let id = "\(f.id)@\(iso)"
        let aj = profe.ajustes[id] ?? AjusteClase()
        let pasada = iso < hoy
        var estado: EstadoClase
        var presentes: Set<String>
        if let m = aj.suspendida {
            estado = .suspendida(m)
            presentes = Set(f.inscriptos)
        } else if pasada {
            estado = .termino
            // Asistencia que pasó: la tomada o una de muestra estable (faltan uno o dos).
            presentes = aj.presentes ?? Set(f.inscriptos.enumerated().filter { i, _ in
                f.inscriptos.count < 3 || (i + Fecha.numero(iso)) % 5 != 0
            }.map(\.element))
        } else {
            let n = Fecha.dias(entre: hoy, y: iso)
            estado = .falta(n == 1 ? "Mañana" : "En \(n) días")
            presentes = Set(f.inscriptos).subtracting(aj.faltan).union(aj.recuperan)
        }
        return Clase(id: id, fijaId: f.id, fecha: iso, recuperan: aj.recuperan, hora: f.hora, nombre: f.nombre, lugar: f.lugar,
                     estado: estado, cupo: f.cupo, inscriptos: f.inscriptos + aj.recuperan.filter { !f.inscriptos.contains($0) },
                     presentes: presentes, particular: f.particular)
    }

    /// Anotar a alguien (recuperación) en una fecha puntual.
    func anotar(_ alumnoId: String, en claseId: String) {
        Haptico.exito()
        withAnimation(.snappy) {
            if let i = profe.clases.firstIndex(where: { $0.id == claseId }) {
                profe.clases[i].recuperan.append(alumnoId)
                profe.clases[i].inscriptos.append(alumnoId)
                profe.clases[i].presentes.insert(alumnoId)
            } else if let i = profe.clasesUnicas.firstIndex(where: { $0.id == claseId }) {
                profe.clasesUnicas[i].inscriptos.append(alumnoId)
                profe.clasesUnicas[i].presentes.insert(alumnoId)
            } else {
                profe.ajustes[claseId, default: AjusteClase()].recuperan.append(alumnoId)
            }
        }
        let datos = self.datos
        Task { try? await datos.anotarEnClase(claseId: claseId, alumnoId: alumnoId) }
        avisar("Anotaste a \(alumno(alumnoId)?.primerNombre ?? "tu alumno"). Le llega el aviso.")
    }

    /// Una clase nueva: fija (todas las semanas) o única (sólo esa fecha).
    func crearClase(nombre: String, hora: String, lugar: String, cupo: Int, dias: [Int], unica fecha: String?) {
        Haptico.exito()
        let fija = ClaseFija(id: "cf-\(UUID().uuidString.prefix(6))", nombre: nombre, dias: dias, hora: hora, lugar: lugar, cupo: cupo, inscriptos: [])
        withAnimation(.snappy) {
            if let fecha {
                profe.clasesUnicas.append(Clase(id: "cu-\(UUID().uuidString.prefix(6))", fecha: fecha, hora: hora, nombre: nombre, lugar: lugar,
                                                estado: .falta("Única"), cupo: cupo, inscriptos: [], presentes: []))
            } else {
                profe.horario.append(fija)
            }
        }
        let datos = self.datos
        Task { try? await datos.crearClase(fija, unica: fecha) }
        avisar(fecha == nil ? "Clase sumada a tu horario." : "Clase sumada para el \(Fecha.corta(fecha!)).")
    }
}
