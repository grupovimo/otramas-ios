import SwiftUI
import UIKit

/// Lo que la interfaz lee y las acciones que hace. Todo pasa en memoria al instante (con animación) y
/// después se avisa a `datos`; cuando haya API, `datos` es la que persiste.
@MainActor
@Observable
final class Estado {
    @ObservationIgnored let datos: Datos
    var profe: PanelProfe
    var alumno: PanelAlumno
    /// Aviso corto que se muestra arriba (toast).
    var aviso: String?
    /// Lo que se respondió en el onboarding (nil: todavía no se hizo).
    var perfil: Perfil?
    /// El perfil profesional del profe (su página pública).
    var perfilProfe: PerfilProfe = DatosDeMuestra.perfilLucia
    var ejercicios: [Ejercicio] = DatosDeMuestra.ejercicios
    var tipsProfe: [Tip] = DatosDeMuestra.tipsProfe
    var tipsAlumno: [Tip] = DatosDeMuestra.tipsAlumno

    init(datos: Datos = DatosDeMuestra()) {
        self.datos = datos
        profe = DatosDeMuestra.profe
        alumno = DatosDeMuestra.alumno
        perfil = Perfil.guardado()
    }

    /// Trae lo último de `datos`. Secuencial a propósito: nunca `async let` (cerraba la app en Release).
    func cargar() async {
        if let p = try? await datos.panelProfe() { profe = p }
        if let a = try? await datos.panelAlumno() { alumno = a }
        if let e = try? await datos.ejercicios() { ejercicios = e }
        if let p = try? await datos.perfilProfe() { perfilProfe = p }
        if let t = try? await datos.tips(para: .profe) { tipsProfe = t }
        if let t = try? await datos.tips(para: .alumno) { tipsAlumno = t }
    }

    // MARK: - Perfil y tips

    func guardarPerfil(_ p: Perfil) {
        perfil = p
        p.guardar()
        if p.lado == .alumno && !p.primerNombre.isEmpty { alumno.nombre = p.primerNombre }
        if p.lado == .profe && !p.primerNombre.isEmpty { profe.profe.nombre = p.primerNombre }
        let datos = self.datos
        Task { try? await datos.guardarPerfil(p) }
    }

    func guardar(perfilProfe p: PerfilProfe, aviso: String? = "Perfil guardado.") {
        perfilProfe = p
        let datos = self.datos
        Task { try? await datos.guardarPerfilProfe(p) }
        if let aviso { Haptico.exito(); avisar(aviso) }
    }

    /// Lo que se calcula solo para el perfil: años, alumnos activos y clases dadas.
    var logrosProfe: (anios: Int, alumnos: Int, clases: Int) {
        let anios = max(1, 2026 - perfilProfe.desde)
        let porSemana = profe.horario.reduce(0) { $0 + $1.dias.count }
        return (anios, profe.alumnos.count, anios * 46 * max(porSemana, 1))
    }

    func borrarPerfil() {
        perfil = nil
        Perfil.borrar()
    }

    func ejercicio(_ id: String?) -> Ejercicio? { id.flatMap { i in ejercicios.first { $0.id == i } } }

    /// Sexo para elegir la ilustración: el del perfil del alumno; si no, mujer.
    var sexoIlustracion: Sexo { perfil?.sexo ?? .mujer }

    /// Un tip para mostrar: cambia con el día (y con `salto`, para que no se repita en la misma pantalla).
    func tip(_ lado: Lado, salto: Int = 0) -> Tip? {
        let lista = lado == .profe ? tipsProfe : tipsAlumno
        guard !lista.isEmpty else { return nil }
        let dia = Calendar.current.ordinality(of: .day, in: .era, for: Date()) ?? 0
        return lista[(dia + salto) % lista.count]
    }

