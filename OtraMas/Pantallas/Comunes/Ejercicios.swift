import SwiftUI

/// La ilustración de un ejercicio (mujer u hombre). Mientras no esté el PNG, un lugar reservado del mismo tamaño.
struct IlustracionEjercicio: View {
    let ejercicio: Ejercicio
    var sexo: Sexo

    var body: some View {
        ZStack {
            Color(hex: 0xF7F3ED)
            if let img = ejercicio.imagen(para: sexo) {
                Image(uiImage: img).resizable().scaledToFit()
            } else {
                VStack(spacing: 8) {
                    IconoVista(icono(ejercicio.grupo), tamano: 32).foregroundStyle(Color.arena300)
                    Text("Ilustración en camino").tipo(.texto(12, 600)).foregroundStyle(Color.arena500)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("Ilustración de \(ejercicio.nombre)")
    }
}

func icono(_ g: GrupoEjercicio) -> Icono {
    switch g { case .piernas: return .pesa; case .empuje: return .sube; case .tiron: return .cambio; case .core: return .rayo; case .pilates: return .estrella }
}

/// Biblioteca de ejercicios: buscador, filtros por grupo y la grilla de ilustraciones.
/// Con `elegir`, sirve para sumar un ejercicio a la rutina.
struct Biblioteca: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    var elegir: ((Ejercicio) -> Void)?
    /// Texto del botón de volver («Cerrar» en una hoja, «Ajustes» si se entró desde ahí).
    var volver: String?
    @State private var buscar = ""
    @State private var grupo: GrupoEjercicio?
    @State private var sexo: Sexo?

    private var sexoVista: Sexo { sexo ?? estado.sexoIlustracion }

    private var lista: [Ejercicio] {
        let q = buscar.trimmingCharacters(in: .whitespaces)
        return estado.ejercicios.filter { e in
            (grupo == nil || e.grupo == grupo) && (q.isEmpty || e.nombre.localizedStandardContains(q))
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Banda {
                    HStack {
                        if let volver {
                            Button { dismiss() } label: {
                                HStack(spacing: 0) {
                                    if volver != "Cerrar" { IconoVista(.atras, tamano: 24).padding(.leading, -8) }
                                    Text(volver).tipo(.texto(16, 600))
                                }
                                .foregroundStyle(Color.hueso).frame(height: 44).contentShape(Rectangle())
                            }
                            .buttonStyle(Apretable())
                        }
                        Spacer()
                        HStack(spacing: 4) {
                            ForEach([Sexo.mujer, .hombre], id: \.self) { s in
                                Button { Haptico.seleccion(); sexo = s } label: {
                                    Text(s.titulo).tipo(.texto(14, 700))
                                        .foregroundStyle(sexoVista == s ? Color.berenjena800 : Color.hueso.opacity(0.7))
                                        .padding(.horizontal, 14).frame(height: 36)
                                        .background(sexoVista == s ? Color.yema : Color.clear, in: Capsule())
                                }
                                .buttonStyle(Apretable())
                                .accessibilityLabel("Ver ilustraciones de \(s.titulo.lowercased())")
                            }
                        }
                        .padding(4)
                        .background(Color.berenjena700, in: Capsule())
                    }
                    .padding(.horizontal, Espacio.margen)
                    .frame(height: 52)
                    HStack(alignment: .bottom) {
                        Titulo(elegir == nil ? "Ejercicios" : "Sumar ejercicio", tamano: 40, color: .hueso)
                        Spacer()
                        Text("\(lista.count)").tipo(.texto(16, 600)).foregroundStyle(Color.berenjena300).padding(.bottom, 6)
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 8)
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.berenjena300)
                        TextField("", text: $buscar, prompt: Text("Buscar ejercicio").foregroundColor(.berenjena300))
                            .font(Estilo.texto(16, 400).font()).foregroundStyle(Color.hueso).tint(Color.yema)
                            .autocorrectionDisabled()
                    }
                    .padding(.horizontal, 14).frame(height: 44)
                    .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 16)
                    ScrollView(.horizontal) {
                        HStack(spacing: 8) {
                            Chip(titulo: "Todos", elegido: grupo == nil, sobreBanda: true) { Haptico.seleccion(); withAnimation(.snappy) { grupo = nil } }
                            ForEach(GrupoEjercicio.allCases, id: \.self) { g in
                                Chip(titulo: g.titulo, elegido: grupo == g, sobreBanda: true) { Haptico.seleccion(); withAnimation(.snappy) { grupo = g } }
                            }
                        }
                        .padding(.horizontal, Espacio.margen)
                    }
                    .scrollIndicators(.hidden)
                    .padding(.top, 12)
                }
                if lista.isEmpty {
                    Tarjeta(relleno: 24) {
                        Text("No hay ejercicios con «\(buscar)».").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                        Text("Probá con otra palabra o sacá el filtro.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4)
                    }
                    .padding(Espacio.margen)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                        ForEach(lista) { e in
                            NavigationLink(value: e) { tarjeta(e) }.buttonStyle(Apretable())
                        }
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.immediately)
        .background(Color.hueso.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(for: Ejercicio.self) { e in
            DetalleEjercicio(ejercicio: e, sexo: sexoVista, elegir: elegir.map { f in { f(e); dismiss() } })
        }
    }

    private func tarjeta(_ e: Ejercicio) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            IlustracionEjercicio(ejercicio: e, sexo: sexoVista)
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: Radio.tarjeta, topTrailingRadius: Radio.tarjeta, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Etiqueta(e.grupo.titulo, color: .yema700)
                Text(e.nombre).tipo(.texto(15, 700)).foregroundStyle(Color.tinta).lineLimit(2, reservesSpace: true)
            }
            .padding(12)
        }
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .sombraTarjeta()
        .accessibilityElement(children: .combine)
    }
}

