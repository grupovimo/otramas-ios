import SwiftUI
import PhotosUI
import MapKit
import CoreImage.CIFilterBuiltins

// MARK: - Piezas

/// La foto del profe: la subida, la de muestra o sus iniciales.
struct FotoPerfil: View {
    let perfil: PerfilProfe
    var tamano: CGFloat = 88
    var body: some View {
        Group {
            if let d = perfil.foto, let i = UIImage(data: d) {
                Image(uiImage: i).resizable().scaledToFill().frame(width: tamano, height: tamano)
            } else if let a = perfil.fotoAsset {
                FotoRedonda(nombre: a, tamano: tamano)
            } else {
                Text(perfil.nombre.split(separator: " ").prefix(2).compactMap { $0.first.map(String.init) }.joined())
                    .font(Estilo.titulo(tamano * 0.4).font()).foregroundStyle(Color.berenjena800)
                    .frame(width: tamano, height: tamano).background(Color.yema)
            }
        }
        .clipShape(Circle())
        .accessibilityHidden(true)
    }
}

struct Portada: View {
    let perfil: PerfilProfe
    var body: some View {
        Group {
            if let d = perfil.portada, let i = UIImage(data: d) {
                Image(uiImage: i).resizable().scaledToFill()
            } else if let a = perfil.portadaAsset {
                FotoRecortada(nombre: a, foco: UnitPoint(x: 0.5, y: 0.5))
            } else {
                ZStack {
                    LinearGradient(colors: [Color.berenjena700, Color.berenjena800], startPoint: .topLeading, endPoint: .bottomTrailing)
                    Image("mas-uno").resizable().scaledToFit().frame(width: 72).opacity(0.25).rotationEffect(.degrees(-8))
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

struct Estrellas: View {
    let valor: Double
    var tamano: CGFloat = 14
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { i in
                Image(systemName: Double(i) + 0.75 <= valor ? "star.fill" : Double(i) + 0.25 <= valor ? "star.leadinghalf.filled" : "star")
                    .font(.system(size: tamano, weight: .semibold))
                    .foregroundStyle(Color.yema)
            }
        }
        .accessibilityLabel("\(Formato.decimal((valor * 10).rounded() / 10)) de 5 estrellas")
    }
}

/// Chips en fondo claro (elegido: berenjena con letra hueso).
struct ChipsClaros: View {
    let opciones: [String]
    let elegidas: Set<String>
    var tocar: (String) -> Void
    var body: some View {
        Fluir(espacio: 8) {
            ForEach(opciones, id: \.self) { o in
                let on = elegidas.contains(o)
                Button { Haptico.seleccion(); tocar(o) } label: {
                    HStack(spacing: 6) {
                        if on { IconoVista(.tilde, tamano: 14, grosor: 3).foregroundStyle(Color.yema) }
                        Text(o).tipo(.texto(15, 700))
                    }
                    .foregroundStyle(on ? Color.hueso : Color.berenjena800)
                    .padding(.horizontal, 16).frame(height: 44)
                    .background(on ? Color.berenjena800 : Color.berenjena100, in: Capsule())
                }
                .buttonStyle(Apretable())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// Campo de texto claro con etiqueta.
struct Campo: View {
    let etiqueta: String
    @Binding var texto: String
    var ejemplo: String = ""
    var prefijo: String? = nil
    var teclado: UIKeyboardType = .default
    var varias = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Etiqueta(etiqueta)
            HStack(spacing: 2) {
                if let prefijo { Text(prefijo).tipo(.texto(16, 400)).foregroundStyle(Color.arena500) }
                if varias {
                    TextField("", text: $texto, prompt: Text(ejemplo).foregroundColor(.arena500), axis: .vertical)
                        .lineLimit(3...8)
                } else {
                    TextField("", text: $texto, prompt: Text(ejemplo).foregroundColor(.arena500))
                        .keyboardType(teclado)
                }
            }
            .font(Estilo.texto(16, 600).font())
            .foregroundStyle(Color.tinta)
            .tint(Color.berenjena800)
            .padding(.horizontal, 16).padding(.vertical, varias ? 14 : 0)
            .frame(minHeight: 52)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous).strokeBorder(Color.arena200, lineWidth: 1))
        }
    }
}

/// Achica una foto elegida a 900 px en JPG (para no guardar fotos de 12 MP).
func achicar(_ d: Data, lado: CGFloat = 900) -> Data? {
    guard let i = UIImage(data: d) else { return nil }
    let e = min(1, lado / max(i.size.width, i.size.height))
    let t = CGSize(width: i.size.width * e, height: i.size.height * e)
    return UIGraphicsImageRenderer(size: t).image { _ in i.draw(in: CGRect(origin: .zero, size: t)) }.jpegData(compressionQuality: 0.82)
}

enum DestinoPerfil: Hashable {
    case seccion(SeccionPerfil)
    case asiTeVen
}

// MARK: - Tu perfil

/// «Tu perfil»: cómo está, qué falta, cada sección para editar, la vista pública, el QR y el directorio.
struct TuPerfil: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State private var camino: [DestinoPerfil]
    @State private var qr: Bool
    @State private var ajustes = false

    init(inicial: DestinoPerfil? = nil, qr: Bool = false) {
        _camino = State(initialValue: inicial.map { [$0] } ?? [])
        _qr = State(initialValue: qr)
    }

    var body: some View {
        let p = estado.perfilProfe
        NavigationStack(path: $camino) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Banda {
                        HStack {
                            Button("Cerrar") { dismiss() }.font(Estilo.texto(16, 600).font()).foregroundStyle(Color.hueso).frame(height: 44)
                            Spacer()
                            ShareLink(item: p.link, subject: Text(p.nombreProfesional), message: Text(p.frase)) {
                                Image(systemName: "square.and.arrow.up").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.hueso)
                                    .frame(width: 44, height: 44).background(Color.huesoOsc, in: Circle())
                            }
                            .accessibilityLabel("Compartir tu perfil")
                        }
                        .padding(.horizontal, Espacio.margen)
                        .padding(.top, 8)
                        ZStack(alignment: .bottomLeading) {
                            Portada(perfil: p)
                                .frame(height: 132)
                                .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                                .padding(.bottom, 40)
                            FotoPerfil(perfil: p, tamano: 88)
                                .overlay(Circle().stroke(Color.berenjena800, lineWidth: 4))
                                .padding(.leading, 16)
                        }
                        .padding(.horizontal, Espacio.margen)
                        .padding(.top, 8)
                        VStack(alignment: .leading, spacing: 4) {
                            Titulo(p.nombre, tamano: 36, color: .hueso)
                            Text(p.nombreProfesional).tipo(.texto(15, 600)).foregroundStyle(Color.berenjena300)
                            Text("otramas.com.ar/\(p.usuario)").tipo(.texto(14, 700)).foregroundStyle(Color.yema).padding(.top, 4)
                        }
                        .padding(.horizontal, Espacio.margen)
                        .padding(.top, 12)
                        HStack(spacing: 8) {
                            NavigationLink(value: DestinoPerfil.asiTeVen) {
                                etiquetaBoton("Así te ven", .gente, fondo: .yema, frente: .berenjena800)
                            }
                            Button { qr = true } label: {
                                HStack(spacing: 8) { Image(systemName: "qrcode").font(.system(size: 18, weight: .semibold)); Text("QR").tipo(.texto(16, 700)) }
                                    .foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 48)
                                    .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                            }
                                .frame(width: 104)
                        }
                        .buttonStyle(Apretable())
                        .padding(.horizontal, Espacio.margen)
                        .padding(.top, 16)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        completitud(p)
                        logros
                        TituloSeccion("Tu perfil")
                        Tarjeta {
                            ForEach(Array(SeccionPerfil.allCases.enumerated()), id: \.element) { i, s in
                                if i > 0 { Divisor() }
                                NavigationLink(value: DestinoPerfil.seccion(s)) { filaSeccion(s, p) }.buttonStyle(.plain)
                            }
                        }
                        directorio
                        Tarjeta {
                            NavigationLink { TuPlan() } label: {
                                HStack(spacing: 12) {
                                    IconoVista(.rayo, tamano: 20).foregroundStyle(Color.berenjena800)
                                        .frame(width: 40, height: 40).background(Color.yema, in: Circle())
                                    NomSub(nombre: "Tu plan de Otra Más", sub: Text(estado.enPrueba ? "Pro · te quedan \(estado.diasDePrueba) días de prueba" : estado.suscripcion.plan.nombre))
                                    IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
                                }
                                .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            Divisor()
                            Button { ajustes = true } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "gearshape").font(.system(size: 18, weight: .semibold)).foregroundStyle(Color.berenjena800)
                                        .frame(width: 40, height: 40).background(Color.berenjena100, in: Circle())
                                    Text("Ajustes de la app").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
                                }
                                .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 24)
                    .padding(.bottom, 40)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.hueso.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: DestinoPerfil.self) { d in
                switch d {
                case .seccion(let s): EditarSeccionPerfil(seccion: s)
                case .asiTeVen: AsiTeVen(qr: $qr)
                }
            }
        }
        .sheet(isPresented: $qr) { QRPerfil() }
        .sheet(isPresented: $ajustes) { Ajustes() }
    }

    private func etiquetaBoton(_ t: String, _ i: Icono, fondo: Color, frente: Color) -> some View {
        HStack(spacing: 8) { IconoVista(i, tamano: 20); Text(t).tipo(.texto(16, 700)) }
            .foregroundStyle(frente)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(fondo, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
    }

    private func completitud(_ p: PerfilProfe) -> some View {
        Tarjeta(relleno: 16) {
            HStack(alignment: .firstTextBaseline) {
                Titulo(p.completitud == 100 ? "Tu perfil está completo" : "Tu perfil está al \(p.completitud) %", tamano: 20)
                Spacer()
            }
            BarraProgreso(fraccion: Double(p.completitud) / 100).padding(.top, 12)
            if p.pendientes.isEmpty {
                Text("Así lo ven tus alumnos. Compartilo en Instagram con el QR.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 10)
            } else {
                Text("Te falta:").tipo(.texto(14, 600)).foregroundStyle(Color.texto2).padding(.top, 12)
                ForEach(p.pendientes.prefix(4), id: \.0) { t, s in
                    NavigationLink(value: DestinoPerfil.seccion(s)) {
                        HStack(spacing: 10) {
                            Circle().strokeBorder(Color.arena300, lineWidth: 2).frame(width: 20, height: 20)
                            Text(t).tipo(.texto(15, 600)).foregroundStyle(Color.tinta).frame(maxWidth: .infinity, alignment: .leading)
                            Text("Completar").tipo(.texto(14, 700)).foregroundStyle(Color.yema700)
                        }
                        .frame(minHeight: 44).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var logros: some View {
        let l = estado.logrosProfe
        return HStack(spacing: 12) {
            dato("\(l.anios)", "años entrenando")
            dato("\(l.alumnos)", "alumnos activos")
            dato(Formato.miles(l.clases), "clases dadas")
        }
        .padding(.top, 12)
    }

    private func dato(_ n: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(n).tipo(.numero(28), alto: 28).foregroundStyle(Color.berenjena800)
            Text(l).tipo(.texto(13, 600)).foregroundStyle(Color.arena700).fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .sombraTarjeta()
        .accessibilityElement(children: .combine)
    }

    private func filaSeccion(_ s: SeccionPerfil, _ p: PerfilProfe) -> some View {
        let falta = p.pendientes.contains { $0.1 == s }
        return HStack(spacing: 12) {
            IconoVista(s.icono, tamano: 20).foregroundStyle(Color.berenjena800)
                .frame(width: 40, height: 40).background(Color.berenjena100, in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(s.titulo).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                Text(resumen(s, p)).tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if falta { Circle().fill(Color.yema).frame(width: 8, height: 8).accessibilityLabel("Falta completar") }
            IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
        }
        .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
    }

    private func resumen(_ s: SeccionPerfil, _ p: PerfilProfe) -> String {
        switch s {
        case .fotos: return (p.portada == nil && p.portadaAsset == nil) ? "Falta la portada" : "Foto y portada listas"
        case .basicos: return "@\(p.usuario) · \(p.frase)"
        case .especialidades: return p.especialidades.joined(separator: ", ")
        case .formacion: return "\(p.certificaciones.count) títulos y cursos"
        case .lugares: return p.lugares.map(\.tipo.titulo).joined(separator: ", ")
        case .precios: return p.precios.filter(\.activo).map { "\($0.modalidad.rawValue) desde \(Formato.plata($0.desde))" }.joined(separator: " · ")
        case .horarios: return "\(estado.profe.horario.count) clases por semana"
        case .contacto: return [p.telefono, p.instagram].filter { !$0.isEmpty }.joined(separator: " · ")
        case .galeria: return "\(p.galeria.count + p.galeriaSubida.count) fotos"
        case .resenas: return p.resenas.isEmpty ? "Todavía no tenés" : "\(Formato.decimal((p.promedio * 10).rounded() / 10)) ★ · \(p.resenas.count) reseñas"
        }
    }

    private var directorio: some View {
        @Bindable var estado = estado
        return Tarjeta(relleno: 16) {
            Toggle(isOn: $estado.perfilProfe.enDirectorio) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("Aparecer en el directorio").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                        Text("Pronto").tipo(.texto(11, 700)).foregroundStyle(Color.yema700)
                            .padding(.horizontal, 8).frame(height: 22).background(Color.yema100, in: Capsule())
                    }
                    Text("Otra Más va a tener un buscador de profes por barrio y especialidad. Si lo activás, aparecés cuando arranque.")
                        .tipo(.texto(13, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(Color.ok)
        }
        .padding(.top, 12)
    }
}

// MARK: - Editar una sección

struct EditarSeccionPerfil: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let seccion: SeccionPerfil
    @State private var foto: PhotosPickerItem?
    @State private var portada: PhotosPickerItem?
    @State private var galeria: [PhotosPickerItem] = []
    @State private var certificado: PhotosPickerItem?
    @State private var nuevoTitulo = ""
    @State private var nuevaInstitucion = ""
    @State private var nuevoAnio = ""
    @State private var nuevoCertificado: Data?
    @State private var nuevoBarrio = ""
    @State private var nuevaEspecialidad = ""
    @State private var nuevaClase = false

    var body: some View {
        @Bindable var estado = estado
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Banda {
                    NavBanda(atras: "Tu perfil", accionAtras: { dismiss() }) { EmptyView() }
                    Titulo(seccion.titulo, tamano: 36, color: .hueso)
                        .padding(.horizontal, Espacio.margen).padding(.top, 8)
                }
                VStack(alignment: .leading, spacing: 16) {
                    editor($estado.perfilProfe)
                }
                .padding(.horizontal, Espacio.margen)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .scrollIndicators(.hidden)
        .scrollDismissesKeyboard(.interactively)
        .background(Color.hueso.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .bottom) {
            Boton(titulo: "Listo", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                estado.guardar(perfilProfe: estado.perfilProfe)
                dismiss()
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 12)
            .background(LinearGradient(stops: [.init(color: .hueso.opacity(0), location: 0), .init(color: .hueso, location: 0.3)],
                                       startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
        .onChange(of: foto) { _, i in cargar(i) { estado.perfilProfe.foto = $0 } }
        .onChange(of: portada) { _, i in cargar(i, lado: 1400) { estado.perfilProfe.portada = $0 } }
        .onChange(of: certificado) { _, i in cargar(i) { nuevoCertificado = $0 } }
        .onChange(of: galeria) { _, items in
            for i in items { cargar(i) { estado.perfilProfe.galeriaSubida.append($0) } }
            galeria = []
        }
        .sheet(isPresented: $nuevaClase) { HojaNuevaClase(fecha: estado.hoy) }
    }

    private func cargar(_ i: PhotosPickerItem?, lado: CGFloat = 900, _ listo: @escaping (Data) -> Void) {
        guard let i else { return }
        Task {
            if let d = try? await i.loadTransferable(type: Data.self), let chica = achicar(d, lado: lado) {
                withAnimation(.snappy) { listo(chica) }
            }
        }
    }

    @ViewBuilder
    private func editor(_ p: Binding<PerfilProfe>) -> some View {
        switch seccion {
        case .fotos:
            Tarjeta(relleno: 20) {
                VStack(spacing: 16) {
                    FotoPerfil(perfil: p.wrappedValue, tamano: 140)
                        .overlay(Circle().stroke(Color.yema, lineWidth: 4))
                    PhotosPicker(selection: $foto, matching: .images) {
                        botonPicker("Cambiar foto de perfil")
                    }
                    Text("Se recorta en círculo. Que se vea tu cara, con buena luz.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
            Tarjeta(relleno: 20) {
                Etiqueta("Portada")
                Portada(perfil: p.wrappedValue).frame(height: 150)
                    .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous)).padding(.top, 8)
                PhotosPicker(selection: $portada, matching: .images) { botonPicker(p.wrappedValue.portada == nil ? "Sumar portada" : "Cambiar portada") }
                    .padding(.top, 12)
                Text("Una foto de tus clases, horizontal. Va arriba de tu perfil.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2).padding(.top, 8)
            }
        case .basicos:
            Campo(etiqueta: "Nombre y apellido", texto: p.nombre, ejemplo: "Lucía Ferreyra")
            Campo(etiqueta: "Nombre profesional", texto: p.nombreProfesional, ejemplo: "Lu Ferreyra · Entrenamiento")
            Campo(etiqueta: "Tu usuario", texto: p.usuario, ejemplo: "luciaentrena", prefijo: "otramas.com.ar/")
            Campo(etiqueta: "Frase corta (\(p.wrappedValue.frase.count)/90)", texto: p.frase, ejemplo: "Funcional al aire libre en Mar del Plata", varias: true)
            Campo(etiqueta: "Sobre mí", texto: p.sobreMi, ejemplo: "Quién sos, cómo trabajás y para quién.", varias: true)
        case .especialidades:
            Etiqueta("Especialidades")
            ChipsClaros(opciones: especialidadesPosibles + p.wrappedValue.especialidades.filter { !especialidadesPosibles.contains($0) },
                        elegidas: Set(p.wrappedValue.especialidades)) { o in alternar(&p.wrappedValue.especialidades, o) }
            HStack(spacing: 8) {
                Campo(etiqueta: "Otra", texto: $nuevaEspecialidad, ejemplo: "Calistenia")
                Boton(titulo: "Sumar", variante: .suave, alto: .chico) {
                    let n = nuevaEspecialidad.trimmingCharacters(in: .whitespaces)
                    if !n.isEmpty { p.wrappedValue.especialidades.append(n); nuevaEspecialidad = "" }
                }
                .padding(.top, 24)
            }
            Etiqueta("Con quiénes trabajás").padding(.top, 8)
            ChipsClaros(opciones: nivelesPosibles, elegidas: Set(p.wrappedValue.niveles)) { o in alternar(&p.wrappedValue.niveles, o) }
        case .formacion:
            if p.wrappedValue.certificaciones.isEmpty {
                Text("Sumá tus títulos y cursos: dan confianza a quien no te conoce.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2)
            }
            ForEach(p.wrappedValue.certificaciones) { c in
                Tarjeta(relleno: 16) {
                    HStack(spacing: 12) {
                        if let d = c.foto, let i = UIImage(data: d) {
                            Image(uiImage: i).resizable().scaledToFill().frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                        } else {
                            IconoVista(.trofeo, tamano: 22).foregroundStyle(Color.yema700)
                                .frame(width: 52, height: 52).background(Color.yema100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.titulo).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                            Text("\(c.institucion) · \(String(c.anio))").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Button { p.wrappedValue.certificaciones.removeAll { $0.id == c.id } } label: {
                            IconoVista(.cerrar, tamano: 16).foregroundStyle(Color.arena500).frame(width: 44, height: 44)
                        }
                        .accessibilityLabel("Quitar \(c.titulo)")
                    }
                }
            }
            Tarjeta(relleno: 16) {
                Etiqueta("Sumar formación")
                VStack(spacing: 12) {
                    Campo(etiqueta: "Título", texto: $nuevoTitulo, ejemplo: "Instructora de pilates")
                    Campo(etiqueta: "Institución", texto: $nuevaInstitucion, ejemplo: "Escuela, instituto o universidad")
                    Campo(etiqueta: "Año", texto: $nuevoAnio, ejemplo: "2024", teclado: .numberPad)
                    PhotosPicker(selection: $certificado, matching: .images) {
                        botonPicker(nuevoCertificado == nil ? "Foto del certificado (opcional)" : "Certificado cargado ✓")
                    }
                    Boton(titulo: "Sumar", icono: .mas, variante: .prim, ancho: true) {
                        guard !nuevoTitulo.isEmpty else { return }
                        p.wrappedValue.certificaciones.append(.init(titulo: nuevoTitulo, institucion: nuevaInstitucion,
                                                                     anio: Int(nuevoAnio) ?? 2026, foto: nuevoCertificado))
                        nuevoTitulo = ""; nuevaInstitucion = ""; nuevoAnio = ""; nuevoCertificado = nil
                        Haptico.exito()
                    }
                    .disabled(nuevoTitulo.isEmpty).opacity(nuevoTitulo.isEmpty ? 0.45 : 1)
                }
                .padding(.top, 8)
            }
        case .lugares:
            ForEach(LugarClase.allCases, id: \.self) { tipo in
                let i = p.wrappedValue.lugares.firstIndex { $0.tipo == tipo }
                Tarjeta(relleno: 16) {
                    Toggle(isOn: Binding(get: { i != nil }, set: { on in
                        if on { p.wrappedValue.lugares.append(.init(tipo: tipo, detalle: "", radioKm: tipo == .domicilio ? 5 : nil)) }
                        else { p.wrappedValue.lugares.removeAll { $0.tipo == tipo } }
                    })) {
                        Text(tipo.titulo).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                    }
                    .tint(Color.ok)
                    if let i {
                        Campo(etiqueta: tipo == .online ? "Cómo" : "Dónde", texto: p.lugares[i].detalle,
                              ejemplo: tipo == .gimnasio ? "Nombre y dirección" : "Plaza Mitre").padding(.top, 12)
                        if tipo == .domicilio {
                            Paso(etiqueta: "Radio (km)", valor: Binding(get: { Double(p.wrappedValue.lugares[i].radioKm ?? 5) },
                                                                      set: { p.wrappedValue.lugares[i].radioKm = Int($0) }), rango: 1...30)
                                .padding(.horizontal, -16)
                        }
                    }
                }
            }
            Tarjeta {
                MapaZona(radioKm: p.wrappedValue.lugares.first { $0.tipo == .domicilio }?.radioKm)
                    .frame(height: 200)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: Radio.tarjeta, topTrailingRadius: Radio.tarjeta, style: .continuous))
                VStack(alignment: .leading, spacing: 12) {
                    Campo(etiqueta: "Ciudad", texto: p.ciudad, ejemplo: "Mar del Plata")
                    Etiqueta("Barrios")
                    ChipsClaros(opciones: p.wrappedValue.barrios, elegidas: Set(p.wrappedValue.barrios)) { b in p.wrappedValue.barrios.removeAll { $0 == b } }
                    HStack(spacing: 8) {
                        Campo(etiqueta: "Sumar barrio", texto: $nuevoBarrio, ejemplo: "Güemes")
                        Boton(titulo: "Sumar", variante: .suave, alto: .chico) {
                            let n = nuevoBarrio.trimmingCharacters(in: .whitespaces)
                            if !n.isEmpty { p.wrappedValue.barrios.append(n); nuevoBarrio = "" }
                        }
                        .padding(.top, 24)
                    }
                }
                .padding(16)
            }
        case .precios:
            ForEach(PerfilProfe.Modalidad.allCases, id: \.self) { m in
                let i = p.wrappedValue.precios.firstIndex { $0.modalidad == m }
                Tarjeta(relleno: 16) {
                    Toggle(isOn: Binding(get: { i.map { p.wrappedValue.precios[$0].activo } ?? false }, set: { on in
                        if let i { p.wrappedValue.precios[i].activo = on } else { p.wrappedValue.precios.append(.init(modalidad: m, desde: 10000)) }
                    })) {
                        NomSub(nombre: m.rawValue, sub: Text("Desde, \(m.unidad)"))
                    }
                    .tint(Color.ok)
                    if let i, p.wrappedValue.precios[i].activo {
                        Campo(etiqueta: "Desde", texto: Binding(get: { String(p.wrappedValue.precios[i].desde) },
                                                                 set: { p.wrappedValue.precios[i].desde = Int($0.filter(\.isNumber)) ?? 0 }),
                              ejemplo: "14000", prefijo: "$", teclado: .numberPad).padding(.top, 12)
                    }
                }
            }
            Tarjeta(relleno: 16) {
                Toggle(isOn: p.claseDePrueba) {
                    NomSub(nombre: "Primera clase gratis", sub: Text("Se muestra como «Pedí una clase de prueba»"))
                }
                .tint(Color.ok)
            }
        case .horarios:
            Text("Salen de tu horario semanal. Lo que cambies en Horario se ve acá.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2)
            Tarjeta {
                ForEach(Array(estado.profe.horario.enumerated()), id: \.element.id) { i, c in
                    if i > 0 { Divisor() }
                    HStack(spacing: 12) {
                        Text(c.hora).tipo(.numero(20), alto: 20).foregroundStyle(Color.berenjena800).frame(width: 56, alignment: .leading)
                        NomSub(nombre: c.nombre, sub: Text("\(dias(c.dias)) · \(c.lugar)"))
                    }
                    .padding(.horizontal, 16).frame(minHeight: 64)
                }
            }
            Boton(titulo: "Sumar una clase", icono: .mas, variante: .suave, ancho: true) { nuevaClase = true }
        case .contacto:
            campoPublico("WhatsApp", p.telefono, "+54 223 …", .telefono, p, .phonePad)
            campoPublico("Mail", p.mail, "nombre@mail.com", .mail, p, .emailAddress)
            campoPublico("Instagram", p.instagram, "@usuario", .instagram, p)
            campoPublico("Otras redes", p.otrasRedes, "TikTok, YouTube…", .otras, p)
            Tarjeta(relleno: 16) {
                Etiqueta("En tu perfil público")
                ForEach([PerfilProfe.Dato.precios, .barrios], id: \.self) { d in
                    Toggle(isOn: visible(d, p)) { Text("Mostrar \(d.titulo.lowercased())").tipo(.texto(16, 600)).foregroundStyle(Color.tinta) }
                        .tint(Color.ok).frame(minHeight: 48)
                }
            }
        case .galeria:
            let fotos = p.wrappedValue.galeria
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                ForEach(Array(fotos.enumerated()), id: \.offset) { i, f in
                    celda(FotoRecortada(nombre: f, foco: .center)) { p.wrappedValue.galeria.remove(at: i) }
                }
                ForEach(Array(p.wrappedValue.galeriaSubida.enumerated()), id: \.offset) { i, d in
                    celda(Group { if let u = UIImage(data: d) { Image(uiImage: u).resizable().scaledToFill() } }) {
                        p.wrappedValue.galeriaSubida.remove(at: i)
                    }
                }
                PhotosPicker(selection: $galeria, maxSelectionCount: 6, matching: .images) {
                    VStack(spacing: 6) {
                        IconoVista(.mas, tamano: 24)
                        Text("Sumar").tipo(.texto(13, 700))
                    }
                    .foregroundStyle(Color.berenjena800)
                    .frame(maxWidth: .infinity).aspectRatio(1, contentMode: .fit)
                    .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
            }
            Text("Fotos de tus clases: el grupo, el lugar, la técnica. Sin caras de alumnos que no hayan dicho que sí.")
                .tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
        case .resenas:
            let r = p.wrappedValue.resenas
            if !r.isEmpty {
                HStack(spacing: 12) {
                    Text(Formato.decimal((p.wrappedValue.promedio * 10).rounded() / 10)).tipo(.numero(56), alto: 56).foregroundStyle(Color.berenjena800)
                    VStack(alignment: .leading, spacing: 4) {
                        Estrellas(valor: p.wrappedValue.promedio, tamano: 18)
                        Text("\(r.count) reseñas de tus alumnos").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    }
                }
            }
            ShareLink(item: URL(string: "https://otramas.com.ar/\(p.wrappedValue.usuario)/resena")!,
                      message: Text("¡Hola! ¿Me dejás una reseña de las clases? Tarda un minuto y me ayuda un montón:")) {
                HStack(spacing: 8) { IconoVista(.wa, tamano: 20).foregroundStyle(Color.yema); Text("Pedir reseña por WhatsApp").tipo(.texto(16, 700)) }
                    .foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            }
            .buttonStyle(Apretable())
            if r.isEmpty {
                Text("Todavía no tenés reseñas. Pedile una a tu alumno más constante.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2)
            }
            ForEach(r) { x in TarjetaResena(resena: x) }
        }
    }

    private func dias(_ d: [Int]) -> String {
        if d == [1, 2, 3, 4, 5] { return "Lun a vie" }
        return d.map { Fecha.cortos[$0 - 1].lowercased() }.joined(separator: ", ")
    }

    private func botonPicker(_ t: String) -> some View {
        HStack(spacing: 8) { IconoVista(.camara, tamano: 20); Text(t).tipo(.texto(16, 700)) }
            .foregroundStyle(Color.berenjena800)
            .frame(maxWidth: .infinity).frame(height: 48)
            .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
    }

    private func celda<V: View>(_ v: V, quitar: @escaping () -> Void) -> some View {
        Color.clear.aspectRatio(1, contentMode: .fit)
            .overlay(v)
            .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button(action: quitar) {
                    IconoVista(.cerrar, tamano: 12, grosor: 3).foregroundStyle(Color.hueso)
                        .frame(width: 26, height: 26).background(Color.berenjena900.opacity(0.7), in: Circle())
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Quitar foto")
            }
    }

    private func visible(_ d: PerfilProfe.Dato, _ p: Binding<PerfilProfe>) -> Binding<Bool> {
        Binding(get: { p.wrappedValue.muestra(d) }, set: { p.wrappedValue.visible[d] = $0 })
    }

    private func campoPublico(_ e: String, _ t: Binding<String>, _ ej: String, _ d: PerfilProfe.Dato, _ p: Binding<PerfilProfe>,
                              _ teclado: UIKeyboardType = .default) -> some View {
        Tarjeta(relleno: 16) {
            Campo(etiqueta: e, texto: t, ejemplo: ej, teclado: teclado)
            Toggle(isOn: visible(d, p)) {
                Text(p.wrappedValue.muestra(d) ? "Se ve en tu perfil" : "Sólo lo ves vos").tipo(.texto(14, 600)).foregroundStyle(Color.texto2)
            }
            .tint(Color.ok).padding(.top, 8)
        }
    }

    private func alternar(_ l: inout [String], _ v: String) {
        if let i = l.firstIndex(of: v) { l.remove(at: i) } else { l.append(v) }
    }
}

/// Mapa de Mar del Plata con las plazas y la zona a domicilio.
struct MapaZona: View {
    var radioKm: Int?
    private let laPerla = CLLocationCoordinate2D(latitude: -37.9905, longitude: -57.5500)
    var body: some View {
        Map(initialPosition: .region(MKCoordinateRegion(center: laPerla, latitudinalMeters: 14000, longitudinalMeters: 14000))) {
            if let r = radioKm {
                MapCircle(center: laPerla, radius: CLLocationDistance(r * 1000))
                    .foregroundStyle(Color.yema.opacity(0.22))
                    .stroke(Color.yema700, lineWidth: 2)
            }
            Marker("Plaza Mitre", coordinate: CLLocationCoordinate2D(latitude: -38.0047, longitude: -57.5450)).tint(Color.berenjena800)
            Marker("Plaza España", coordinate: CLLocationCoordinate2D(latitude: -37.9937, longitude: -57.5428)).tint(Color.berenjena800)
        }
        .mapStyle(.standard(pointsOfInterest: .excludingAll))
        .allowsHitTesting(false)
        .accessibilityLabel("Mapa de la zona donde das clases")
    }
}

struct TarjetaResena: View {
    let resena: PerfilProfe.Resena
    var body: some View {
        Tarjeta(relleno: 16) {
            HStack {
                Text(resena.nombre).tipo(.texto(15, 700)).foregroundStyle(Color.tinta)
                Spacer()
                Estrellas(valor: Double(resena.estrellas), tamano: 12)
            }
            Text(resena.texto).tipo(.texto(15, 400)).foregroundStyle(Color.arena700).padding(.top, 6)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(Fecha.mes(resena.fecha).capitalized) \(String(Fecha.calendario.component(.year, from: Fecha.fecha(resena.fecha))))")
                .tipo(.texto(12, 600)).foregroundStyle(Color.arena500).padding(.top, 6)
        }
    }
}

// MARK: - Así te ven

/// La página pública del profe, como la ve un alumno.
struct AsiTeVen: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @Binding var qr: Bool

    var body: some View {
        let p = estado.perfilProfe
        let l = estado.logrosProfe
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack(alignment: .bottomLeading) {
                        Portada(perfil: p).frame(height: 240).frame(maxWidth: .infinity)
                            .overlay(LinearGradient(colors: [Color.berenjena950.opacity(0.45), .clear], startPoint: .top, endPoint: .center))
                            .padding(.bottom, 52)
                        FotoPerfil(perfil: p, tamano: 104)
                            .overlay(Circle().stroke(Color.hueso, lineWidth: 5))
                            .padding(.leading, Espacio.margen)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        Text(p.nombre.uppercased(with: Locale(identifier: "es_AR"))).tipo(.titulo(40)).foregroundStyle(Color.berenjena800)
                            .fixedSize(horizontal: false, vertical: true).padding(.top, 12)
                        Text(p.nombreProfesional).tipo(.texto(15, 600)).foregroundStyle(Color.texto2).padding(.top, 2)
                        if !p.resenas.isEmpty {
                            HStack(spacing: 6) {
                                Estrellas(valor: p.promedio)
                                Text("\(Formato.decimal((p.promedio * 10).rounded() / 10)) · \(p.resenas.count) reseñas").tipo(.texto(14, 700)).foregroundStyle(Color.tinta)
                            }
                            .padding(.top, 8)
                        }
                        Text(p.frase).tipo(.texto(18, 600)).foregroundStyle(Color.tinta).padding(.top, 12)
                            .fixedSize(horizontal: false, vertical: true)
                        if p.claseDePrueba {
                            HStack(spacing: 6) { IconoVista(.estrella, tamano: 14); Text("Primera clase gratis").tipo(.texto(13, 700)) }
                                .foregroundStyle(Color.berenjena800).padding(.horizontal, 12).frame(height: 32)
                                .background(Color.yema, in: Capsule()).padding(.top, 12)
                        }
                        Fluir(espacio: 6) {
                            ForEach(p.especialidades, id: \.self) { e in
                                Text(e).tipo(.texto(13, 700)).foregroundStyle(Color.berenjena800)
                                    .padding(.horizontal, 12).frame(height: 32).background(Color.berenjena100, in: Capsule())
                            }
                        }
                        .padding(.top, 12)
                        HStack(spacing: 8) {
                            numero("\(l.anios)", "años")
                            numero("\(l.alumnos)", "alumnos")
                            numero(Formato.miles(l.clases), "clases")
                        }
                        .padding(.top, 20)
                        bloque("Sobre mí") { Text(p.sobreMi).tipo(.texto(16, 400)).foregroundStyle(Color.arena700).fixedSize(horizontal: false, vertical: true) }
                        bloque("Dónde") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(p.lugares) { x in
                                    HStack(alignment: .top, spacing: 10) {
                                        IconoVista(.pin, tamano: 18).foregroundStyle(Color.yema700)
                                        Text("\(x.tipo.titulo): \(x.detalle)\(x.radioKm.map { " (hasta \($0) km)" } ?? "")")
                                            .tipo(.texto(15, 400)).foregroundStyle(Color.tinta).fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                                if p.muestra(.barrios) {
                                    Text("\(p.ciudad) · \(p.barrios.joined(separator: ", "))").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                                }
                            }
                        }
                        if p.muestra(.precios) {
                            bloque("Precios") {
                                VStack(spacing: 0) {
                                    ForEach(p.precios.filter(\.activo)) { x in
                                        HStack {
                                            Text(x.modalidad.rawValue).tipo(.texto(16, 600)).foregroundStyle(Color.tinta)
                                            Spacer()
                                            Text("desde ").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                                            Text(Formato.plata(x.desde)).tipo(.numero(20), alto: 20).foregroundStyle(Color.berenjena800)
                                            Text(" \(x.modalidad.unidad)").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                                        }
                                        .frame(minHeight: 44)
                                    }
                                }
                            }
                        }
                        bloque("Horarios") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(estado.profe.horario.filter { $0.particular == nil }) { c in
                                    HStack {
                                        Text(c.dias.map { Fecha.cortos[$0 - 1] }.joined(separator: " · ")).tipo(.texto(14, 600)).foregroundStyle(Color.tinta)
                                        Spacer()
                                        Text("\(c.hora) · \(c.lugar)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                                    }
                                }
                            }
                        }
                        if !p.galeria.isEmpty {
                            bloque("Clases") {
                                ScrollView(.horizontal) {
                                    HStack(spacing: 8) {
                                        ForEach(p.galeria, id: \.self) { f in
                                            FotoRecortada(nombre: f, foco: .center).frame(width: 150, height: 190)
                                                .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                                        }
                                    }
                                }
                                .scrollIndicators(.hidden)
                            }
                        }
                        bloque("Formación") {
                            VStack(alignment: .leading, spacing: 10) {
                                ForEach(p.certificaciones) { c in
                                    HStack(alignment: .top, spacing: 10) {
                                        IconoVista(.trofeo, tamano: 18).foregroundStyle(Color.yema700)
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text(c.titulo).tipo(.texto(15, 700)).foregroundStyle(Color.tinta)
                                            Text("\(c.institucion) · \(String(c.anio))").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                                        }
                                    }
                                }
                            }
                        }
                        if !p.resenas.isEmpty {
                            bloque("Reseñas") { VStack(spacing: 12) { ForEach(p.resenas) { TarjetaResena(resena: $0) } } }
                        }
                        let contactos = [(PerfilProfe.Dato.telefono, p.telefono), (.instagram, p.instagram), (.mail, p.mail), (.otras, p.otrasRedes)]
                            .filter { p.muestra($0.0) && !$0.1.isEmpty }
                        if !contactos.isEmpty {
                            bloque("Contacto") {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(contactos, id: \.0) { d, v in
                                        HStack {
                                            Text(d.titulo).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                                            Spacer()
                                            Text(v).tipo(.texto(15, 700)).foregroundStyle(Color.tinta)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.bottom, 140)
                }
            }
            .scrollIndicators(.hidden)
            .ignoresSafeArea(edges: .top)
            .background(Color.hueso.ignoresSafeArea())

            // Botones del alumno
            HStack(spacing: 12) {
                Boton(titulo: "Escribile", icono: .wa, variante: .suave, alto: .alto, colorIcono: .ok) {
                    estado.avisar("Así le llega a \(p.nombre.split(separator: " ").first ?? "") un WhatsApp tuyo.")
                }
                .fixedSize()
                Boton(titulo: p.claseDePrueba ? "Pedí una clase de prueba" : "Pedí una clase", variante: .yema, alto: .alto, ancho: true) {
                    estado.avisar("Así te piden una clase de prueba. Te llega el aviso.")
                }
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 24)
            .background(LinearGradient(stops: [.init(color: .hueso.opacity(0), location: 0), .init(color: .hueso, location: 0.35)],
                                       startPoint: .top, endPoint: .bottom).ignoresSafeArea())
        }
        .overlay(alignment: .top) {
            HStack(spacing: 8) {
                Button { dismiss() } label: {
                    HStack(spacing: 2) { IconoVista(.atras, tamano: 20); Text("Tu perfil").tipo(.texto(15, 700)) }
                        .foregroundStyle(Color.hueso).padding(.horizontal, 12).frame(height: 40)
                        .background(Color.berenjena900.opacity(0.55), in: Capsule())
                }
                .buttonStyle(Apretable())
                Spacer()
                Text("Vista previa").tipo(.texto(12, 700)).foregroundStyle(Color.berenjena800)
                    .padding(.horizontal, 10).frame(height: 28).background(Color.yema, in: Capsule())
                Button { qr = true } label: {
                    Image(systemName: "qrcode").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.hueso)
                        .frame(width: 40, height: 40).background(Color.berenjena900.opacity(0.55), in: Circle())
                }
                .accessibilityLabel("Ver el QR de tu perfil")
                ShareLink(item: p.link, subject: Text(p.nombreProfesional), message: Text(p.frase)) {
                    Image(systemName: "square.and.arrow.up").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.hueso)
                        .frame(width: 40, height: 40).background(Color.berenjena900.opacity(0.55), in: Circle())
                }
                .accessibilityLabel("Compartir tu perfil")
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 4)
        }
        .toolbar(.hidden, for: .navigationBar)
    }

    private func numero(_ n: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(n).tipo(.numero(24), alto: 24).foregroundStyle(Color.berenjena800)
            Text(l).tipo(.texto(12, 600)).foregroundStyle(Color.texto2)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 12)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
        .sombraTarjeta()
    }

    private func bloque<C: View>(_ t: String, @ViewBuilder _ c: () -> C) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Titulo(t, tamano: 20)
            c()
        }
        .padding(.top, 28)
    }
}

// MARK: - QR

enum QR {
    /// QR berenjena sobre hueso, con corrección alta (para poner el +1 en el medio).
    static func imagen(_ texto: String, lado: CGFloat = 900) -> UIImage? {
        let f = CIFilter.qrCodeGenerator()
        f.message = Data(texto.utf8)
        f.correctionLevel = "H"
        guard let base = f.outputImage else { return nil }
        let color = CIFilter.falseColor()
        color.inputImage = base
        color.color0 = CIColor(red: 0x2B / 255, green: 0x16 / 255, blue: 0x38 / 255)
        color.color1 = CIColor(red: 0xFA / 255, green: 0xF7 / 255, blue: 0xF2 / 255)
        guard let coloreada = color.outputImage else { return nil }
        let e = lado / base.extent.width
        let grande = coloreada.transformed(by: CGAffineTransform(scaleX: e, y: e))
        guard let cg = CIContext().createCGImage(grande, from: grande.extent) else { return nil }
        return UIImage(cgImage: cg)
    }
}

/// Tarjeta con el QR del perfil, para imprimir o subir a Instagram.
struct TarjetaQR: View {
    let perfil: PerfilProfe
    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 6) {
                Image("mas-uno").resizable().scaledToFit().frame(width: 28)
                Text("OTRA MÁS").font(Estilo.titulo(18).font()).foregroundStyle(Color.berenjena800)
            }
            if let q = QR.imagen(perfil.link.absoluteString) {
                Image(uiImage: q).interpolation(.none).resizable().scaledToFit()
                    .frame(width: 240, height: 240)
                    .overlay {
                        Image("mas-uno").resizable().scaledToFit().frame(width: 40)
                            .padding(10).background(Color.hueso, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
            }
            VStack(spacing: 4) {
                Text(perfil.nombre.uppercased(with: Locale(identifier: "es_AR"))).font(Estilo.titulo(28).font()).foregroundStyle(Color.berenjena800)
                Text("otramas.com.ar/\(perfil.usuario)").font(Estilo.texto(15, 700).font()).foregroundStyle(Color.yema700)
                Text("Escaneá y pedí tu clase").font(Estilo.texto(13, 400).font()).foregroundStyle(Color.arena600)
            }
        }
        .padding(28)
        .background(Color.hueso, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
    }
}

struct QRPerfil: View {
    @Environment(Estado.self) private var estado
    @State private var imagen: UIImage?

    var body: some View {
        let p = estado.perfilProfe
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Tu perfil", titulo: "Tu QR")
            TarjetaQR(perfil: p)
                .sombraTarjeta()
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
            Text("Imprimilo para la plaza o subilo a tus historias: lleva directo a tu perfil.")
                .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 16)
            Spacer(minLength: 16)
            if let imagen {
                ShareLink(item: Image(uiImage: imagen), preview: SharePreview("QR de \(p.nombre)", image: Image(uiImage: imagen))) {
                    HStack(spacing: 8) { Image(systemName: "square.and.arrow.up").font(.system(size: 17, weight: .semibold)).foregroundStyle(Color.yema); Text("Compartir o guardar").tipo(.texto(16, 700)) }
                        .foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
                .buttonStyle(Apretable())
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .background(Color.arena50.ignoresSafeArea())
        .estiloHoja()
        .onAppear {
            let r = ImageRenderer(content: TarjetaQR(perfil: p).frame(width: 360))
            r.scale = 3
            imagen = r.uiImage
        }
    }
}