    func avisar(_ texto: String) {
        withAnimation(.spring(duration: 0.35)) { aviso = texto }
        Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.6))
            guard let self, self.aviso == texto else { return }
            withAnimation(.easeOut(duration: 0.25)) { self.aviso = nil }
        }
    }

    // MARK: - Derivados del profe

    var alumnos: [Alumno] { profe.alumnos }
    var total: Int { profe.alumnos.count }
    var pagaron: Int { profe.alumnos.filter { $0.cuota == .alDia }.count }

    var porConfirmar: [(alumno: Alumno, comprobante: Comprobante)] {
        profe.alumnos.compactMap { a in
            if case .porConfirmar(let c) = a.cuota { return (a, c) }
            return nil
        }
    }

    var deben: [(alumno: Alumno, deuda: Deuda)] {
        profe.alumnos.compactMap { a in
            if case .debe(let d) = a.cuota { return (a, d) }
            return nil
        }
        .sorted { $0.deuda.dias > $1.deuda.dias }
    }

    var montoPorConfirmar: Int { porConfirmar.reduce(0) { $0 + $1.comprobante.monto } }
    var montoDeben: Int { deben.reduce(0) { $0 + $1.deuda.monto } }
    var faltan: Int { montoPorConfirmar + montoDeben }
    var esperado: Int { profe.resumen.cobrado + faltan }
    /// El número rojo de Cuotas en la barra: lo que hay para resolver.
    var pendientesCuotas: Int { porConfirmar.count + deben.count }
    var porcentajeAlDia: Int { total == 0 ? 0 : Int((Double(pagaron) / Double(total) * 100).rounded()) }

    func alumno(_ id: String) -> Alumno? { profe.alumnos.first { $0.id == id } }

    var proxima: Clase? { profe.clases.first { $0.id == profe.proxima } }

    // MARK: - Acciones del profe

    func confirmar(alumnoId: String) {
        guard let i = profe.alumnos.firstIndex(where: { $0.id == alumnoId }),
              case .porConfirmar(let c) = profe.alumnos[i].cuota else { return }
        Haptico.exito()
        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            profe.alumnos[i].cuota = .alDia
            cobrar(monto: c.monto)
        }
        let datos = self.datos
        Task { try? await datos.confirmarComprobante(alumnoId: alumnoId, comprobanteId: c.id) }
    }

    func registrarCobro(alumnoId: String, monto: Int, medio: MedioPago) {
        guard let i = profe.alumnos.firstIndex(where: { $0.id == alumnoId }) else { return }
        Haptico.exito()
        withAnimation(.spring(duration: 0.6, bounce: 0.2)) {
            profe.alumnos[i].cuota = .alDia
            cobrar(monto: monto)
            if let m = profe.resumen.medios.firstIndex(where: { $0.medio == medio }) { profe.resumen.medios[m].cuotas += 1 }
        }
        let datos = self.datos
        Task { try? await datos.registrarCobro(alumnoId: alumnoId, monto: monto, medio: medio) }
        avisar("Cobro registrado: \(Formato.plata(monto)) de \(profe.alumnos[i].primerNombre).")
    }

    private func cobrar(monto: Int) {
        profe.resumen.cobrado += monto
        if !profe.resumen.ingresos.isEmpty {
            profe.resumen.ingresos[profe.resumen.ingresos.count - 1] = Double(profe.resumen.cobrado) / 1000
        }
    }

    func recordarDeudas(_ ids: [String]? = nil) {
        let lista = ids ?? deben.map(\.alumno.id)
        guard !lista.isEmpty else { avisar("Nadie te debe este mes."); return }
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.recordarDeudas(alumnoIds: lista) }
        if lista.count == 1, let a = alumno(lista[0]) {
            avisar("Listo. Le llegó el recordatorio a \(a.primerNombre).")
        } else {
            avisar("Listo. Les llegó el recordatorio a los \(lista.count).")
        }
    }

    func suspender(claseId: String, motivo: String, dejarRecuperar: Bool) {
        Haptico.exito()
        let n = clase(claseId)?.vienen ?? 0
        withAnimation(.snappy) {
            if let i = profe.clases.firstIndex(where: { $0.id == claseId }) {
                profe.clases[i].estado = .suspendida(motivo)
            } else if let i = profe.clasesUnicas.firstIndex(where: { $0.id == claseId }) {
                profe.clasesUnicas[i].estado = .suspendida(motivo)
            } else {
                profe.ajustes[claseId, default: AjusteClase()].suspendida = motivo
            }
        }
        let datos = self.datos
        Task { try? await datos.suspenderClase(claseId: claseId, motivo: motivo, dejarRecuperar: dejarRecuperar) }
        avisar("Clase suspendida. Les avisamos a los \(n).")
    }

    func guardarAsistencia(claseId: String, presentes: Set<String>) {
        Haptico.exito()
        let total = clase(claseId)?.inscriptos.count ?? presentes.count
        if let i = profe.clases.firstIndex(where: { $0.id == claseId }) {
            profe.clases[i].presentes = presentes
        } else if let i = profe.clasesUnicas.firstIndex(where: { $0.id == claseId }) {
            profe.clasesUnicas[i].presentes = presentes
        } else {
            profe.ajustes[claseId, default: AjusteClase()].presentes = presentes
        }
        let datos = self.datos
        Task { try? await datos.guardarAsistencia(claseId: claseId, presentes: presentes) }
        avisar("Lista guardada: vinieron \(presentes.count) de \(total).")
    }

    func crearAlumno(nombre: String, plan: String) {
        let limpio = nombre.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !limpio.isEmpty else { return }
        Haptico.exito()
        let nuevo = Alumno(id: "nuevo-\(profe.alumnos.count + 1)", nombre: limpio, tono: .berenjena, plan: plan,
                           horario: "a definir", cuota: .alDia, asistencias: 0, clasesDelMes: 0, racha: 0,
                           progreso: nil, pasos: nil, ultimaVez: 0)
        withAnimation(.snappy) {
            profe.alumnos.insert(nuevo, at: 0)
            profe.resumen.alumnosActivos += 1
            profe.resumen.nuevos += 1
        }
        UIPasteboard.general.string = "https://otramas.com.ar/\(profe.profe.alias.split(separator: ".").first ?? "lucia")/\(limpio.split(separator: " ").first?.lowercased() ?? "alumno")"
        let datos = self.datos
        Task { _ = try? await datos.crearAlumno(nombre: limpio, plan: plan) }
        avisar("\(nuevo.primerNombre) ya está. Copiamos su link para mandárselo.")
    }

    // MARK: - Acciones del alumno

    var ejercicioActual: EjercicioSesion { alumno.sesion.ejercicios[min(alumno.sesion.actual, alumno.sesion.ejercicios.count - 1)] }
    var terminoSesion: Bool { alumno.sesion.actual >= alumno.sesion.ejercicios.count }

    func cambiarCarga(kilos: Double = 0, reps: Int = 0) {
        let i = alumno.sesion.actual
        guard i < alumno.sesion.ejercicios.count else { return }
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.2)) {
            alumno.sesion.ejercicios[i].kilos = max(0, alumno.sesion.ejercicios[i].kilos + kilos)
            alumno.sesion.ejercicios[i].reps = max(1, alumno.sesion.ejercicios[i].reps + reps)
        }
    }

    /// ¡Listo!: marca la serie, arranca el descanso y, si era la última, pasa al ejercicio siguiente.
    func listo() {
        let i = alumno.sesion.actual
        guard i < alumno.sesion.ejercicios.count else { return }
        let e = alumno.sesion.ejercicios[i]
        Haptico.exito()
        let datos = self.datos
        Task { try? await datos.registrarSerie(ejercicioId: e.id, kilos: e.kilos, reps: e.reps) }
        withAnimation(.spring(duration: 0.45, bounce: 0.25)) {
            alumno.sesion.hechas += 1
            if alumno.sesion.hechas >= e.series {
                if e.kilos > alumno.logros.record.kilos {
                    alumno.logros.record.kilos = e.kilos
                    alumno.logros.record.ejercicio = e.nombre
                }
                alumno.sesion.actual += 1
                alumno.sesion.hechas = 0
                alumno.sesion.descansoRestante = 0
            } else {
                alumno.sesion.descansoRestante = e.descanso
            }
        }
    }

    func tickDescanso() {
        guard alumno.sesion.descansoRestante > 0 else { return }
        alumno.sesion.descansoRestante -= 1
        if alumno.sesion.descansoRestante == 0 { Haptico.suave() }
    }

    func reiniciarSesion() {
        withAnimation(.snappy) { alumno.sesion = DatosDeMuestra.alumno.sesion }
    }

    func avisarFalta() {
        Haptico.exito()
        withAnimation(.snappy) {
            alumno.plan.avisoFalta = true
            alumno.plan.paraRecuperar += 1
        }
        let datos = self.datos
        Task { try? await datos.avisarFalta() }
        avisar("Le avisamos a \(alumno.profe). Te queda para recuperar.")
    }

    func elegirRecuperar(_ dia: String) {
        guard alumno.plan.paraRecuperar > 0 else { return }
        Haptico.exito()
        withAnimation(.snappy) { alumno.plan.paraRecuperar -= 1 }
        avisar("Listo, recuperás el \(dia).")
    }
}