/// Detalle: la ilustración grande, el grupo y, si se está armando una rutina, el botón para sumarlo.
struct DetalleEjercicio: View {
    @Environment(\.dismiss) private var dismiss
    let ejercicio: Ejercicio
    @State var sexo: Sexo
    var elegir: (() -> Void)?
    var cerrable = false

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Banda {
                        NavBanda(atras: cerrable ? nil : "Ejercicios", accionAtras: { dismiss() }) {
                            if cerrable { Redondo(icono: .cerrar, etiqueta: "Cerrar") { dismiss() } }
                        }
                        Etiqueta(ejercicio.grupo.titulo, color: .berenjena300).padding(.horizontal, Espacio.margen).padding(.top, 8)
                        Text(ejercicio.nombre.uppercased(with: Locale(identifier: "es_AR")))
                            .tipo(.titulo(40)).foregroundStyle(Color.hueso)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, Espacio.margen).padding(.top, 8)
                    }
                    IlustracionEjercicio(ejercicio: ejercicio, sexo: sexo)
                        .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                        .sombraTarjeta()
                        .padding(.horizontal, Espacio.margen)
                        .padding(.top, 24)
                        .animation(.easeInOut(duration: 0.25), value: sexo)
                    HStack(spacing: 8) {
                        ForEach([Sexo.mujer, .hombre], id: \.self) { s in
                            Chip(titulo: s.titulo, elegido: sexo == s, elegidoOscuro: true, ancho: true) { Haptico.seleccion(); sexo = s }
                        }
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 16)
                    .padding(.bottom, 120)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.hueso.ignoresSafeArea())
            if let elegir {
                Boton(titulo: "Sumar a la rutina", icono: .mas, variante: .prim, alto: .alto, ancho: true) {
                    Haptico.exito(); elegir()
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.top, 24)
                .background(LinearGradient(stops: [.init(color: .hueso.opacity(0), location: 0), .init(color: .hueso, location: 0.3)],
                                           startPoint: .top, endPoint: .bottom).ignoresSafeArea())
            }
        }
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Ajustes: tu perfil, la biblioteca, cambiar de lado y rehacer el inicio.
struct Ajustes: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lado") private var lado = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    CabezaHoja(etiqueta: estado.perfil.map { $0.lado == .profe ? "Profe" : "Alumno" }, titulo: "Ajustes")
                    if let p = estado.perfil {
                        Tarjeta(relleno: 16) {
                            Text(p.nombre).tipo(.texto(20, 700)).foregroundStyle(Color.tinta)
                            Text(resumen(p)).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 24)
                    }
                    Tarjeta {
                        NavigationLink { Biblioteca(volver: "Ajustes") } label: { fila(.pesa, "Biblioteca de ejercicios") }
                            .buttonStyle(.plain)
                        Divisor()
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) { lado = lado == Lado.profe.rawValue ? Lado.alumno.rawValue : Lado.profe.rawValue }
                            dismiss()
                        } label: { fila(.cambio, lado == Lado.profe.rawValue ? "Ver la app del alumno" : "Ver la app del profe") }
                            .buttonStyle(.plain)
                        Divisor()
                        Button {
                            dismiss()
                            withAnimation(.easeInOut(duration: 0.3)) { estado.borrarPerfil(); lado = "" }
                        } label: { fila(.recarga, "Rehacer el inicio") }
                            .buttonStyle(.plain)
                    }
                    .padding(.top, 12)
                    Text("Otra Más · maqueta").tipo(.texto(12, 600)).foregroundStyle(Color.arena500)
                        .frame(maxWidth: .infinity).padding(.top, 24)
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Color.hueso)
            .toolbar(.hidden, for: .navigationBar)
        }
        .estiloHoja([.medium, .large])
    }

    private func fila(_ i: Icono, _ t: String) -> some View {
        HStack(spacing: 12) {
            IconoVista(i, tamano: 20).foregroundStyle(Color.berenjena800)
                .frame(width: 40, height: 40).background(Color.berenjena100, in: Circle())
            Text(t).tipo(.texto(16, 700)).foregroundStyle(Color.tinta).frame(maxWidth: .infinity, alignment: .leading)
            IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
        }
        .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
    }

    private func resumen(_ p: Perfil) -> String {
        if p.lado == .profe {
            return "\(p.cantidadAlumnos) alumnos · \(p.lugares.map(\.titulo).joined(separator: ", ")) · cobrás con \(p.cobros.map { $0 == .mercadoPago ? $0.rawValue : $0.rawValue.lowercased() }.joined(separator: ", "))"
        }
        return "\(p.edad) años · \(Formato.decimal(p.peso)) kg · \(p.altura) cm · \(p.objetivo?.titulo ?? "") · \(p.diasPorSemana) días por semana"
    }
}
