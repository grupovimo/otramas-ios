import SwiftUI
import PhotosUI

enum PestanaFicha: String, CaseIterable { case resumen = "Resumen", progreso = "Progreso", pagos = "Pagos", asistencia = "Asistencia", notas = "Notas" }

/// Datos del alumno al pie del resumen: contacto, objetivo, lesiones, abono e inicio.
struct DatosFicha: View {
    @Environment(Estado.self) private var estado
    let alumnoId: String
    var body: some View {
        if let d = estado.detalle(alumnoId) {
            TituloSeccion("Datos")
            Tarjeta {
                fila("WhatsApp", d.telefono) {
                    if let url = URL(string: "tel:\(d.telefono.filter { $0.isNumber || $0 == "+" })") {
                        Link(destination: url) {
                            Image(systemName: "phone.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.ok)
                                .frame(width: 44, height: 44).background(Color.okFondo, in: Circle())
                        }
                        .accessibilityLabel("Llamar")
                    }
                }
                Divisor()
                fila("Objetivo", d.objetivo?.titulo ?? "—") { EmptyView() }
                Divisor()
                fila("Lesiones o molestias", d.lesiones.isEmpty ? "Ninguna" : d.lesiones.joined(separator: ", ")) { EmptyView() }
                Divisor()
                fila("Abono", estado.abono(d.abonoId).map { "\($0.nombre) · \(Formato.plata($0.precio))" } ?? "—") { EmptyView() }
                Divisor()
                fila("Entrena desde", Fecha.largo(d.inicio).components(separatedBy: " ").dropFirst().joined(separator: " ") + " de \(Fecha.calendario.component(.year, from: Fecha.fecha(d.inicio)))") { EmptyView() }
            }
        }
    }

    private func fila<A: View>(_ e: String, _ v: String, @ViewBuilder _ accion: () -> A) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Etiqueta(e)
                Text(v).tipo(.texto(16, 600)).foregroundStyle(Color.tinta)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accion()
        }
        .padding(.horizontal, 16).padding(.vertical, 10).frame(minHeight: 64)
        .accessibilityElement(children: .combine)
    }
}

