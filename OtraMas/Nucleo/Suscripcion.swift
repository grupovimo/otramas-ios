import SwiftUI

/// Los planes de Otra Más para el profe (propuesta, sección 5). El alumno nunca paga.
enum PlanOM: String, Codable, CaseIterable, Hashable {
    case gratis, personal, pro

    var nombre: String {
        switch self { case .gratis: return "Gratis"; case .personal: return "Personal"; case .pro: return "Pro" }
    }
    /// Por mes, con IVA.
    var precioMes: Int {
        switch self { case .gratis: return 0; case .personal: return 9900; case .pro: return 19900 }
    }
    /// Anual = 10 meses.
    var precioAnual: Int { precioMes * 10 }
    var tope: Int {
        switch self { case .gratis: return 10; case .personal: return 25; case .pro: return 60 }
    }
    var bajada: String {
        switch self {
        case .gratis: return "Para empezar"
        case .personal: return "Para el profe que vive de esto"
        case .pro: return "Para grupos grandes"
        }
    }
    var incluye: [String] {
        switch self {
        case .gratis: return ["Hasta 10 alumnos activos", "Cuotas, horario, rutinas y avisos", "Tu página con «hecha con Otra Más»"]
        case .personal: return ["Hasta 25 alumnos activos", "Link de pago con Mercado Pago", "Tu página sin la marca"]
        case .pro: return ["Hasta 60 alumnos activos", "Todo lo de Personal", "Lo nuevo, apenas sale"]
        }
    }
    func precio(_ p: PeriodoPlan) -> Int { p == .mensual ? precioMes : precioAnual }
}

enum PeriodoPlan: String, Codable, CaseIterable, Hashable {
    case mensual, anual
    var titulo: String { self == .mensual ? "Mensual" : "Anual" }
    var unidad: String { self == .mensual ? "/mes" : "/año" }
}

struct FacturaOM: Codable, Hashable, Identifiable {
    var id = UUID().uuidString
    var numero: String
    var fecha: String
    var concepto: String
    var monto: Int
}

struct Suscripcion: Codable, Hashable {
    var plan: PlanOM
    var periodo: PeriodoPlan = .mensual
    /// Prueba de Pro: 14 días, sin tarjeta, arranca con el 3.er alumno.
    var pruebaHasta: String?
    var pruebaUsada = false
    /// Cuándo se cobra la próxima vez (nil en Gratis o en prueba sin plan elegido).
    var proximoCobro: String?
    /// Plan elegido para cuando termine la prueba.
    var planElegido: PlanOM?
    var renueva = true
    /// Precio de lanzamiento fijo por 6 meses.
    var precioFijoHasta: String
    var facturas: [FacturaOM] = []
    var cuenta = "lu.entrena.mdp@icloud.com"
}

extension DatosDeMuestra {
    /// Lucía: en la prueba de Pro, le quedan 9 días (vence el 3/12).
    static let suscripcion = Suscripcion(plan: .gratis, pruebaHasta: "2026-12-03", pruebaUsada: true, precioFijoHasta: "2027-05-24")
}

extension Estado {
    var activos: Int { profe.alumnos.filter { estadoDe($0.id) == .activo }.count }

    var enPrueba: Bool { (suscripcion.pruebaHasta ?? "") >= hoy && suscripcion.pruebaHasta != nil }
    var diasDePrueba: Int { suscripcion.pruebaHasta.map { max(0, Fecha.dias(entre: hoy, y: $0)) } ?? 0 }
    /// El plan que rige hoy: Pro mientras dura la prueba.
    var planActual: PlanOM { enPrueba ? .pro : suscripcion.plan }
    var tope: Int { planActual.tope }
    var puedeSumarAlumno: Bool { activos < tope }

    /// El plan que alcanza para los alumnos activos.
    var planQueAlcanza: PlanOM { PlanOM.allCases.first { $0.tope >= activos } ?? .pro }

    /// Cuándo sería el primer cobro si elige hoy: al terminar la prueba o ahora.
    var primerCobro: String { enPrueba ? (suscripcion.pruebaHasta ?? hoy) : hoy }

