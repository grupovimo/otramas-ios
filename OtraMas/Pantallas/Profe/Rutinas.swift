import SwiftUI
import PDFKit

// MARK: - Piezas

/// Miniaturas de las ilustraciones de una rutina (hasta 4, con «+N»).
struct MiniaturasRutina: View {
    @Environment(Estado.self) private var estado
    let ids: [String]
    var tamano: CGFloat = 52

    var body: some View {
        HStack(spacing: 8) {
            ForEach(ids.prefix(4), id: \.self) { id in
                if let e = estado.ejercicio(id) {
                    IlustracionEjercicio(ejercicio: e, sexo: estado.sexoIlustracion)
                        .frame(width: tamano, height: tamano)
                        .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
            }
            if ids.count > 4 {
                Text("+\(ids.count - 4)").tipo(.numero(16), alto: 16).foregroundStyle(Color.berenjena800)
                    .frame(width: tamano, height: tamano)
                    .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            }
        }
        .accessibilityHidden(true)
    }
}

/// Avatares encimados de los alumnos (.pila).
struct PilaAvatares: View {
    @Environment(Estado.self) private var estado
    let ids: [String]
    var body: some View {
        HStack(spacing: -6) {
            ForEach(ids.prefix(4), id: \.self) { id in
                if let a = estado.alumno(id) {
                    Iniciales(texto: a.iniciales, tono: a.tono, tamano: 28)
                        .overlay(Circle().stroke(Color.white, lineWidth: 2))
                }
            }
        }
        .accessibilityHidden(true)
    }
}

struct TarjetaRutina: View {
    let rutina: Rutina
    var body: some View {
        Tarjeta(relleno: 16) {
            HStack(alignment: .center) {
                Etiqueta("\(rutina.objetivo) · \(rutina.nivel)", color: .yema700)
                Spacer(minLength: 8)
                if rutina.plantilla {
                    Text("Plantilla").tipo(.texto(12, 700)).foregroundStyle(Color.berenjena800)
                        .padding(.horizontal, 8).frame(height: 24).background(Color.berenjena100, in: Capsule())
                } else if rutina.archivada {
                    Text("Archivada").tipo(.texto(12, 700)).foregroundStyle(Color.arena700)
                        .padding(.horizontal, 8).frame(height: 24).background(Color.arena100, in: Capsule())
                }
            }
            Text(rutina.nombre).tipo(.texto(20, 700)).foregroundStyle(Color.tinta).lineLimit(2).padding(.top, 6)
            Text(rutina.resumen).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 2)
            MiniaturasRutina(ids: rutina.ejerciciosIds).padding(.top, 12)
            Divisor().padding(.top, 14).padding(.horizontal, -16)
            HStack(spacing: 8) {
                if rutina.asignaciones.isEmpty {
                    Text(rutina.plantilla ? "Lista para usar" : "Sin asignar").tipo(.texto(14, 600)).foregroundStyle(Color.texto2)
                } else {
                    PilaAvatares(ids: rutina.asignaciones.map(\.alumnoId))
                    Text("Asignada a \(rutina.asignaciones.count)").tipo(.texto(14, 700)).foregroundStyle(Color.tinta)
                }
                Spacer()
                IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
            }
            .padding(.top, 12)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Lista

/// Pestaña Rutinas: buscador, filtros (Todas · Mías · Plantillas · Archivadas) y las tarjetas.
struct ListaRutinas: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @State private var filtro = Filtro.todas
    @State private var buscar = ""

    enum Filtro: String, CaseIterable { case todas = "Todas", mias = "Mías", plantillas = "Plantillas", archivadas = "Archivadas" }

    private func filtrar(_ l: [Rutina]) -> [Rutina] {
        let q = buscar.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return l }
        return l.filter { $0.nombre.localizedStandardContains(q) || $0.objetivo.localizedStandardContains(q) }
    }