/// Progreso · Pagos · Asistencia · Notas de la ficha.
struct FichaPestana: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    let alumnoId: String
    let pestana: PestanaFicha
    @State private var medicion = false
    @State private var evaluacion = false
    @State private var linkPago = false
    @State private var foto: PhotosPickerItem?
    @State private var nota = ""

    var body: some View {
        if let d = estado.detalle(alumnoId), let a = estado.alumno(alumnoId) {
            switch pestana {
            case .resumen: EmptyView()
            case .progreso: progreso(d)
            case .pagos: pagos(d, a)
            case .asistencia: asistencia
            case .notas: notas(d)
            }
            Color.clear.frame(height: 1)
                .sheet(isPresented: $medicion) { HojaMedicion(alumnoId: alumnoId) }
                .sheet(isPresented: $evaluacion) { HojaEvaluacion(alumnoId: alumnoId) }
                .sheet(isPresented: $linkPago) { HojaLinkPago(alumnoId: alumnoId) }
                .onChange(of: foto) { _, i in
                    guard let i else { return }
                    Task {
                        if let datos = try? await i.loadTransferable(type: Data.self), let chica = achicar(datos) { estado.sumar(foto: chica, a: alumnoId) }
                        foto = nil
                    }
                }
        }
    }

    // MARK: Progreso

    @ViewBuilder
    private func progreso(_ d: DetalleAlumno) -> some View {
        let m = d.mediciones.sorted { $0.fecha < $1.fecha }
        TituloSeccion(texto: "Mediciones", arriba: 0) {
            Button { medicion = true } label: { Text("Sumar").tipo(.texto(15, 700)).foregroundStyle(Color.yema700).frame(height: 44) }
        }
        if let u = m.last, let p = m.first {
            Tarjeta(relleno: 16) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiqueta("Peso")
                        Numero(valor: Formato.decimal(u.peso), tamano: 28, unidad: "kg")
                    }
                    Spacer()
                    let dif = u.peso - p.peso
                    Text("\(dif <= 0 ? "−" : "+")\(Formato.decimal(abs((dif * 10).rounded() / 10))) kg desde \(Fecha.mes(p.fecha))")
                        .tipo(.texto(14, 700)).foregroundStyle(Color.ok).padding(.bottom, 4)
                }
                GraficoProgreso(valores: m.map(\.peso), meses: m.map { Fecha.mes($0.fecha).prefix(3).uppercased() },
                                minimo: (m.map(\.peso).min() ?? 50) - 3, maximo: (m.map(\.peso).max() ?? 90) + 2,
                                marcas: [((m.map(\.peso).min() ?? 50)).rounded(), ((m.map(\.peso).max() ?? 90)).rounded()])
                    .padding(.top, 8)
                HStack(spacing: 8) {
                    if let g = u.grasa { mini("Grasa", "\(Formato.decimal(g)) %") }
                    if let c = u.cintura { mini("Cintura", "\(Formato.decimal(c)) cm") }
                    if let c = u.cadera { mini("Cadera", "\(Formato.decimal(c)) cm") }
                }
                .padding(.top, 12)
            }
        } else {
            vacio("Todavía no hay mediciones", "Sumá peso y medidas una vez por mes.", "Sumar medición") { medicion = true }
        }

        TituloSeccion(texto: "Fotos de progreso") {
            PhotosPicker(selection: $foto, matching: .images) { Text("Sumar").tipo(.texto(15, 700)).foregroundStyle(Color.yema700).frame(height: 44) }
        }
        if d.fotos.isEmpty {
            vacio("Sin fotos todavía", "Antes y después, privadas: sólo las ven vos y tu alumno.", nil) {}
        } else {
            HStack(spacing: 8) {
                ForEach(d.fotos.suffix(2)) { f in
                    VStack(alignment: .leading, spacing: 6) {
                        Group {
                            if let x = f.datos, let i = UIImage(data: x) { Image(uiImage: i).resizable().scaledToFill() }
                            else if let a = f.asset { FotoRecortada(nombre: a, foco: .center) }
                        }
                        .frame(height: 200).frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
                        Text(f.id == d.fotos.first?.id ? "Antes · \(Fecha.corta(f.fecha))" : "Ahora · \(Fecha.corta(f.fecha))")
                            .tipo(.texto(13, 700)).foregroundStyle(Color.texto2)
                    }
                }
            }
            HStack(spacing: 6) {
                IconoVista(.candado, tamano: 14); Text("Privadas: sólo las ven vos y tu alumno.").tipo(.texto(13, 400))
            }
            .foregroundStyle(Color.texto2).padding(.top, 8)
        }

        TituloSeccion(texto: "Evaluaciones") {
            Button { evaluacion = true } label: { Text("Sumar").tipo(.texto(15, 700)).foregroundStyle(Color.yema700).frame(height: 44) }
        }
        let grupos = Dictionary(grouping: d.evaluaciones, by: \.nombre).sorted { $0.key < $1.key }
        if grupos.isEmpty {
            vacio("Sin evaluaciones", "Sentadilla 1RM, plancha, Cooper: medí y compará.", "Sumar evaluación") { evaluacion = true }
        } else {
            Tarjeta {
                ForEach(Array(grupos.enumerated()), id: \.element.key) { i, g in
                    if i > 0 { Divisor() }
                    let h = g.value.sorted { $0.fecha < $1.fecha }
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(g.key).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                            Text(h.map { "\(Formato.decimal($0.valor)) \($0.unidad) (\(Fecha.corta($0.fecha)))" }.joined(separator: " → "))
                                .tipo(.texto(13, 400)).foregroundStyle(Color.texto2).lineLimit(2)
                        }
                        Spacer()
                        if h.count > 1, let a = h.first?.valor, let b = h.last?.valor, a > 0 {
                            Text("\(b >= a ? "+" : "")\(Int(((b - a) / a * 100).rounded())) %").tipo(.numero(20), alto: 20)
                                .foregroundStyle(b >= a ? Color.ok : Color.error)
                        }
                    }
                    .padding(16)
                }
            }
        }

        TituloSeccion("Récords")
        Tarjeta {
            ForEach(Array(d.marcas.enumerated()), id: \.element.id) { i, r in
                if i > 0 { Divisor() }
                HStack(spacing: 12) {
                    if let e = estado.ejercicio(r.ejercicioId) {
                        IlustracionEjercicio(ejercicio: e, sexo: estado.sexoIlustracion).frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    }
                    NomSub(nombre: estado.ejercicio(r.ejercicioId)?.nombre ?? r.ejercicioId, sub: Text("El \(Fecha.corta(r.fecha))"))
                    Numero(valor: Formato.decimal(r.kilos), tamano: 24, unidad: "kg")
                }
                .padding(.horizontal, 16).padding(.vertical, 10)
            }
        }
    }

    private func mini(_ e: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Etiqueta(e)
            Text(v).tipo(.numero(18), alto: 18).foregroundStyle(Color.berenjena800)
        }
        .padding(10).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.arena50, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
    }

    // MARK: Pagos

    @ViewBuilder
    private func pagos(_ d: DetalleAlumno, _ a: Alumno) -> some View {
        let monto = estado.montoCuota(a.id)
        Tarjeta(relleno: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Etiqueta("Noviembre")
                    switch a.cuota {
                    case .alDia: Text("Pagó").tipo(.texto(20, 700)).foregroundStyle(Color.ok)
                    case .porConfirmar: Text("Mandó comprobante").tipo(.texto(20, 700)).foregroundStyle(Color.yema700)
                    case .debe(let x): Text("Debe hace \(x.dias) días").tipo(.texto(20, 700)).foregroundStyle(Color.error)
                    }
                }
                Spacer()
                Numero(valor: Formato.plata(monto), tamano: 24)
            }
            HStack(spacing: 8) {
                Boton(titulo: "Link de pago", icono: .plata, variante: .suave, alto: .chico, ancho: true) { linkPago = true }
                Boton(titulo: "Registrar", icono: .tilde, variante: .prim, alto: .chico, ancho: true) { nav.hoja = .cobrar(a.id) }
            }
            .padding(.top, 12)
        }
        TituloSeccion("Historial")
        if d.pagos.isEmpty {
            vacio("Todavía no pagó", "Mandale el link de pago y se acredita solo.", "Mandar link") { linkPago = true }
        } else {
            Tarjeta {
                ForEach(Array(d.pagos.sorted { $0.fecha > $1.fecha }.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { Divisor() }
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(Fecha.mes("\(p.mes)-01").capitalized).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                            Text("\(p.medio.rawValue) · el \(Fecha.corta(p.fecha))").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                        }
                        Spacer()
                        Text(Formato.plata(p.monto)).tipo(.numero(18), alto: 18).foregroundStyle(Color.tinta)
                        CompartirBoton(generar: { Recibo.uiImagen(p, alumno: a.nombre, profe: estado.perfilProfe.nombre) }) {
                            IconoVista(.recibo, tamano: 18).foregroundStyle(Color.berenjena800)
                                .frame(width: 44, height: 44).background(Color.berenjena100, in: Circle())
                        }
                        .accessibilityLabel("Compartir recibo")
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: Asistencia

    @ViewBuilder
    private var asistencia: some View {
        let lista = estado.asistencia(de: alumnoId)
        let vino = lista.filter(\.vino).count
        if lista.isEmpty {
            vacio("Sin clases fijas", "Asignale un horario fijo y acá vas a ver si viene.", nil) {}
        } else {
            Tarjeta(relleno: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Numero(valor: "\(Int((Double(vino) / Double(max(lista.count, 1)) * 100).rounded()))", tamano: 40, chico: "%", tamanoChico: 24)
                    Text("vino a \(vino) de \(lista.count) clases en 8 semanas").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                }
                // Una fila de puntos por clase, la más vieja a la izquierda.
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 10), spacing: 6) {
                    ForEach(Array(lista.reversed().enumerated()), id: \.offset) { _, x in
                        Circle().fill(x.vino ? Color.berenjena800 : Color.arena100).frame(height: 22)
                            .overlay { if x.vino { IconoVista(.tilde, tamano: 12, grosor: 3).foregroundStyle(Color.yema) } }
                    }
                }
                .padding(.top, 12)
                .accessibilityHidden(true)
            }
            TituloSeccion("Últimas clases")
            Tarjeta {
                ForEach(Array(lista.prefix(10).enumerated()), id: \.offset) { i, x in
                    if i > 0 { Divisor() }
                    HStack {
                        NomSub(nombre: Fecha.largo(x.fecha), sub: Text(x.clase))
                        Text(x.vino ? "Vino" : "Faltó").tipo(.texto(14, 700)).foregroundStyle(x.vino ? Color.ok : Color.error)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
            }
        }
    }

    // MARK: Notas

    @ViewBuilder
    private func notas(_ d: DetalleAlumno) -> some View {
        Tarjeta(relleno: 16) {
            Etiqueta("Nota nueva")
            TextField("", text: $nota, prompt: Text("Molestias, avances, lo que quieras recordar").foregroundColor(.arena500), axis: .vertical)
                .lineLimit(2...6)
                .font(Estilo.texto(16, 400).font()).foregroundStyle(Color.tinta).tint(Color.berenjena800)
                .padding(.top, 8)
            Boton(titulo: "Guardar nota", variante: .prim, alto: .chico, ancho: true) {
                estado.sumar(nota: nota, a: alumnoId); nota = ""
            }
            .disabled(nota.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(nota.trimmingCharacters(in: .whitespaces).isEmpty ? 0.45 : 1)
            .padding(.top, 12)
        }
        Text("Sólo las ves vos.").tipo(.texto(13, 400)).foregroundStyle(Color.texto2).padding(.top, 8)
        ForEach(d.notas) { n in
            Tarjeta(relleno: 16) {
                Etiqueta(Fecha.largo(n.fecha))
                Text(n.texto).tipo(.texto(15, 400)).foregroundStyle(Color.tinta).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 12)
        }
    }

    private func vacio(_ t: String, _ s: String, _ accion: String?, _ hacer: @escaping () -> Void) -> some View {
        Tarjeta(relleno: 20) {
            Text(t).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
            Text(s).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            if let accion { Boton(titulo: accion, icono: .mas, variante: .prim, alto: .chico, ancho: true, accion: hacer).padding(.top, 12) }
        }
    }
}

// MARK: - Hojas

struct HojaMedicion: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let alumnoId: String
    @State private var peso: Double = 70
    @State private var grasa = ""
    @State private var cintura = ""
    @State private var cadera = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: estado.alumno(alumnoId)?.nombre, titulo: "Medición de hoy")
            ScrollView {
                VStack(spacing: 16) {
                    Tarjeta { Paso(etiqueta: "Peso (kg)", valor: $peso, paso: 0.5, rango: 30...200, formato: Formato.decimal) }
                    Campo(etiqueta: "% de grasa (opcional)", texto: $grasa, ejemplo: "24", teclado: .decimalPad)
                    HStack(spacing: 12) {
                        Campo(etiqueta: "Cintura (cm)", texto: $cintura, ejemplo: "80", teclado: .decimalPad)
                        Campo(etiqueta: "Cadera (cm)", texto: $cadera, ejemplo: "98", teclado: .decimalPad)
                    }
                }
                .padding(.top, 24)
            }
            Boton(titulo: "Guardar medición", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                func n(_ s: String) -> Double? { Double(s.replacingOccurrences(of: ",", with: ".")) }
                estado.sumar(medicion: Medicion(fecha: estado.hoy, peso: peso, grasa: n(grasa), cintura: n(cintura), cadera: n(cadera)), a: alumnoId)
                dismiss()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .onAppear { peso = estado.detalle(alumnoId)?.mediciones.last?.peso ?? 70 }
    }
}