    func comprar(_ p: PlanOM, _ periodo: PeriodoPlan) {
        let monto = p.precio(periodo)
        let cobraHoy = !enPrueba && monto > 0
        let fin = enPrueba ? (suscripcion.pruebaHasta ?? hoy) : hoy
        let siguiente = Fecha.iso(Fecha.calendario.date(byAdding: periodo == .mensual ? .month : .year, value: 1, to: Fecha.fecha(fin)) ?? Date())
        withAnimation(.snappy) {
            suscripcion.periodo = periodo
            suscripcion.renueva = true
            if enPrueba {
                suscripcion.planElegido = p
                suscripcion.proximoCobro = p == .gratis ? nil : fin
            } else {
                suscripcion.plan = p
                suscripcion.planElegido = nil
                suscripcion.proximoCobro = p == .gratis ? nil : siguiente
            }
            if cobraHoy {
                let n = String(format: "0001-%08d", 128 + suscripcion.facturas.count)
                suscripcion.facturas.insert(FacturaOM(numero: n, fecha: hoy, concepto: "Otra Más \(p.nombre) · \(periodo.titulo.lowercased())", monto: monto), at: 0)
            }
        }
        reactivarHasta(p.tope)
        let datos = self.datos
        Task { try? await datos.comprarPlan(p, periodo: periodo) }
        Haptico.exito()
        avisar(enPrueba ? "Listo: \(p.nombre) arranca el \(Fecha.corta(fin)), cuando termina la prueba." : "¡Bienvenida a \(p.nombre)!")
    }

    func cancelarSuscripcion() {
        withAnimation(.snappy) { suscripcion.renueva = false }
        let datos = self.datos
        Task { try? await datos.cancelarSuscripcion() }
        Haptico.exito()
        let hasta = suscripcion.proximoCobro.map { " hasta el \(Fecha.corta($0))" } ?? ""
        avisar("Cancelada. Seguís con \(suscripcion.plan.nombre)\(hasta) y después pasás a Gratis.")
    }

    func restaurarCompras() {
        let datos = self.datos
        Task { try? await datos.restaurarCompras() }
        Haptico.exito()
        avisar(suscripcion.facturas.isEmpty && suscripcion.planElegido == nil ? "No encontramos compras en esta cuenta." : "Compras restauradas: \(suscripcion.plan.nombre).")
    }

    /// Fin de la prueba sin plan elegido: pasa a Gratis y los alumnos que sobran quedan en pausa (no se borran).
    func vencerPrueba() {
        withAnimation(.snappy) {
            suscripcion.pruebaHasta = Fecha.sumar(-1, a: hoy)
            if let p = suscripcion.planElegido { suscripcion.plan = p; suscripcion.planElegido = nil } else { suscripcion.plan = .gratis }
        }
        pausarExcedente()
    }

    /// Deja activos sólo hasta el tope: pausa a los más nuevos.
    func pausarExcedente() {
        let activosIds = profe.alumnos.filter { estadoDe($0.id) == .activo }.map(\.id)
        guard activosIds.count > tope else { return }
        for id in activosIds.suffix(activosIds.count - tope) {
            profe.detalles[id]?.estado = .pausado
            profe.detalles[id]?.pausadoPorTope = true
        }
        profe.resumen.alumnosActivos = tope
    }

    /// Al subir de plan, vuelven los que habían quedado en pausa por el tope.
    private func reactivarHasta(_ nuevoTope: Int) {
        var libres = nuevoTope - activos
        for a in profe.alumnos where libres > 0 && profe.detalles[a.id]?.pausadoPorTope == true {
            profe.detalles[a.id]?.estado = .activo
            profe.detalles[a.id]?.pausadoPorTope = false
            libres -= 1
        }
        profe.resumen.alumnosActivos = activos
    }

    /// La prueba arranca sola cuando se suma el tercer alumno.
    func empezarPruebaSiCorresponde() {
        guard !suscripcion.pruebaUsada, activos >= 3 else { return }
        suscripcion.pruebaUsada = true
        suscripcion.pruebaHasta = Fecha.sumar(14, a: hoy)
        avisar("¡Tenés 14 días de Pro gratis! Sin tarjeta.")
    }
}
