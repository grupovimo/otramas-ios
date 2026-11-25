import SwiftUI

extension Estado {
    // MARK: - Alumnos

    func detalle(_ id: String) -> DetalleAlumno? { profe.detalles[id] }
    func abono(_ id: String?) -> Abono? { profe.abonos.first { $0.id == id } }
    func estadoDe(_ id: String) -> EstadoAlumno { profe.detalles[id]?.estado ?? .activo }

    func guardar(detalle d: DetalleAlumno, de id: String, aviso: String? = nil) {
        withAnimation(.snappy) { profe.detalles[id] = d }
        let datos = self.datos
        Task { try? await datos.guardarDetalle(alumnoId: id, d) }
        if let aviso { Haptico.exito(); avisar(aviso) }
    }

    func cambiarEstado(_ id: String, a e: EstadoAlumno) {
        guard var d = detalle(id), let a = alumno(id) else { return }
        d.estado = e
        let texto: String
        switch e {
        case .activo: texto = "\(a.primerNombre) volvió a entrenar."
        case .pausado: texto = "\(a.primerNombre) quedó en pausa. No le llegan recordatorios."
        case .baja: texto = "\(a.primerNombre) dejó de entrenar. Queda su historia por si vuelve."
        }
        guardar(detalle: d, de: id, aviso: texto)
        withAnimation(.snappy) {
            profe.resumen.alumnosActivos = profe.detalles.values.filter { $0.estado == .activo }.count
        }
    }

    /// Alta completa: datos, objetivo, lesiones, abono, horario fijo y fecha de inicio.
    @discardableResult
    func darDeAlta(nombre: String, telefono: String, objetivo: Objetivo?, lesiones: [String], abonoId: String,
                   claseFijaId: String?, inicio: String) -> String? {
        let limpio = nombre.trimmingCharacters(in: .whitespaces)
        guard limpio.count >= 2 else { return nil }
        let ab = abono(abonoId)
        crearAlumno(nombre: limpio, plan: ab?.nombre ?? "Mensual")
        guard let id = profe.alumnos.first?.id else { return nil }
        let fija = profe.horario.first { $0.id == claseFijaId }
        if let i = profe.alumnos.firstIndex(where: { $0.id == id }), let fija {
            profe.alumnos[i].horario = "\(fija.dias.map { Fecha.cortos[$0 - 1].lowercased() }.joined(separator: ", ")) \(fija.hora)"
        }
        if let k = profe.horario.firstIndex(where: { $0.id == claseFijaId }) { profe.horario[k].inscriptos.append(id) }
        profe.detalles[id] = DetalleAlumno(telefono: telefono, objetivo: objetivo, lesiones: lesiones, abonoId: abonoId,
                                           claseFijaId: claseFijaId, inicio: inicio)
        empezarPruebaSiCorresponde()
        return id
    }

    func actualizar(alumno id: String, nombre: String, telefono: String, objetivo: Objetivo?, lesiones: [String], abonoId: String, claseFijaId: String?) {
        guard var d = detalle(id), let i = profe.alumnos.firstIndex(where: { $0.id == id }) else { return }
        profe.alumnos[i].nombre = nombre
        profe.alumnos[i].plan = abono(abonoId)?.nombre ?? profe.alumnos[i].plan
        if d.claseFijaId != claseFijaId {
            for k in profe.horario.indices { profe.horario[k].inscriptos.removeAll { $0 == id } }
            if let k = profe.horario.firstIndex(where: { $0.id == claseFijaId }) {
                profe.horario[k].inscriptos.append(id)
                let f = profe.horario[k]
                profe.alumnos[i].horario = "\(f.dias.map { Fecha.cortos[$0 - 1].lowercased() }.joined(separator: ", ")) \(f.hora)"
            }
        }
        d.telefono = telefono; d.objetivo = objetivo; d.lesiones = lesiones; d.abonoId = abonoId; d.claseFijaId = claseFijaId
        guardar(detalle: d, de: id, aviso: "Datos de \(profe.alumnos[i].primerNombre) guardados.")
    }