struct HojaEvaluacion: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let alumnoId: String
    @State private var test = "Sentadilla 1RM"
    @State private var valor: Double = 40
    private let tests: [(String, String)] = [("Sentadilla 1RM", "kg"), ("Peso muerto 1RM", "kg"), ("Plancha", "s"), ("Test de Cooper", "m"), ("Flexiones", "reps"), ("Salto en largo", "cm")]

    // Partido en piezas chicas: en el Xcode de GitHub, la versión de una sola expresión no llegaba a compilar.
    private var unidad: String { tests.first { $0.0 == test }?.1 ?? "" }
    private var pasoValor: Double {
        switch unidad {
        case "m": return 50
        case "kg": return 2.5
        default: return 1
        }
    }
    private var anterior: Evaluacion? {
        let evs: [Evaluacion] = estado.detalle(alumnoId)?.evaluaciones ?? []
        return evs.filter { $0.nombre == test }.last
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: estado.alumno(alumnoId)?.nombre, titulo: "Evaluación")
            ScrollView { contenido.padding(.top, 24) }
            guardar.padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .onChange(of: test) { _, t in valor = valorInicial(t) }
    }

    private var contenido: some View {
        VStack(alignment: .leading, spacing: 16) {
            ChipsClaros(opciones: tests.map(\.0), elegidas: [test]) { test = $0 }
            Tarjeta {
                Paso(etiqueta: "Resultado (" + unidad + ")", valor: $valor, paso: pasoValor, rango: 0...5000, formato: Formato.decimal)
            }
            if let ant = anterior {
                Text(textoAnterior(ant)).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
        }
    }

    private var guardar: some View {
        Boton(titulo: "Guardar", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
            let ev = Evaluacion(nombre: test, valor: valor, unidad: unidad, fecha: estado.hoy)
            estado.sumar(evaluacion: ev, a: alumnoId)
            dismiss()
        }
    }

    private func textoAnterior(_ ant: Evaluacion) -> String {
        "La última vez: " + Formato.decimal(ant.valor) + " " + ant.unidad + " el " + Fecha.corta(ant.fecha)
    }

    private func valorInicial(_ t: String) -> Double {
        let evs: [Evaluacion] = estado.detalle(alumnoId)?.evaluaciones ?? []
        if let v = evs.filter({ $0.nombre == t }).last?.valor { return v }
        return t == "Test de Cooper" ? 2000 : 30
    }
}

