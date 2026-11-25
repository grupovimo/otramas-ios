import SwiftUI
import XCTest
@testable import OtraMas

/// Humo: monta cada pantalla con DatosDeMuestra en una ventana de verdad y la dibuja. Si algo se cae al
/// abrirla (como el `async let` que cerraba Tu Local Web en Release), salta acá. Corre también en Release:
/// `xcodebuild test -configuration Release ENABLE_TESTABILITY=YES …`.
@MainActor
final class PantallasTests: XCTestCase {
    private var ventana: UIWindow?

    override func tearDown() {
        ventana?.isHidden = true
        ventana = nil
    }

    private func montar<V: View>(_ vista: V, segundos: Double = 0.6, file: StaticString = #filePath, line: UInt = #line) {
        let estado = Estado()
        let nav = NavProfe()
        let raiz = vista
            .environment(estado)
            .environment(nav)
            .preferredColorScheme(.light)
        let escena = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first
        let v = escena.map { UIWindow(windowScene: $0) } ?? UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        let host = UIHostingController(rootView: raiz)
        v.rootViewController = host
        v.makeKeyAndVisible()
        ventana = v
        RunLoop.main.run(until: Date().addingTimeInterval(segundos))
        host.view.layoutIfNeeded()
        XCTAssertGreaterThan(host.view.bounds.width, 0, file: file, line: line)

        // Y además a imagen, a 390 × 844 como el diseño.
        let r = ImageRenderer(content: raiz.frame(width: 390, height: 844))
        r.scale = 1
        XCTAssertNotNil(r.uiImage, "No se pudo dibujar la pantalla", file: file, line: line)
    }

    // Profe
    func testRaizProfe() { montar(RaizProfe(arranque: .inicio)) }
    func testInicio() { montar(NavigationStack { Inicio() }) }
    func testMenuMasUno() { montar(RaizProfe(arranque: .menu)) }
    func testTuMes() { montar(NavigationStack { TuMes() }) }
    func testCuotas() { montar(NavigationStack { Cuotas() }) }
    func testHorario() { montar(NavigationStack { Horario() }) }
    func testSuspender() { montar(HojaSuspender(claseId: "c3")) }
    func testAlumnos() { montar(NavigationStack { ListaAlumnos() }) }
    func testFicha() { montar(NavigationStack { FichaAlumno(alumnoId: "carla") }) }
    func testFichaSinDatos() { montar(NavigationStack { FichaAlumno(alumnoId: "tomas") }) }
    func testFichaInexistente() { montar(NavigationStack { FichaAlumno(alumnoId: "nadie") }) }
    func testRutina() { montar(ArmadoRutina()) }
    func testCobrar() { montar(HojaCobrar(alumnoId: nil)) }
    func testCobrarUno() { montar(HojaCobrar(alumnoId: "martina")) }
    func testPasarLista() { montar(HojaPasarLista(claseId: "c1")) }
    func testAlumnoNuevo() { montar(HojaAlumnoNuevo()) }
    func testRutinas() { montar(NavigationStack { ListaRutinas() }) }
    func testDetalleRutina() { montar(NavigationStack { DetalleRutina(rutinaId: "r1") }) }
    func testDetallePlantilla() { montar(NavigationStack { DetalleRutina(rutinaId: "p-hipertrofia") }) }
    func testDetalleRutinaInexistente() { montar(NavigationStack { DetalleRutina(rutinaId: "nada") }) }
    func testAsignarRutina() { montar(HojaAsignarRutina(rutinaId: "r1", preelegidos: ["martina"])) }
    func testEnviarRutina() { montar(HojaEnviarRutina(rutinaId: "r1")) }
    func testEnviarSinAsignar() { montar(HojaEnviarRutina(rutinaId: "p-pilates")) }
    func testPDFRutina() { montar(HojaPDFRutina(rutinaId: "r1"), segundos: 1.5) }
    func testElegirRutina() { montar(HojaElegirRutina(alumnoIds: ["martina", "ezequiel", "ramiro"])) }
    func testArmadoNueva() { montar(ArmadoRutina(rutina: Estado().rutinaNueva())) }
    func testHorarioApilado() { montar(NavigationStack { Horario(apilada: true) }) }
    func testHojaClase() { montar(HojaClase(claseId: "fm@2026-11-26")) }
    func testNuevaClase() { montar(HojaNuevaClase(fecha: "2026-11-29")) }