    func sumar(medicion m: Medicion, a id: String) {
        guard var d = detalle(id) else { return }
        d.mediciones.append(m)
        guardar(detalle: d, de: id, aviso: "Medición guardada.")
    }

    func sumar(evaluacion e: Evaluacion, a id: String) {
        guard var d = detalle(id) else { return }
        d.evaluaciones.append(e)
        guardar(detalle: d, de: id, aviso: "\(e.nombre): \(Formato.decimal(e.valor)) \(e.unidad).")
    }

    func sumar(nota texto: String, a id: String) {
        guard var d = detalle(id), !texto.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        d.notas.insert(Nota(fecha: hoy, texto: texto), at: 0)
        guardar(detalle: d, de: id, aviso: "Nota guardada.")
    }

    func sumar(foto: Data, a id: String) {
        guard var d = detalle(id) else { return }
        d.fotos.append(FotoProgreso(fecha: hoy, datos: foto))
        guardar(detalle: d, de: id, aviso: "Foto guardada. Sólo la ven vos y tu alumno.")
    }

    /// Asistencia real de las últimas semanas: las clases fijas en las que está y si vino.
    func asistencia(de id: String, semanas: Int = 8) -> [(fecha: String, clase: String, vino: Bool)] {
        var out: [(String, String, Bool)] = []
        var f = Fecha.sumar(-semanas * 7, a: hoy)
        while f <= hoy {
            for c in clases(en: f) where c.inscriptos.contains(id) && c.estado == .termino {
                out.append((f, c.nombre, c.presentes.contains(id)))
            }
            f = Fecha.sumar(1, a: f)
        }
        return out.reversed()
    }

    /// Alumnos que faltan seguido: hace más de 7 días que no vienen o vinieron a menos de la mitad del mes.
    /// (Cuenta liviana: se usa en Inicio y Tu mes.)
    var enRiesgo: [(alumno: Alumno, faltas: Int)] {
        profe.alumnos.filter { estadoDe($0.id) == .activo }.compactMap { a in
            let faltas = max(a.clasesDelMes - a.asistencias, 0)
            return (a.ultimaVez > 7 || (a.clasesDelMes > 0 && a.asistencias * 2 < a.clasesDelMes)) ? (a, faltas) : nil
        }
        .sorted { $0.faltas > $1.faltas }
    }

    // MARK: - Abonos

    func alumnos(con abonoId: String) -> [Alumno] { profe.alumnos.filter { detalle($0.id)?.abonoId == abonoId } }

    func guardar(abono a: Abono) {
        withAnimation(.snappy) {
            if let i = profe.abonos.firstIndex(where: { $0.id == a.id }) { profe.abonos[i] = a } else { profe.abonos.append(a) }
        }
        let datos = self.datos, l = profe.abonos
        Task { try? await datos.guardarAbonos(l) }
        Haptico.exito()
        avisar("«\(a.nombre)» guardado.")
    }

    /// Precio redondeado a $500 después de aumentar un porcentaje.
    func conAumento(_ precio: Int, _ porcentaje: Double) -> Int {
        Int((Double(precio) * (1 + porcentaje / 100) / 500).rounded()) * 500
    }

    func aumentar(_ porcentaje: Double, abonos ids: Set<String>, avisar avisarAlumnos: Bool) {
        withAnimation(.snappy) {
            for i in profe.abonos.indices where ids.contains(profe.abonos[i].id) {
                profe.abonos[i].precio = conAumento(profe.abonos[i].precio, porcentaje)
            }
        }
        let datos = self.datos, l = profe.abonos
        Task { try? await datos.guardarAbonos(l) }
        Haptico.exito()
        let n = profe.alumnos.filter { ids.contains(detalle($0.id)?.abonoId ?? "") }.count
        avisar(avisarAlumnos ? "Precios nuevos. Les avisamos a los \(n) con un mes de anticipación." : "Precios actualizados.")
    }