    var body: some View {
        PantallaProfe {
            CabeceraPestana(titulo: "Rutinas") {
                Button { nav.edicion = .nueva } label: {
                    IconoVista(.mas, tamano: 20).foregroundStyle(Color.berenjena800)
                        .frame(width: 44, height: 44).background(Color.yema, in: Circle())
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("Rutina nueva")
            }
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Filtro.allCases, id: \.self) { f in
                        Chip(titulo: f.rawValue, elegido: filtro == f, sobreBanda: true) {
                            Haptico.seleccion(); withAnimation(.snappy(duration: 0.25)) { filtro = f }
                        }
                    }
                }
                .padding(.horizontal, Espacio.margen)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 16)
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.berenjena300)
                TextField("", text: $buscar, prompt: Text("Buscar rutina").foregroundColor(.berenjena300))
                    .font(Estilo.texto(16, 400).font()).foregroundStyle(Color.hueso).tint(Color.yema)
                    .autocorrectionDisabled()
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 12)
        } cuerpo: {
            switch filtro {
            case .todas:
                seccion("Mías", filtrar(estado.rutinasMias), arriba: 0, vacioMias: true)
                seccion("Plantillas", filtrar(estado.plantillas), arriba: 24)
            case .mias: seccion("Mías", filtrar(estado.rutinasMias), arriba: 0, vacioMias: true)
            case .plantillas: seccion("Plantillas", filtrar(estado.plantillas), arriba: 0)
            case .archivadas: seccion("Archivadas", filtrar(estado.rutinasArchivadas), arriba: 0)
            }
        }
        .scrollDismissesKeyboard(.immediately)
    }

    @ViewBuilder
    private func seccion(_ titulo: String, _ lista: [Rutina], arriba: CGFloat, vacioMias: Bool = false) -> some View {
        TituloSeccion(texto: titulo, arriba: arriba) {
            Text("\(lista.count)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
        }
        if lista.isEmpty {
            vacio(titulo, mias: vacioMias)
        } else {
            VStack(spacing: 12) {
                ForEach(lista) { r in
                    NavigationLink(value: DestinoProfe.rutina(r.id)) { TarjetaRutina(rutina: r) }
                        .buttonStyle(Apretable())
                }
            }
        }
    }

    private func vacio(_ titulo: String, mias: Bool) -> some View {
        Tarjeta(relleno: 24) {
            VStack(spacing: 12) {
                if !buscar.isEmpty {
                    Text("No hay rutinas con «\(buscar)»").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                    Text("Probá con otra palabra.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                } else if mias {
                    Image("mas-uno").resizable().scaledToFit().frame(width: 72).accessibilityHidden(true)
                    Text("Todavía no armaste rutinas").tipo(.texto(18, 700)).foregroundStyle(Color.tinta)
                    Text("Empezá de cero o usá una plantilla y la ajustás.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        .multilineTextAlignment(.center)
                    Boton(titulo: "Armar la primera", icono: .mas, variante: .prim, ancho: true) { nav.edicion = .nueva }
                        .padding(.top, 4)
                } else {
                    Text(titulo == "Archivadas" ? "No archivaste ninguna" : "No hay \(titulo.lowercased())").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                    Text(titulo == "Archivadas" ? "Las rutinas que ya no usás quedan acá, sin perderse." : "Pronto sumamos más.")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Detalle

struct DetalleRutina: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @Environment(\.dismiss) private var dismiss
    let rutinaId: String
    @State private var dia = 0

    var body: some View {
        if let r = estado.rutina(rutinaId) {
            contenido(r)
        } else {
            Text("Esta rutina ya no está.").tipo(.texto(16, 600)).foregroundStyle(Color.texto2)
                .frame(maxWidth: .infinity, maxHeight: .infinity).background(Color.hueso)
                .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func contenido(_ r: Rutina) -> some View {
        let d = min(dia, max(r.dias.count - 1, 0))
        return PantallaProfe {
            NavBanda(atras: "Rutinas", accionAtras: { dismiss() }) {
                Menu {
                    if !r.plantilla { Button { nav.edicion = .editar(r.id) } label: { Label("Editar", systemImage: "pencil") } }
                    Button { estado.duplicar(rutina: r.id) } label: { Label("Duplicar", systemImage: "plus.square.on.square") }
                    Button { nav.hoja = .pdfRutina(r.id) } label: { Label("Exportar PDF", systemImage: "doc.richtext") }
                    if !r.plantilla {
                        Button(role: r.archivada ? nil : .destructive) { estado.archivar(rutina: r.id, !r.archivada) } label: {
                            Label(r.archivada ? "Desarchivar" : "Archivar", systemImage: "archivebox")
                        }
                    }
                } label: {
                    IconoVista(.puntos, tamano: 20).foregroundStyle(Color.hueso)
                        .frame(width: 44, height: 44).background(Color.huesoOsc, in: Circle())
                }
                .accessibilityLabel("Más opciones")
            }
            VStack(alignment: .leading, spacing: 8) {
                Etiqueta("\(r.objetivo) · \(r.nivel)", color: .berenjena300)
                Text(r.nombre.uppercased(with: Locale(identifier: "es_AR")))
                    .tipo(.titulo(40)).foregroundStyle(Color.hueso)
                    .fixedSize(horizontal: false, vertical: true)
                Text(r.resumen + (r.asignaciones.isEmpty ? "" : " · asignada a \(r.asignaciones.count)"))
                    .tipo(.texto(14, 400)).foregroundStyle(Color.berenjena300)
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 8)
            // Acciones: la principal (asignar), enviar, y las secundarias.
            HStack(spacing: 8) {
                Boton(titulo: "Asignar", icono: .gente, variante: .yema, alto: .normal, ancho: true) {
                    nav.hoja = .asignarRutina(r.id, [])
                }
                Boton(titulo: "Enviar", icono: .wa, variante: .osc, alto: .normal, ancho: true) { nav.hoja = .enviarRutina(r.id) }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 16)
            HStack(spacing: 8) {
                if r.plantilla {
                    Boton(titulo: "Usar como base", variante: .osc, alto: .chico, ancho: true) {
                        if let id = estado.duplicar(rutina: r.id, nombre: r.nombre, avisando: false) { nav.edicion = .editar(id) }
                    }
                } else {
                    Boton(titulo: "Editar", variante: .osc, alto: .chico, ancho: true) { nav.edicion = .editar(r.id) }
                    Boton(titulo: "Duplicar", variante: .osc, alto: .chico, ancho: true) { estado.duplicar(rutina: r.id) }
                }
                Boton(titulo: "PDF", icono: .recibo, variante: .osc, alto: .chico, ancho: true) { nav.hoja = .pdfRutina(r.id) }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 8)
            if r.dias.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 8) {
                        ForEach(Array(r.dias.enumerated()), id: \.element.id) { i, x in
                            Chip(titulo: x.nombre, elegido: d == i, sobreBanda: true) {
                                Haptico.seleccion(); withAnimation(.snappy(duration: 0.25)) { dia = i }
                            }
                        }
                    }
                    .padding(.horizontal, Espacio.margen)
                }
                .scrollIndicators(.hidden)
                .padding(.top, 16)
            }
        } cuerpo: {
            if let n = r.notas, !n.isEmpty {
                Tarjeta(relleno: 16) {
                    Etiqueta("Notas para tus alumnos")
                    Text(n).tipo(.texto(15, 400)).foregroundStyle(Color.tinta).padding(.top, 6)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, 12)
            }
            if r.dias.isEmpty || r.dias[d].ejercicios.isEmpty {
                Tarjeta(relleno: 24) {
                    Text("Este día no tiene ejercicios").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                    Boton(titulo: "Editar la rutina", variante: .prim, ancho: true) { nav.edicion = .editar(r.id) }.padding(.top, 12)
                }
            } else {
                let ej = r.dias[d].ejercicios
                Tarjeta {
                    ForEach(Array(ej.enumerated()), id: \.element.id) { i, e in
                        if i > 0 { Divisor() }
                        filaEjercicio(e, i, ej.count)
                    }
                }
            }
            TituloSeccion(texto: "Asignada a") {
                Text("\(r.asignaciones.count)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            if r.asignaciones.isEmpty {
                Tarjeta(relleno: 20) {
                    Text(r.plantilla ? "Al asignarla, se copia a Mías para que la puedas ajustar." : "Todavía no se la diste a nadie.")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    Boton(titulo: "Asignar", icono: .gente, variante: .prim, ancho: true) { nav.hoja = .asignarRutina(r.id, []) }
                        .padding(.top, 12)
                }
            } else {
                Tarjeta {
                    ForEach(Array(r.asignaciones.enumerated()), id: \.element.alumnoId) { i, a in
                        if let al = estado.alumno(a.alumnoId) {
                            if i > 0 { Divisor() }
                            NavigationLink(value: DestinoProfe.ficha(al.id)) {
                                HStack(spacing: 12) {
                                    Iniciales(texto: al.iniciales, tono: al.tono, tamano: 40)
                                    NomSub(nombre: al.nombre, sub: Text("Desde el \(Fecha.corta(a.desde))"))
                                    IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12).frame(minHeight: 64).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            if !r.plantilla {
                Button { estado.archivar(rutina: r.id, !r.archivada) } label: {
                    Text(r.archivada ? "Volver a Mías" : "Archivar rutina").tipo(.texto(15, 700))
                        .foregroundStyle(r.archivada ? Color.berenjena800 : Color.error)
                        .frame(maxWidth: .infinity).frame(height: 48)
                }
                .buttonStyle(Apretable())
                .padding(.top, 16)
            }
        }
    }

    private func filaEjercicio(_ e: EjercicioDeRutina, _ i: Int, _ total: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Group {
                if let ej = estado.ejercicio(e.ejercicioId) {
                    IlustracionEjercicio(ejercicio: ej, sexo: estado.sexoIlustracion)
                } else {
                    FotoRecortada(nombre: e.foto, foco: UnitPoint(x: e.focoX, y: e.focoY))
                }
            }
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            VStack(alignment: .leading, spacing: 4) {
                Etiqueta("\(i + 1) de \(total)", color: .yema700)
                Text(e.nombre).tipo(.texto(17, 700)).foregroundStyle(Color.tinta)
                Text("\(e.resumen) · pausa \(Formato.pausa(e.pausa))").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                if let n = e.notas {
                    Text(n).tipo(.texto(13, 400)).italic().foregroundStyle(Color.arena700)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Asignar

struct HojaAsignarRutina: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let rutinaId: String
    var preelegidos: [String] = []
    @State private var elegidos: Set<String> = []
    @State private var buscar = ""
    @State private var desde = Fecha.fecha("2026-11-30")
    @State private var reemplaza = true

    var body: some View {
        let r = estado.rutina(rutinaId)
        let lista = estado.alumnos.filter { buscar.isEmpty || $0.nombre.localizedStandardContains(buscar) }
            .sorted { (preelegidos.contains($0.id) ? 0 : 1, $0.nombre) < (preelegidos.contains($1.id) ? 0 : 1, $1.nombre) }
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: r?.nombre, titulo: "Asignar rutina")
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").font(.system(size: 16, weight: .semibold)).foregroundStyle(Color.arena500)
                TextField("", text: $buscar, prompt: Text("Buscar alumno").foregroundColor(.arena500))
                    .font(Estilo.texto(16, 400).font()).foregroundStyle(Color.tinta).autocorrectionDisabled()
            }
            .padding(.horizontal, 14).frame(height: 44)
            .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .padding(.top, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Tarjeta {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(lista.enumerated()), id: \.element.id) { i, a in
                                if i > 0 { Divisor() }
                                fila(a)
                            }
                        }
                    }
                    .padding(.top, 12)
                    Tarjeta {
                        DatePicker(selection: $desde, displayedComponents: .date) {
                            Text("Empieza el").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                        }
                        .tint(Color.berenjena800)
                        .environment(\.locale, Locale(identifier: "es_AR"))
                        .padding(.horizontal, 16).frame(minHeight: 64)
                        Divisor()
                        Toggle(isOn: $reemplaza) {
                            NomSub(nombre: "Reemplaza su rutina actual", sub: Text(reemplaza ? "Dejan la que tenían" : "La suman a la que ya tienen"))
                        }
                        .tint(Color.ok)
                        .padding(.horizontal, 16).frame(minHeight: 72)
                    }
                    .padding(.top, 12)
                    if r?.plantilla == true {
                        Text("Es una plantilla: se copia a Mías y la podés ajustar después.")
                            .tipo(.texto(13, 400)).foregroundStyle(Color.texto2).padding(.top, 12)
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.immediately)
            Boton(titulo: elegidos.isEmpty ? "Elegí a quiénes" : "Asignar a \(elegidos.count)", icono: .gente, variante: .prim, alto: .alto, ancho: true) {
                estado.asignar(rutina: rutinaId, a: Array(elegidos), desde: Fecha.iso(desde), reemplaza: reemplaza)
                dismiss()
            }
            .disabled(elegidos.isEmpty)
            .opacity(elegidos.isEmpty ? 0.45 : 1)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .onAppear { elegidos = Set(preelegidos) }
    }

    private func fila(_ a: Alumno) -> some View {
        let on = elegidos.contains(a.id)
        let actual = estado.rutinaActual(de: a.id)
        return Button {
            Haptico.seleccion()
            if on { elegidos.remove(a.id) } else { elegidos.insert(a.id) }
        } label: {
            HStack(spacing: 12) {
                Iniciales(texto: a.iniciales, tono: a.tono, tamano: 40)
                VStack(alignment: .leading, spacing: 0) {
                    Text(a.nombre).tipo(.texto(16, 700)).foregroundStyle(Color.tinta).lineLimit(1)
                    Text(actual.map { "Ahora: \($0.rutina.nombre)" } ?? "Sin rutina")
                        .tipo(.texto(14, actual == nil ? 600 : 400))
                        .foregroundStyle(actual == nil ? Color.yema700 : Color.texto2).lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                IconoVista(.tilde, tamano: 18, grosor: 2.6)
                    .foregroundStyle(on ? Color.yema : Color.clear)
                    .frame(width: 28, height: 28)
                    .background(on ? Color.berenjena800 : Color.clear, in: RoundedRectangle(cornerRadius: 8))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(on ? Color.clear : Color.arena300, lineWidth: 2))
            }
            .padding(.horizontal, 16).padding(.vertical, 12).frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(a.nombre)
        .accessibilityValue(actual.map { "Ahora tiene \($0.rutina.nombre)" } ?? "Sin rutina")
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// Elegir una rutina para uno o varios alumnos (desde la ficha o «Sin rutina» en Inicio).
struct HojaElegirRutina: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let alumnoIds: [String]

    var body: some View {
        let nombres = alumnoIds.compactMap { estado.alumno($0)?.primerNombre }
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Para \(lista(nombres))", titulo: "Elegí una rutina")
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach([("Mías", estado.rutinasMias), ("Plantillas", estado.plantillas)], id: \.0) { titulo, rutinas in
                        TituloSeccion(titulo)
                        VStack(spacing: 8) {
                            ForEach(rutinas) { r in
                                Button {
                                    estado.asignar(rutina: r.id, a: alumnoIds, desde: estado.hoy, reemplaza: true)
                                    dismiss()
                                } label: {
                                    HStack(spacing: 12) {
                                        MiniaturasRutina(ids: Array(r.ejerciciosIds.prefix(1)), tamano: 56)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(r.nombre).tipo(.texto(16, 700)).foregroundStyle(Color.tinta).lineLimit(1)
                                            Text("\(r.objetivo) · \(r.resumen)").tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(1)
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
                                    }
                                    .padding(12)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                                    .sombraTarjeta()
                                }
                                .buttonStyle(Apretable())
                            }
                        }
                    }
                }
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
    }
}

func lista(_ n: [String]) -> String {
    switch n.count {
    case 0: return "tus alumnos"
    case 1: return n[0]
    default: return n.dropLast().joined(separator: ", ") + " y " + n.last!
    }
}

// MARK: - Enviar

struct HojaEnviarRutina: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let rutinaId: String

    var body: some View {
        if let r = estado.rutina(rutinaId) {
            let texto = "¡Hola! Te paso la rutina «\(r.nombre)» (\(r.resumen)). La ves completa, con cómo se hace cada ejercicio, acá: \(r.link.absoluteString)\n— \(estado.profe.profe.nombre), Otra Más"
            let asignados = r.asignaciones.compactMap { estado.alumno($0.alumnoId) }
            VStack(alignment: .leading, spacing: 0) {
                CabezaHoja(etiqueta: r.nombre, titulo: "Enviar rutina")
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Etiqueta("Así llega").padding(.top, 24).padding(.bottom, 8)
                        VStack(alignment: .leading, spacing: 8) {
                            Text(texto).tipo(.texto(15, 400)).foregroundStyle(Color.tinta).fixedSize(horizontal: false, vertical: true)
                            HStack(spacing: 10) {
                                MiniaturasRutina(ids: Array(r.ejerciciosIds.prefix(1)), tamano: 44)
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(r.nombre).tipo(.texto(14, 700)).foregroundStyle(Color.tinta)
                                    Text("otramas.com.ar").tipo(.texto(12, 400)).foregroundStyle(Color.texto2)
                                }
                            }
                            .padding(8).frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.arena50, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                        }
                        .padding(14)
                        .background(Color(hex: 0xE3F7DB), in: UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 18, bottomTrailingRadius: 4, topTrailingRadius: 18, style: .continuous))
                        ShareLink(item: r.link, subject: Text(r.nombre), message: Text(texto)) {
                            HStack(spacing: 8) {
                                IconoVista(.wa, tamano: 20).foregroundStyle(Color.yema)
                                Text("Por WhatsApp o donde quieras").tipo(.texto(16, 700))
                            }
                            .foregroundStyle(Color.hueso)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                        }
                        .buttonStyle(Apretable())
                        .padding(.top, 16)

                        TituloSeccion(texto: "A sus alumnos asignados") {
                            Text("\(asignados.count)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                        if asignados.isEmpty {
                            Tarjeta(relleno: 16) {
                                Text("Todavía no la asignaste. Asignala y se la mandamos a cada uno.")
                                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                            }
                        } else {
                            Tarjeta(relleno: 16) {
                                HStack(spacing: 12) {
                                    PilaAvatares(ids: asignados.map(\.id))
                                    Text(lista(asignados.map(\.primerNombre))).tipo(.texto(14, 600)).foregroundStyle(Color.tinta)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Text("Les llega por WhatsApp desde el número de Otra Más, con tu nombre.")
                                    .tipo(.texto(13, 400)).foregroundStyle(Color.texto2).padding(.top, 8)
                                Boton(titulo: "Mandar a los \(asignados.count)", icono: .wa, variante: .yema, ancho: true) {
                                    estado.enviar(rutina: r.id, a: asignados.map(\.id))
                                    dismiss()
                                }
                                .padding(.top, 12)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .padding(.horizontal, Espacio.margen)
            .estiloHoja()
        }
    }
}

// MARK: - PDF

struct HojaPDFRutina: View {
    @Environment(Estado.self) private var estado
    let rutinaId: String
    @State private var url: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: estado.rutina(rutinaId)?.nombre, titulo: "Exportar PDF")
            Group {
                if let url {
                    VistaPDF(url: url)
                        .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                        .sombraTarjeta()
                } else {
                    ProgressView().tint(Color.berenjena800).frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .padding(.top, 16)
            if let url {
                ShareLink(item: url) {
                    HStack(spacing: 8) {
                        IconoVista(.recibo, tamano: 20).foregroundStyle(Color.yema)
                        Text("Compartir PDF").tipo(.texto(16, 700))
                    }
                    .foregroundStyle(Color.hueso)
                    .frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
                .buttonStyle(Apretable())
                .padding(.top, 16)
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .task {
            if let r = estado.rutina(rutinaId) {
                url = PDFRutina.generar(r, profe: estado.profe.profe.nombre, sexo: estado.sexoIlustracion, ejercicios: estado.ejercicios)
            }
        }
    }
}

struct VistaPDF: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> PDFView {
        let v = PDFView()
        v.autoScales = true
        v.displayMode = .singlePageContinuous
        v.backgroundColor = UIColor(Color.arena50)
        v.document = PDFDocument(url: url)
        return v
    }
    func updateUIView(_ v: PDFView, context: Context) {}
}

/// PDF de la rutina en A4: marca, nombre, por día una tabla con ilustración, series × reps, kilos, pausa y notas.
enum PDFRutina {
    static let tamano = CGSize(width: 595, height: 842)

    enum Bloque: Hashable {
        case dia(String)
        case fila(EjercicioDeRutina, Int)
        var alto: CGFloat { if case .dia = self { return 52 }; return 58 }
    }

    @MainActor
    static func generar(_ r: Rutina, profe: String, sexo: Sexo, ejercicios: [Ejercicio], en destino: URL? = nil) -> URL? {
        // Bloques y páginas.
        var bloques: [Bloque] = []
        for d in r.dias {
            bloques.append(.dia(d.nombre))
            for (i, e) in d.ejercicios.enumerated() { bloques.append(.fila(e, i + 1)) }
        }
        var paginas: [[Bloque]] = [[]]
        var usado: CGFloat = 0
        let primera: CGFloat = 842 - 40 - 250 - 60, resto: CGFloat = 842 - 40 - 70 - 60
        for b in bloques {
            let cabe = (paginas.count == 1 ? primera : resto)
            // Un título de día no queda solo al pie.
            let necesita = b.alto + (b.alto == 52 ? 58 : 0)
            if usado + necesita > cabe && !paginas[paginas.count - 1].isEmpty { paginas.append([]); usado = 0 }
            paginas[paginas.count - 1].append(b)
            usado += b.alto
        }
        let nombre = r.nombre.replacingOccurrences(of: "/", with: "-")
        let url = destino ?? FileManager.default.temporaryDirectory.appendingPathComponent("Rutina \(nombre).pdf")
        var caja = CGRect(origin: .zero, size: tamano)
        guard let ctx = CGContext(url as CFURL, mediaBox: &caja, [kCGPDFContextTitle: r.nombre, kCGPDFContextCreator: "Otra Más"] as CFDictionary) else { return nil }
        for (i, p) in paginas.enumerated() {
            let vista = PaginaPDF(rutina: r, bloques: p, numero: i + 1, total: paginas.count, profe: profe, sexo: sexo, ejercicios: ejercicios)
                .frame(width: tamano.width, height: tamano.height)
                .environment(\.dynamicTypeSize, .large)
            let render = ImageRenderer(content: vista)
            render.proposedSize = ProposedViewSize(tamano)
            render.render { _, dibujar in
                ctx.beginPDFPage(nil)
                dibujar(ctx)
                ctx.endPDFPage()
            }
        }
        ctx.closePDF()
        return url
    }
}

private struct PaginaPDF: View {
    let rutina: Rutina
    let bloques: [PDFRutina.Bloque]
    let numero: Int
    let total: Int
    let profe: String
    let sexo: Sexo
    let ejercicios: [Ejercicio]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Marca
            HStack(spacing: 8) {
                Image("mas-uno").resizable().scaledToFit().frame(width: 34)
                Text("OTRA MÁS").font(Estilo.titulo(20).font()).foregroundStyle(Color.berenjena800)
                Spacer()
                Text(numero == 1 ? "RUTINA DE ENTRENAMIENTO" : rutina.nombre.uppercased())
                    .font(Estilo.etiqueta.font()).tracking(0.84).foregroundStyle(Color.arena600)
            }
            if numero == 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(rutina.objetivo) · \(rutina.nivel)".uppercased()).font(Estilo.etiqueta.font()).tracking(0.84).foregroundStyle(Color.berenjena300)
                    Text(rutina.nombre.uppercased()).font(Estilo.titulo(36).font()).foregroundStyle(Color.hueso).lineLimit(2)
                    Text(rutina.resumen).font(Estilo.texto(12, 400).font()).foregroundStyle(Color.berenjena300)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(alignment: .topTrailing) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.yema).frame(width: 56, height: 6).padding(20)
                }
                .padding(.top, 16)
                if let n = rutina.notas {
                    HStack(alignment: .top, spacing: 8) {
                        RoundedRectangle(cornerRadius: 2).fill(Color.yema).frame(width: 4)
                        Text(n).font(Estilo.texto(11, 400).font()).foregroundStyle(Color.arena700).fixedSize(horizontal: false, vertical: true)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(bloques.enumerated()), id: \.offset) { _, b in
                    switch b {
                    case .dia(let nombre):
                        HStack {
                            Text(nombre.uppercased()).font(Estilo.titulo(18).font()).foregroundStyle(Color.berenjena800)
                            Spacer()
                            columna("SERIES × REPS", 86)
                            columna("KILOS", 54)
                            columna("PAUSA", 50)
                        }
                        .frame(height: 30)
                        .padding(.top, 14)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color.berenjena800).frame(height: 1.5) }
                        .padding(.bottom, 6)
                    case .fila(let e, let i):
                        HStack(spacing: 10) {
                            Group {
                                if let ej = ejercicios.first(where: { $0.id == e.ejercicioId }), let img = ej.imagen(para: sexo) {
                                    Image(uiImage: img).resizable().scaledToFit()
                                } else { Color.arena50 }
                            }
                            .frame(width: 42, height: 42)
                            .background(Color(hex: 0xFAF7F2))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(i). \(e.nombre)").font(Estilo.texto(12, 700).font()).foregroundStyle(Color.tinta)
                                if let n = e.notas {
                                    Text(n).font(Estilo.texto(9, 400).font()).italic().foregroundStyle(Color.arena600).lineLimit(2)
                                }
                            }
                            Spacer(minLength: 6)
                            valor("\(Int(e.series)) × \(Int(e.reps))\(e.porTiempo ? " s" : "")", 86)
                            valor(e.kilos > 0 ? "\(Formato.decimal(e.kilos)) kg" : "—", 54)
                            valor(Formato.pausa(e.pausa), 50)
                        }
                        .frame(height: 52)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color.arena100).frame(height: 1) }
                    }
                }
            }
            .padding(.top, 8)
            Spacer(minLength: 0)
            // Pie
            HStack {
                Text("Profe: \(profe)").font(Estilo.texto(10, 700).font()).foregroundStyle(Color.tinta)
                Text("·  \(rutina.link.absoluteString.replacingOccurrences(of: "https://", with: ""))").font(Estilo.texto(10, 400).font()).foregroundStyle(Color.arena600)
                Spacer()
                Text("Página \(numero) de \(total)").font(Estilo.texto(10, 400).font()).foregroundStyle(Color.arena600)
            }
            .padding(.top, 10)
            .overlay(alignment: .top) { Rectangle().fill(Color.arena100).frame(height: 1) }
        }
        .padding(.horizontal, 40)
        .padding(.vertical, 36)
        .background(Color.white)
    }

    private func columna(_ t: String, _ w: CGFloat) -> some View {
        Text(t).font(Estilo.texto(8, 700).font()).tracking(0.6).foregroundStyle(Color.arena600).frame(width: w, alignment: .trailing)
    }

    private func valor(_ t: String, _ w: CGFloat) -> some View {
        Text(t).font(Estilo.numero(15).font()).foregroundStyle(Color.berenjena800).frame(width: w, alignment: .trailing)
    }
}