    // Alumno
    func testRaizAlumno() { montar(RaizAlumno(arranque: .hoy)) }
    func testHoy() { montar(HoyToca()) }
    func testLogros() { montar(LogrosAlumno()) }
    func testMiPlan() { montar(MiPlan()) }

    // Onboarding: cada paso de cada lado
    func testOnboardingAlumno() {
        for i in 0..<PasoOnboarding.pasos(.alumno).count {
            montar(Onboarding(lado: .alumno, paso: i, perfil: i == 0 ? nil : DatosDeMuestra.perfilAlumno) { _ in }, segundos: 0.2)
        }
    }
    func testOnboardingProfe() {
        for i in 0..<PasoOnboarding.pasos(.profe).count {
            montar(Onboarding(lado: .profe, paso: i, perfil: i == 0 ? nil : DatosDeMuestra.perfilProfe) { _ in }, segundos: 0.2)
        }
    }
    func testPerfilSeGuarda() {
        let d = UserDefaults(suiteName: "prueba-perfil")!
        DatosDeMuestra.perfilAlumno.guardar(d)
        XCTAssertEqual(Perfil.guardado(d), DatosDeMuestra.perfilAlumno)
        Perfil.borrar(d)
        XCTAssertNil(Perfil.guardado(d))
    }

    // Biblioteca, ajustes y tips
    func testBiblioteca() { montar(NavigationStack { Biblioteca(volver: "Cerrar") }) }
    func testDetalleEjercicio() { montar(NavigationStack { DetalleEjercicio(ejercicio: DatosDeMuestra.ejercicios[1], sexo: .hombre, cerrable: true) }) }
    func testDetalleSinIlustracion() {
        let core = DatosDeMuestra.ejercicios.first { $0.grupo == .core }!
        montar(DetalleEjercicio(ejercicio: core, sexo: .mujer, elegir: {}))
    }
    func testAjustes() { montar(Ajustes()) }
    func testCarga() { montar(CargaInicial(tip: DatosDeMuestra.tipsAlumno[0])) }

    func testBibliotecaYTips() {
        XCTAssertEqual(DatosDeMuestra.tipsAlumno.count, 20)
        XCTAssertEqual(DatosDeMuestra.tipsProfe.count, 20)
        XCTAssertEqual(Set(DatosDeMuestra.ejercicios.map(\.id)).count, DatosDeMuestra.ejercicios.count, "ids repetidos")
        for g in GrupoEjercicio.allCases { XCTAssertFalse(DatosDeMuestra.ejercicios.filter { $0.grupo == g }.isEmpty, g.rawValue) }
        let e = DatosDeMuestra.ejercicios[0]
        XCTAssertEqual(e.ilustracion(para: .hombre), "ej-hombre-\(e.id)")
        XCTAssertEqual(e.ilustracion(para: .sinDecir), "ej-mujer-\(e.id)")
        for e in DatosDeMuestra.ejercicios {
            XCTAssertNotNil(e.imagen(para: .mujer), "falta la ilustración de \(e.id)")
            XCTAssertNotNil(e.imagen(para: .hombre), "sin la de hombre tiene que caer en la de mujer: \(e.id)")
        }
        // Las rutinas de muestra apuntan a ejercicios del catálogo.
        let ids = Set(DatosDeMuestra.ejercicios.map(\.id))
        for d in DatosDeMuestra.rutina.dias { for x in d.ejercicios { XCTAssertTrue(ids.contains(x.ejercicioId ?? ""), x.nombre) } }
        for x in DatosDeMuestra.alumno.sesion.ejercicios { XCTAssertTrue(ids.contains(x.ejercicioId ?? ""), x.nombre) }
    }