    // MARK: - Cobros

    var todosLosPagos: [Pago] { profe.detalles.values.flatMap(\.pagos).sorted { $0.fecha > $1.fecha } }

    func pagos(delMes mes: String) -> [Pago] { todosLosPagos.filter { $0.mes == mes } }

    var mesesConPagos: [String] { Array(Set(todosLosPagos.map(\.mes))).sorted(by: >) }

    func linkDePago(_ alumnoId: String) -> URL {
        URL(string: "https://mpago.la/otramas-\(profe.profe.alias.prefix(5))-\(alumnoId)")!
    }

    func montoCuota(_ alumnoId: String) -> Int { abono(detalle(alumnoId)?.abonoId)?.precio ?? 45000 }

    func guardar(cobros c: ConfigCobros) {
        profe.cobros = c
        let datos = self.datos
        Task { try? await datos.guardarCobros(c) }
    }

    /// CSV de cobros (se abre en Excel, Numbers o Google Sheets).
    func csvCobros(mes: String? = nil) -> URL {
        let filas = (mes.map { pagos(delMes: $0) } ?? todosLosPagos).map { p -> String in
            let n = alumno(p.alumnoId)?.nombre ?? p.alumnoId
            return [p.fecha, p.mes, "\"\(n)\"", String(p.monto), p.medio.rawValue].joined(separator: ";")
        }
        let texto = "\u{FEFF}Fecha;Mes;Alumno;Monto;Medio\n" + filas.joined(separator: "\n") + "\n"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Cobros \(mes ?? "todos").csv")
        try? texto.data(using: .utf8)?.write(to: url)
        return url
    }

    /// Todo, para llevárselo: un JSON con alumnos, clases, rutinas, cobros y perfil.
    func exportarTodo() -> URL {
        struct Todo: Encodable { let profe: PanelProfe; let perfil: PerfilProfe }
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Otra Más · mis datos.json")
        try? e.encode(Todo(profe: profe, perfil: perfilProfe)).write(to: url)
        return url
    }

    // MARK: - Clases

    func guardar(claseFija c: ClaseFija) {
        withAnimation(.snappy) {
            if let i = profe.horario.firstIndex(where: { $0.id == c.id }) { profe.horario[i] = c } else { profe.horario.append(c) }
        }
        let datos = self.datos
        Task { try? await datos.guardarClaseFija(c) }
        Haptico.exito()
        avisar("Clase guardada.")
    }

    func borrar(claseFija id: String) {
        withAnimation(.snappy) { profe.horario.removeAll { $0.id == id } }
        let datos = self.datos
        Task { try? await datos.borrarClaseFija(id: id) }
        Haptico.exito()
        avisar("La clase salió de tu horario.")
    }

    /// Pasa al primero de la lista de espera a la clase.
    func pasarDeEspera(_ alumnoId: String, en claseId: String) {
        guard let i = profe.horario.firstIndex(where: { $0.id == claseId }) else { return }
        withAnimation(.snappy) {
            profe.horario[i].espera.removeAll { $0 == alumnoId }
            profe.horario[i].inscriptos.append(alumnoId)
        }
        Haptico.exito()
        avisar("\(alumno(alumnoId)?.primerNombre ?? "Tu alumno") ya tiene lugar. Le avisamos.")
    }

    // MARK: - Avisos

    func destinatarios(_ para: String) -> [String] {
        if para == "Todos" { return profe.alumnos.filter { estadoDe($0.id) == .activo }.map(\.id) }
        if para == "Los que deben" { return deben.map(\.alumno.id) }
        return profe.horario.filter { $0.nombre == para }.flatMap(\.inscriptos)
    }

