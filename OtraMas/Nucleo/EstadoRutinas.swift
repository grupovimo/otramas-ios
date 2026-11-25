import SwiftUI

extension Estado {
    func rutina(_ id: String) -> Rutina? { profe.rutinas.first { $0.id == id } }

    var rutinasMias: [Rutina] { profe.rutinas.filter { !$0.plantilla && !$0.archivada } }
    var plantillas: [Rutina] { profe.rutinas.filter { $0.plantilla && !$0.archivada } }
    var rutinasArchivadas: [Rutina] { profe.rutinas.filter { $0.archivada } }

    /// La rutina vigente de un alumno (la asignada más reciente).
    func rutinaActual(de alumnoId: String) -> (rutina: Rutina, desde: String)? {
        profe.rutinas.filter { !$0.archivada }
            .compactMap { r in r.asignaciones.first { $0.alumnoId == alumnoId }.map { (r, $0.desde) } }
            .max { $0.1 < $1.1 }
    }

    var sinRutina: [Alumno] { profe.alumnos.filter { rutinaActual(de: $0.id) == nil } }

    /// Guarda una rutina nueva (va a «Mías») o los cambios de una existente.
    func guardar(rutina r: Rutina, avisando: Bool = true) {
        Haptico.exito()
        withAnimation(.snappy) {
            if let i = profe.rutinas.firstIndex(where: { $0.id == r.id }) { profe.rutinas[i] = r } else { profe.rutinas.insert(r, at: 0) }
        }
        let datos = self.datos
        Task { try? await datos.guardarRutina(r) }
        if avisando { avisar("Rutina guardada en Mías.") }
    }

    /// «… (copia)» en Mías. Devuelve el id nuevo.
    @discardableResult
    func duplicar(rutina id: String, nombre: String? = nil, avisando: Bool = true) -> String? {
        guard var r = rutina(id) else { return nil }
        r.id = "r-\(UUID().uuidString.prefix(8))"
        r.nombre = nombre ?? "\(r.nombre) (copia)"
        r.plantilla = false
        r.archivada = false
        r.asignaciones = []
        if r.plan.hasPrefix("Plantilla") { r.plan = r.plan.replacingOccurrences(of: "Plantilla", with: r.objetivo) }
        guardar(rutina: r, avisando: false)
        if avisando { avisar("Duplicada: «\(r.nombre)» está en Mías.") }
        return r.id
    }

    func archivar(rutina id: String, _ archivada: Bool = true) {
        guard let i = profe.rutinas.firstIndex(where: { $0.id == id }) else { return }
        Haptico.exito()
        withAnimation(.snappy) { profe.rutinas[i].archivada = archivada }
        let datos = self.datos
        Task { try? await datos.archivarRutina(id: id, archivada: archivada) }
        avisar(archivada ? "Rutina archivada." : "La rutina volvió a Mías.")
    }

    /// Asigna una rutina. Si es plantilla, primero la copia a Mías. Devuelve el id de la rutina asignada.
    @discardableResult
    func asignar(rutina id: String, a alumnoIds: [String], desde: String, reemplaza: Bool) -> String? {
        guard !alumnoIds.isEmpty, var destino = rutina(id) else { return nil }
        if destino.plantilla, let nueva = duplicar(rutina: id, nombre: destino.nombre, avisando: false), let r = rutina(nueva) {
            destino = r
        }
        let rid = destino.id
        withAnimation(.snappy) {
            if reemplaza {
                for i in profe.rutinas.indices where profe.rutinas[i].id != rid {
                    profe.rutinas[i].asignaciones.removeAll { alumnoIds.contains($0.alumnoId) }
                }
            }
            if let i = profe.rutinas.firstIndex(where: { $0.id == rid }) {
                profe.rutinas[i].asignaciones.removeAll { alumnoIds.contains($0.alumnoId) }
                profe.rutinas[i].asignaciones += alumnoIds.map { Asignacion(alumnoId: $0, desde: desde) }
            }
        }
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.asignarRutina(rutinaId: rid, alumnoIds: alumnoIds, desde: desde, reemplaza: reemplaza) }
        avisar(alumnoIds.count == 1 ? "Asignada a \(alumno(alumnoIds[0])?.primerNombre ?? "1 alumno")" : "Asignada a \(alumnoIds.count)")
        return rid
    }

    func enviar(rutina id: String, a alumnoIds: [String]) {
        guard !alumnoIds.isEmpty else { return }
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.enviarRutina(id: id, alumnoIds: alumnoIds) }
        avisar(alumnoIds.count == 1 ? "Le mandamos la rutina por WhatsApp." : "Les mandamos la rutina a los \(alumnoIds.count) por WhatsApp.")
    }

    /// Rutina vacía para empezar de cero.
    func rutinaNueva() -> Rutina {
        Rutina(id: "r-\(UUID().uuidString.prefix(8))", nombre: "Rutina nueva", plan: "Fuerza · 1 día",
               dias: [DiaRutina(id: "A", nombre: "Día A", ejercicios: [])])
    }
}