/// Link de pago de Mercado Pago para un alumno (simulado): copiar o mandar por WhatsApp.
struct HojaLinkPago: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let alumnoId: String
    var body: some View {
        let a = estado.alumno(alumnoId)
        let url = estado.linkDePago(alumnoId)
        let monto = estado.montoCuota(alumnoId)
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: a?.nombre, titulo: "Link de pago")
            Tarjeta(relleno: 20) {
                HStack(spacing: 10) {
                    Text("MP").font(.system(size: 14, weight: .heavy)).foregroundStyle(.white)
                        .frame(width: 40, height: 40).background(Color(hex: 0x009EE3), in: Circle())
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cuota de noviembre").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                        Text("Se acredita solo y te avisamos").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                }
                Numero(valor: Formato.plata(monto), tamano: 40).padding(.top, 16)
                Text(url.absoluteString.replacingOccurrences(of: "https://", with: "")).tipo(.texto(14, 600)).foregroundStyle(Color.berenjena600)
                    .padding(.top, 8)
            }
            .padding(.top, 20)
            HStack(spacing: 8) {
                Boton(titulo: "Copiar", icono: .copiar, variante: .suave, alto: .alto, ancho: true) {
                    UIPasteboard.general.string = url.absoluteString; estado.avisar("Link copiado."); dismiss()
                }
                ShareLink(item: url, message: Text("¡Hola \(a?.primerNombre ?? "")! Te paso el link para pagar la cuota de noviembre (\(Formato.plata(monto))):")) {
                    HStack(spacing: 8) { IconoVista(.wa, tamano: 20).foregroundStyle(Color.yema); Text("Mandar").tipo(.texto(16, 700)) }
                        .foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
                .buttonStyle(Apretable())
            }
            .padding(.top, 16)
            Spacer()
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja([.medium])
    }
}