    func enviar(aviso titulo: String, texto: String, para: String) {
        let n = Set(destinatarios(para)).count
        let a = AvisoProfe(fecha: hoy, titulo: titulo, texto: texto, para: para, cantidad: n)
        withAnimation(.snappy) { profe.avisos.insert(a, at: 0) }
        let datos = self.datos
        Task { try? await datos.enviarAviso(a) }
        Haptico.exito()
        avisar("Aviso enviado a \(n) por WhatsApp.")
    }

    // MARK: - Integraciones

    func conectar(_ id: String, _ on: Bool) {
        guard let i = profe.integraciones.firstIndex(where: { $0.id == id }) else { return }
        withAnimation(.snappy) { profe.integraciones[i].conectada = on }
        let datos = self.datos
        Task { try? await datos.conectar(integracion: id, on) }
        Haptico.exito()
        avisar(on ? "\(profe.integraciones[i].nombre) conectado." : "\(profe.integraciones[i].nombre) desconectado.")
    }

    // MARK: - Alumno (Nico)

    var idAlumnoPropio: String { "nico" }

    func pagarCuotaAlumno() {
        Haptico.exito()
        withAnimation(.snappy) { alumno.cuotaPagada = true; alumno.comprobanteEnRevision = false }
        if var d = detalle(idAlumnoPropio) {
            d.pagos.append(Pago(alumnoId: idAlumnoPropio, mes: "2026-12", monto: alumno.plan.proximoMonto, medio: .mercadoPago, fecha: hoy))
            profe.detalles[idAlumnoPropio] = d
        }
        let datos = self.datos
        Task { try? await datos.pagarCuota(medio: .mercadoPago) }
        avisar("¡Pago acreditado! Le avisamos a \(alumno.profe).")
    }

    func subirComprobanteAlumno(_ datosImg: Data) {
        Haptico.exito()
        withAnimation(.snappy) { alumno.comprobanteEnRevision = true }
        let datos = self.datos
        Task { try? await datos.subirComprobante(datosImg) }
        avisar("Comprobante enviado. \(alumno.profe) lo confirma en un rato.")
    }

    /// Las próximas clases del alumno (su horario fijo) en las próximas dos semanas.
    var proximasDelAlumno: [Clase] {
        (1...14).flatMap { k -> [Clase] in
            let f = Fecha.sumar(k, a: hoy)
            return clases(en: f).filter { $0.inscriptos.contains(idAlumnoPropio) }
        }
    }

    /// Clases para recuperar: grupales con lugar en los próximos 7 días.
    var paraRecuperar: [Clase] {
        (1...7).flatMap { k -> [Clase] in
            let f = Fecha.sumar(k, a: hoy)
            return clases(en: f).filter { $0.particular == nil && $0.vienen < $0.cupo && !$0.inscriptos.contains(idAlumnoPropio) }
        }
    }

    func avisarFalta(en claseId: String) {
        Haptico.exito()
        let fecha = clase(claseId)?.fecha ?? hoy
        withAnimation(.snappy) {
            alumno.faltas.append(claseId)
            alumno.plan.paraRecuperar += 1
            profe.ajustes[claseId, default: AjusteClase()].faltan.append(idAlumnoPropio)
        }
        avisar("Le avisamos a \(alumno.profe) que faltás el \(Fecha.corta(fecha)).")
    }

    func reservar(_ claseId: String) {
        guard alumno.plan.paraRecuperar > 0 else { avisar("No te quedan clases para recuperar."); return }
        withAnimation(.snappy) {
            alumno.reservas.append(claseId)
            alumno.plan.paraRecuperar -= 1
        }
        anotar(idAlumnoPropio, en: claseId)
        let datos = self.datos
        Task { try? await datos.reservarRecuperacion(claseId: claseId) }
    }

    var avisosDelAlumno: [AvisoProfe] {
        profe.avisos.filter { $0.para == "Todos" || destinatarios($0.para).contains(idAlumnoPropio) || $0.para == "Funcional tarde" }
    }
}