    // Lógica en memoria
    func testConfirmarMueveLaDona() {
        let e = Estado()
        XCTAssertEqual(e.pagaron, 24)
        XCTAssertEqual(e.total, 30)
        XCTAssertEqual(e.porcentajeAlDia, 80)
        XCTAssertEqual(e.pendientesCuotas, 6)
        XCTAssertEqual(Formato.plata(e.profe.resumen.cobrado), "$1.215.000")
        XCTAssertEqual(Formato.plata(e.faltan), "$297.000")
        e.confirmar(alumnoId: "camila")
        XCTAssertEqual(e.pagaron, 25)
        XCTAssertEqual(e.pendientesCuotas, 5)
        XCTAssertEqual(e.porcentajeAlDia, 83)
        XCTAssertEqual(Formato.plata(e.profe.resumen.cobrado), "$1.260.000")
        XCTAssertEqual(Formato.plata(e.faltan), "$252.000")
    }

    func testRutinasYAsignaciones() {
        let e = Estado()
        let ids = Set(DatosDeMuestra.ejercicios.map(\.id))
        XCTAssertGreaterThanOrEqual(e.plantillas.count, 8)
        for r in e.profe.rutinas { for d in r.dias { for x in d.ejercicios { XCTAssertTrue(ids.contains(x.ejercicioId ?? ""), "\(r.nombre): \(x.nombre)") } } }
        XCTAssertEqual(e.sinRutina.map(\.id).sorted(), ["ezequiel", "martina", "ramiro"])
        // Asignar una plantilla la copia a Mías y reemplaza la rutina anterior.
        let antes = e.rutinasMias.count
        let rid = e.asignar(rutina: "p-gluteos", a: ["martina", "carla"], desde: "2026-11-30", reemplaza: true)
        XCTAssertEqual(e.rutinasMias.count, antes + 1)
        XCTAssertEqual(e.rutinaActual(de: "carla")?.rutina.id, rid)
        XCTAssertFalse(e.rutina("r1")!.asignaciones.contains { $0.alumnoId == "carla" })
        XCTAssertEqual(e.sinRutina.count, 2)
        // Duplicar y archivar.
        let copia = e.duplicar(rutina: "r1")!
        XCTAssertEqual(e.rutina(copia)?.nombre, "Piernas y zona media (copia)")
        e.archivar(rutina: copia)
        XCTAssertTrue(e.rutinasArchivadas.contains { $0.id == copia })
        // Una nueva al guardarse va a Mías.
        var nueva = e.rutinaNueva(); nueva.nombre = "Core express"
        e.guardar(rutina: nueva)
        XCTAssertEqual(e.rutinasMias.first?.nombre, "Core express")
    }

    /// El bug de Horario: ningún día con clases puede quedar vacío (pasado, hoy, futuro, otro mes).
    func testHorarioTreintaDias() {
        let e = Estado()
        for k in -10..<30 {
            let iso = Fecha.sumar(k, a: e.hoy)
            let clases = e.clases(en: iso)
            let d = Fecha.diaSemana(iso)
            if e.feriado(iso) != nil || d == 7 {
                XCTAssertTrue(clases.isEmpty, iso)
            } else {
                XCTAssertFalse(clases.isEmpty, "\(iso) quedó vacío")
                for c in clases {
                    XCTAssertFalse(c.inscriptos.isEmpty, "\(iso) \(c.nombre) sin alumnos")
                    XCTAssertNotNil(e.clase(c.id), c.id)
                    if iso < e.hoy { XCTAssertEqual(c.estado, .termino, iso) }
                    if iso > e.hoy { XCTAssertGreaterThan(c.vienen, 0, iso) }
                }
            }
        }
        // Suspender y anotar en una fecha futura.
        let id = "ft@2026-11-26"
        e.anotar("ramiro", en: id)
        XCTAssertTrue(e.clase(id)!.presentes.contains("ramiro"))
        e.suspender(claseId: id, motivo: "Lluvia", dejarRecuperar: true)
        XCTAssertEqual(e.clase(id)?.estado, .suspendida("Lluvia"))
    }