/// Recibo para compartir (imagen).
enum Recibo {
    @MainActor
    static func uiImagen(_ p: Pago, alumno: String, profe: String) -> UIImage {
        let v = VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image("mas-uno").resizable().scaledToFit().frame(width: 26)
                Text("OTRA MÁS").font(Estilo.titulo(18).font()).foregroundStyle(Color.berenjena800)
                Spacer()
                Text("RECIBO").font(Estilo.etiqueta.font()).tracking(0.84).foregroundStyle(Color.arena600)
            }
            Rectangle().fill(Color.arena100).frame(height: 1)
            Text("Cuota de \(Fecha.mes("\(p.mes)-01"))").font(Estilo.texto(15, 600).font()).foregroundStyle(Color.texto2)
            Text(Formato.plata(p.monto)).font(Estilo.numero(44).font()).foregroundStyle(Color.berenjena800)
            Text("Pagó \(alumno) · \(p.medio.rawValue)").font(Estilo.texto(14, 600).font()).foregroundStyle(Color.tinta)
            Text("El \(Fecha.largo(p.fecha).lowercased())").font(Estilo.texto(13, 400).font()).foregroundStyle(Color.texto2)
            Rectangle().fill(Color.arena100).frame(height: 1)
            Text("Recibió: \(profe)").font(Estilo.texto(13, 700).font()).foregroundStyle(Color.tinta)
        }
        .padding(24).frame(width: 340).background(Color.hueso)
        let r = ImageRenderer(content: v)
        r.scale = 3
        return r.uiImage ?? UIImage()
    }
}

