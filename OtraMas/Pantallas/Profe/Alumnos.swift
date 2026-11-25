import SwiftUI

/// Alumnos: la lista de los 30, con filtro por cuota y buscador. Lleva a la ficha.
struct ListaAlumnos: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @State private var filtro = Filtro.todos
    @State private var buscar = ""

    enum Filtro: String, CaseIterable { case todos = "Todos", alDia = "Al día", deben = "Deben" }

    private var lista: [Alumno] {
        estado.alumnos.filter { a in
            let pasa: Bool
            switch filtro {
            case .todos: pasa = true
            case .alDia: pasa = a.cuota == .alDia
            case .deben: if case .alDia = a.cuota { pasa = false } else { pasa = true }
            }
            let q = buscar.trimmingCharacters(in: .whitespaces)
            return pasa && (q.isEmpty || a.nombre.localizedStandardContains(q))
        }
    }

    var body: some View {
        PantallaProfe {
            CabeceraPestana(titulo: "Alumnos") {
                Button { nav.hoja = .nuevo } label: {
                    IconoVista(.mas, tamano: 20).foregroundStyle(Color.berenjena800)
                        .frame(width: 44, height: 44).background(Color.yema, in: Circle())
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("Alumno nuevo")
            }
            HStack(spacing: 8) {
                ForEach(Filtro.allCases, id: \.self) { f in
                    Chip(titulo: f.rawValue, elegido: filtro == f, sobreBanda: true) {
                        Haptico.seleccion()
                        withAnimation(.snappy(duration: 0.25)) { filtro = f }
                    }
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 16)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.berenjena300)
                TextField("", text: $buscar, prompt: Text("Buscar por nombre").foregroundColor(.berenjena300))
                    .font(Estilo.texto(16, 400).font())
                    .foregroundStyle(Color.hueso)
                    .tint(Color.yema)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            }
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 12)
        } cuerpo: {
            TituloSeccion(texto: filtro == .todos ? "Activos" : filtro.rawValue, arriba: 0) {
                Text("\(lista.count) de \(estado.total)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            if lista.isEmpty {
                Tarjeta(relleno: 24) {
                    VStack(spacing: 8) {
                        Text(buscar.isEmpty ? "Nadie en este grupo" : "No encontramos a «\(buscar)»")
                            .tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                        Text("Probá con otro nombre o sumá un alumno nuevo.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    }
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)
                }
            } else {
                Tarjeta {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(lista.enumerated()), id: \.element.id) { i, a in
                            if i > 0 { Divisor() }
                            NavigationLink(value: DestinoProfe.ficha(a.id)) { fila(a) }
                                .buttonStyle(Apretable())
                        }
                    }
                }
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    private func fila(_ a: Alumno) -> some View {
        HStack(spacing: 12) {
            Iniciales(texto: a.iniciales, tono: a.tono, tamano: 40)
            NomSub(nombre: a.nombre, sub: Text("\(a.plan) · \(a.horario)"))
            estadoCuota(a.cuota)
            IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func estadoCuota(_ c: EstadoCuota) -> some View {
        switch c {
        case .alDia:
            IconoVista(.tilde, tamano: 16).foregroundStyle(Color.ok)
                .frame(width: 28, height: 28).background(Color.okFondo, in: Circle())
                .accessibilityLabel("Al día")
        case .porConfirmar:
            Text("Revisar").tipo(.texto(12, 700)).foregroundStyle(Color.yema700)
                .padding(.horizontal, 8).frame(height: 24).background(Color.yema100, in: Capsule())
        case .debe:
            Text("Debe").tipo(.texto(12, 700)).foregroundStyle(Color.error)
                .padding(.horizontal, 8).frame(height: 24).background(Color(hex: 0xFBE6E3), in: Capsule())
        }
    }
}

/// 3 · Ficha del alumno: asistencia, racha y cuota; acciones; progreso de un ejercicio y pasos de Apple Salud.
struct FichaAlumno: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @Environment(\.dismiss) private var dismiss
    let alumnoId: String

    var body: some View {
        if let a = estado.alumno(alumnoId) {
            contenido(a)
        } else {
            Text("Ese alumno ya no está.").tipo(.texto(16, 600)).foregroundStyle(Color.texto2)
                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.hueso)
        }
    }

    private func contenido(_ a: Alumno) -> some View {
        PantallaProfe(arribaCuerpo: 24) {
            NavBanda(atras: "Alumnos", accionAtras: { dismiss() }) {
                Menu {
                    Button { UIPasteboard.general.string = "https://otramas.com.ar/lucia/\(a.primerNombre.lowercased())"; estado.avisar("Copiamos el link de \(a.primerNombre).") } label: {
                        Label("Copiar su link", systemImage: "link")
                    }
                    Button { estado.avisar("\(a.primerNombre) quedó en pausa.") } label: {
                        Label("Pausar", systemImage: "pause.circle")
                    }
                } label: {
                    IconoVista(.puntos, tamano: 20).foregroundStyle(Color.hueso)
                        .frame(width: 44, height: 44).background(Color.huesoOsc, in: Circle())
                }
                .accessibilityLabel("Más opciones")
            }
            HStack(spacing: 16) {
                Iniciales(texto: a.iniciales, tono: .yemaFuerte, tamano: 56)
                VStack(alignment: .leading, spacing: 4) {
                    Titulo(a.nombre, tamano: 40, color: .hueso)
                    Text("\(a.plan) · \(a.horario)").tipo(.texto(14, 400)).foregroundStyle(Color.berenjena300).lineLimit(1)
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 8)
            aros(a)
        } cuerpo: {
            HStack(spacing: 8) {
                accion("WhatsApp", .wa, color: .ok) { estado.avisar("Abrimos WhatsApp con \(a.primerNombre).") }
                accion("Rutina", .pesa) { nav.rutinaAbierta = true }
                accion("Cobrar", .plata) { nav.hoja = .cobrar(a.id) }
            }
            if let p = a.progreso {
                Tarjeta(relleno: 16) {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Etiqueta(p.ejercicio)
                            Numero(valor: Formato.decimal(p.actual), tamano: 28, unidad: "kg")
                        }
                        Spacer(minLength: 8)
                        HStack(spacing: 4) {
                            IconoVista(.sube, tamano: 16)
                            Text("+\(Formato.decimal(p.actual - (p.valores.first ?? p.actual))) kg desde \(p.desde)").tipo(.texto(14, 700))
                        }
                        .foregroundStyle(Color.ok)
                        .padding(.bottom, 4)
                    }
                    GraficoProgreso(valores: p.valores, meses: p.meses).padding(.top, 8)
                }
                .padding(.top, 12)
            } else {
                Tarjeta(relleno: 16) {
                    Etiqueta("Progreso")
                    Text("Todavía no cargó pesos. Cuando entrene con su rutina, acá ves cómo sube.")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 8)
                }
                .padding(.top, 12)
            }
            Tarjeta(relleno: 16) {
                HStack {
                    Etiqueta("Actividad")
                    Spacer()
                    DeAppleSalud()
                }
                if let pasos = a.pasos {
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            Numero(valor: promedio(pasos), tamano: 28, unidad: "pasos por día")
                            Text("Promedio de 7 días").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                        Spacer(minLength: 8)
                        GraficoPasos(pasos: pasos)
                    }
                    .padding(.top, 8)
                } else {
                    Text("No comparte sus pasos de Apple Salud.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 8)
                }
            }
            .padding(.top, 12)
        }
    }

    private func promedio(_ pasos: [Double]) -> String {
        let total: Double = pasos.reduce(0, +)
        let prom: Double = total / Double(max(pasos.count, 1))
        let redondo: Int = Int((prom / 100).rounded()) * 100
        return Formato.miles(redondo)
    }

    private func aros(_ a: Alumno) -> some View {
        let pago = a.cuota == .alDia
        return HStack(spacing: 0) {
            aro(total: Double(max(a.clasesDelMes, 1)), valor: Double(a.asistencias), color: .yema,
                titulo: "Asistencia", sub: "noviembre") {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(a.asistencias)").tipo(.numero(28))
                    Text("/\(a.clasesDelMes)").tipo(.numero(16)).foregroundStyle(Color.berenjena300)
                }
                .foregroundStyle(Color.hueso)
            }
            aro(total: Double(max(a.racha + 1, 1)), valor: Double(a.racha), color: .racha,
                titulo: "Racha", sub: "semanas seguidas") {
                Text("\(a.racha)").tipo(.numero(28)).foregroundStyle(Color.hueso)
            }
            aro(total: 1, valor: pago ? 1 : 0, color: pago ? .okClaro : .errorClaro,
                titulo: "Cuota", sub: pago ? "pagó noviembre" : "debe noviembre") {
                IconoVista(pago ? .tilde : .reloj, tamano: 28, grosor: 2.6).foregroundStyle(pago ? Color.okClaro : Color.errorClaro)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 24)
    }

    private func aro<C: View>(total: Double, valor: Double, color: Color, titulo: String, sub: String,
                              @ViewBuilder centro: @escaping () -> C) -> some View {
        VStack(spacing: 8) {
            Anillo(tamano: 80, grosor: 10, total: total, segmentos: [.init(valor: valor, color: color)],
                   pista: .berenjena700, redondo: true, centro: centro)
            VStack(spacing: 0) {
                Text(titulo).tipo(.texto(14, 700)).foregroundStyle(Color.hueso)
                Text(sub).tipo(.texto(12, 400)).foregroundStyle(Color.berenjena300).lineLimit(1).minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    private func accion(_ t: String, _ i: Icono, color: Color? = nil, _ hacer: @escaping () -> Void) -> some View {
        Button(action: hacer) {
            HStack(spacing: 8) {
                IconoVista(i, tamano: 20).foregroundStyle(color ?? Color.berenjena800)
                Text(t).tipo(.texto(16, 700)).foregroundStyle(Color.berenjena800).lineLimit(1).fixedSize()
            }
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
        }
        .buttonStyle(Apretable())
    }
}

/// «♥ De Apple Salud» (.fuente).
struct DeAppleSalud: View {
    var body: some View {
        HStack(spacing: 4) {
            IconoVista(.corazon, tamano: 12).foregroundStyle(Color.salud)
            Text("De Apple Salud").tipo(.texto(12, 600)).foregroundStyle(Color.texto2).lineLimit(1)
        }
    }
}