    func testPDFReal() throws {
        let e = Estado()
        let r = e.rutina("r1")!
        let url = try XCTUnwrap(PDFRutina.generar(r, profe: "Lucía", sexo: .mujer, ejercicios: e.ejercicios))
        let datos = try Data(contentsOf: url)
        XCTAssertTrue(datos.starts(with: Array("%PDF".utf8)))
        XCTAssertGreaterThan(datos.count, 20_000)
        // Una muestra para revisar a mano (sólo si existe la carpeta del repo).
        let capturas = URL(fileURLWithPath: "/Users/nahuelsantillan/Trabajo/vimo/otramas-ios/capturas")
        if FileManager.default.fileExists(atPath: capturas.path) {
            let destino = capturas.appendingPathComponent("rutina.pdf")
            try? FileManager.default.removeItem(at: destino)
            try? FileManager.default.copyItem(at: url, to: destino)
            let largo = try XCTUnwrap(PDFRutina.generar(e.rutina("p-hipertrofia")!, profe: "Lucía", sexo: .hombre, ejercicios: e.ejercicios))
            let d2 = capturas.appendingPathComponent("rutina-hipertrofia.pdf")
            try? FileManager.default.removeItem(at: d2)
            try? FileManager.default.copyItem(at: largo, to: d2)
        }
    }

    func testListoAvanzaLaSerie() {
        let e = Estado()
        XCTAssertEqual(e.ejercicioActual.nombre, "Peso muerto rumano")
        XCTAssertEqual(e.alumno.sesion.hechas, 2)
        e.listo()
        XCTAssertEqual(e.alumno.sesion.hechas, 3)
        XCTAssertEqual(e.alumno.sesion.descansoRestante, 120)
        e.tickDescanso()
        XCTAssertEqual(e.alumno.sesion.descansoRestante, 119)
        e.listo()
        XCTAssertEqual(e.ejercicioActual.nombre, "Estocadas")
        XCTAssertEqual(e.alumno.sesion.hechas, 0)
    }

    func testIconosSeLeen() {
        for i in Icono.allCases {
            let r = ImageRenderer(content: IconoVista(i).foregroundStyle(.black))
            XCTAssertNotNil(r.uiImage, "\(i)")
        }
    }

    func testFuentesVariables() {
        let titulo = Estilo.titulo(40).uiFont()
        let texto = Estilo.texto(16, 700).uiFont()
        XCTAssertTrue(titulo.fontName.hasPrefix("Archivo"), titulo.fontName)
        XCTAssertTrue(texto.fontName.hasPrefix("Figtree"), texto.fontName)
        // Ancho 62 es bastante más angosto que el normal.
        let angosto = ("HOLA, LUCÍA" as NSString).size(withAttributes: [.font: titulo]).width
        let normal = ("HOLA, LUCÍA" as NSString).size(withAttributes: [.font: Tipo.uiFont(.archivo, tamano: 40, peso: 900, ancho: 100)]).width
        XCTAssertLessThan(angosto, normal * 0.85)
        // Mismo tamaño, otro ancho: el número (75) tiene que medir lo del diseño (~172 pt), no lo del título (62).
        let plata = ("$1.215.000" as NSString).size(withAttributes: [.font: Estilo.numero(40).uiFont()]).width
        XCTAssertEqual(plata, 172.6, accuracy: 6, "ancho 75 no aplicado")
    }
}