/// Alta completa o edición de un alumno.
struct HojaDatosAlumno: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    var alumnoId: String?
    @State private var nombre = ""
    @State private var telefono = ""
    @State private var objetivo: Objetivo?
    @State private var lesiones: [String] = []
    @State private var abonoId = "m3"
    @State private var claseId: String?
    @State private var inicio = Fecha.fecha("2026-11-30")

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: alumnoId == nil ? "Con su link listo" : "Editar", titulo: alumnoId == nil ? "Alumno nuevo" : "Datos del alumno")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Campo(etiqueta: "Nombre y apellido", texto: $nombre, ejemplo: "Sofía Méndez")
                    Campo(etiqueta: "WhatsApp", texto: $telefono, ejemplo: "+54 223 …", teclado: .phonePad)
                    Etiqueta("Objetivo")
                    ChipsClaros(opciones: Objetivo.allCases.map(\.titulo), elegidas: Set([objetivo?.titulo].compactMap { $0 })) { t in
                        objetivo = Objetivo.allCases.first { $0.titulo == t }
                    }
                    Etiqueta("Lesiones o molestias")
                    ChipsClaros(opciones: ["Ninguna"] + lesionesComunes, elegidas: Set(lesiones.isEmpty ? ["Ninguna"] : lesiones)) { o in
                        if o == "Ninguna" { lesiones = [] } else if let i = lesiones.firstIndex(of: o) { lesiones.remove(at: i) } else { lesiones.append(o) }
                    }
                    Etiqueta("Abono")
                    VStack(spacing: 8) {
                        ForEach(estado.profe.abonos) { a in
                            elegible(a.nombre, "\(a.detalle) · \(Formato.plata(a.precio))", abonoId == a.id) { abonoId = a.id }
                        }
                    }
                    Etiqueta("Horario fijo")
                    VStack(spacing: 8) {
                        ForEach(estado.profe.horario.filter { $0.particular == nil }) { c in
                            elegible(c.nombre, "\(c.dias.map { Fecha.cortos[$0 - 1] }.joined(separator: " · ")) · \(c.hora) · \(c.inscriptos.count)/\(c.cupo)",
                                     claseId == c.id) { claseId = claseId == c.id ? nil : c.id }
                        }
                    }
                    if alumnoId == nil {
                        Tarjeta {
                            DatePicker(selection: $inicio, displayedComponents: .date) {
                                Text("Empieza el").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                            }
                            .tint(Color.berenjena800).environment(\.locale, Locale(identifier: "es_AR"))
                            .padding(.horizontal, 16).frame(minHeight: 60)
                        }
                    }
                }
                .padding(.top, 24).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            .scrollDismissesKeyboard(.interactively)
            Boton(titulo: alumnoId == nil ? "Crear y copiar su link" : "Guardar", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                if let id = alumnoId {
                    estado.actualizar(alumno: id, nombre: nombre, telefono: telefono, objetivo: objetivo, lesiones: lesiones, abonoId: abonoId, claseFijaId: claseId)
                } else {
                    estado.darDeAlta(nombre: nombre, telefono: telefono, objetivo: objetivo, lesiones: lesiones, abonoId: abonoId,
                                     claseFijaId: claseId, inicio: Fecha.iso(inicio))
                }
                dismiss()
            }
            .disabled(nombre.trimmingCharacters(in: .whitespaces).count < 2)
            .opacity(nombre.trimmingCharacters(in: .whitespaces).count < 2 ? 0.45 : 1)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .onAppear {
            guard let id = alumnoId, let a = estado.alumno(id), let d = estado.detalle(id) else { return }
            nombre = a.nombre; telefono = d.telefono; objetivo = d.objetivo; lesiones = d.lesiones; abonoId = d.abonoId; claseId = d.claseFijaId
        }
    }

    private func elegible(_ t: String, _ s: String, _ on: Bool, _ tocar: @escaping () -> Void) -> some View {
        Button { Haptico.seleccion(); tocar() } label: {
            HStack(spacing: 12) {
                NomSub(nombre: t, sub: Text(s))
                Circle().strokeBorder(on ? Color.berenjena800 : Color.arena300, lineWidth: 2)
                    .background(Circle().fill(on ? Color.berenjena800 : .clear).padding(6))
                    .frame(width: 24, height: 24)
            }
            .padding(.horizontal, 16).frame(minHeight: 64)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous).strokeBorder(on ? Color.berenjena800 : Color.arena200, lineWidth: on ? 2 : 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}
