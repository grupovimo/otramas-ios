import SwiftUI

/// Encabezado de una pantalla de gestión: volver + título grande + bajada.
private struct CabezaGestion: View {
    @Environment(\.dismiss) private var dismiss
    let titulo: String
    var bajada: String?
    var atras = "Inicio"
    var body: some View {
        NavBanda(atras: atras, accionAtras: { dismiss() }) { EmptyView() }
        VStack(alignment: .leading, spacing: 6) {
            Titulo(titulo, tamano: 40, color: .hueso)
            if let bajada { Text(bajada).tipo(.texto(15, 400)).foregroundStyle(Color.berenjena300).fixedSize(horizontal: false, vertical: true) }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
    }
}

// MARK: - Herramientas (Inicio)

/// La grilla «Tu negocio» de Inicio: que todo se descubra.
struct Herramientas: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    var body: some View {
        TituloSeccion("Tu negocio")
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
            tile(.plata, "Cobros", "\(estado.pendientesCuotas) pendientes") { nav.inicio.append(.cobros) }
            tile(.recibo, "Planes", "\(estado.profe.abonos.count) abonos") { nav.inicio.append(.planes) }
            tile(.cal, "Clases", "\(estado.profe.horario.count) fijas") { nav.inicio.append(.clases) }
            tile(.wa, "Avisos", "\(estado.profe.avisos.count) enviados") { nav.inicio.append(.avisos) }
            tile(.sube, "Tu mes", "\(estado.enRiesgo.count) en riesgo") { nav.inicio.append(.tuMes) }
            tile(.puntos, "Ajustes", "Cobro, avisos, apps") { nav.inicio.append(.ajustes) }
        }
    }

    private func tile(_ i: Icono, _ t: String, _ s: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            VStack(alignment: .leading, spacing: 6) {
                IconoVista(i, tamano: 20).foregroundStyle(Color.berenjena800)
                    .frame(width: 40, height: 40).background(Color.yema, in: Circle())
                Text(t).tipo(.texto(15, 700)).foregroundStyle(Color.tinta)
                Text(s).tipo(.texto(12, 400)).foregroundStyle(Color.texto2).lineLimit(1).minimumScaleFactor(0.85)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 112, alignment: .topLeading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .sombraTarjeta()
        }
        .buttonStyle(Apretable())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Planes y precios

struct PantallaPlanes: View {
    @Environment(Estado.self) private var estado
    @State private var editar: Abono?
    @State private var aumento = false

    var body: some View {
        PantallaProfe {
            CabezaGestion(titulo: "Planes y precios", bajada: "Tus abonos y quién tiene cada uno.")
            HStack(spacing: 8) {
                Boton(titulo: "Abono nuevo", icono: .mas, variante: .yema, ancho: true) {
                    editar = Abono(id: "a-\(UUID().uuidString.prefix(6))", nombre: "", tipo: .mensual, cantidad: 2, precio: 40000)
                }
                Boton(titulo: "Aumento", icono: .sube, variante: .osc, ancho: true) { aumento = true }
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 16)
        } cuerpo: {
            VStack(spacing: 12) {
                ForEach(estado.profe.abonos) { a in
                    let quienes = estado.alumnos(con: a.id)
                    Button { editar = a } label: {
                        Tarjeta(relleno: 16) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Etiqueta(a.tipo.rawValue, color: .yema700)
                                    Text(a.nombre).tipo(.texto(18, 700)).foregroundStyle(Color.tinta)
                                    Text(a.detalle).tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                                }
                                Spacer()
                                Numero(valor: Formato.plata(a.precio), tamano: 24)
                            }
                            HStack(spacing: 8) {
                                if quienes.isEmpty {
                                    Text("Nadie lo tiene todavía").tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                                } else {
                                    PilaAvatares(ids: quienes.map(\.id))
                                    Text("\(quienes.count) \(quienes.count == 1 ? "alumno" : "alumnos")").tipo(.texto(14, 700)).foregroundStyle(Color.tinta)
                                }
                                Spacer()
                                IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
                            }
                            .padding(.top, 12)
                        }
                    }
                    .buttonStyle(Apretable())
                }
            }
        }
        .sheet(item: $editar) { HojaAbono(abono: $0) }
        .sheet(isPresented: $aumento) { HojaAumento() }
    }
}

struct HojaAbono: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State var abono: Abono
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Abono", titulo: abono.nombre.isEmpty ? "Abono nuevo" : abono.nombre)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Campo(etiqueta: "Nombre", texto: $abono.nombre, ejemplo: "Mensual 2 veces")
                    Etiqueta("Tipo")
                    HStack(spacing: 8) {
                        ForEach(TipoAbono.allCases, id: \.self) { t in
                            Chip(titulo: t == .pack ? "Pack" : t.rawValue, elegido: abono.tipo == t, elegidoOscuro: true, ancho: true) { abono.tipo = t }
                        }
                    }
                    if abono.tipo != .suelta {
                        Tarjeta {
                            Paso(etiqueta: abono.tipo == .mensual ? "Veces por semana" : "Clases",
                                 valor: Binding(get: { Double(abono.cantidad ?? 0) }, set: { abono.cantidad = $0 == 0 ? nil : Int($0) }),
                                 rango: 0...(abono.tipo == .mensual ? 7 : 30),
                                 formato: { $0 == 0 ? "Libre" : String(Int($0)) })
                        }
                    }
                    Campo(etiqueta: "Precio", texto: Binding(get: { String(abono.precio) }, set: { abono.precio = Int($0.filter(\.isNumber)) ?? 0 }),
                          ejemplo: "45000", prefijo: "$", teclado: .numberPad)
                }
                .padding(.top, 24)
            }
            Boton(titulo: "Guardar", icono: .tilde, variante: .prim, alto: .alto, ancho: true) { estado.guardar(abono: abono); dismiss() }
                .disabled(abono.nombre.isEmpty).opacity(abono.nombre.isEmpty ? 0.45 : 1)
                .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
    }
}

/// Aumento masivo con vista previa de cada precio y a cuántos alumnos les llega.
struct HojaAumento: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State private var porcentaje: Double = 10
    @State private var elegidos: Set<String> = []
    @State private var avisar = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Planes y precios", titulo: "Aumento de precios")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Tarjeta { Paso(etiqueta: "Aumento (%)", valor: $porcentaje, rango: 1...100) }
                    Etiqueta("Vista previa")
                    Tarjeta {
                        ForEach(Array(estado.profe.abonos.enumerated()), id: \.element.id) { i, a in
                            if i > 0 { Divisor() }
                            let on = elegidos.contains(a.id)
                            Button { Haptico.seleccion(); if on { elegidos.remove(a.id) } else { elegidos.insert(a.id) } } label: {
                                HStack(spacing: 12) {
                                    IconoVista(.tilde, tamano: 16, grosor: 3).foregroundStyle(on ? Color.yema : .clear)
                                        .frame(width: 26, height: 26)
                                        .background(on ? Color.berenjena800 : .clear, in: RoundedRectangle(cornerRadius: 7))
                                        .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(on ? .clear : Color.arena300, lineWidth: 2))
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(a.nombre).tipo(.texto(15, 700)).foregroundStyle(Color.tinta)
                                        Text("\(estado.alumnos(con: a.id).count) alumnos").tipo(.texto(12, 400)).foregroundStyle(Color.texto2)
                                    }
                                    Spacer()
                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(Formato.plata(a.precio)).tipo(.texto(13, 400)).strikethrough(on).foregroundStyle(Color.texto2)
                                        Text(Formato.plata(on ? estado.conAumento(a.precio, porcentaje) : a.precio)).tipo(.numero(18), alto: 18)
                                            .foregroundStyle(on ? Color.berenjena800 : Color.arena500)
                                            .contentTransition(.numericText())
                                    }
                                }
                                .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    Tarjeta(relleno: 16) {
                        Toggle(isOn: $avisar) {
                            NomSub(nombre: "Avisarles con un mes de anticipación", sub: Text("Por WhatsApp, con el precio nuevo"))
                        }
                        .tint(Color.ok)
                    }
                }
                .padding(.top, 24).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            let n = estado.profe.alumnos.filter { elegidos.contains(estado.detalle($0.id)?.abonoId ?? "") }.count
            Boton(titulo: elegidos.isEmpty ? "Elegí los abonos" : "Aplicar a \(n) alumnos", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                estado.aumentar(porcentaje, abonos: elegidos, avisar: avisar); dismiss()
            }
            .disabled(elegidos.isEmpty).opacity(elegidos.isEmpty ? 0.45 : 1)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .onAppear { elegidos = Set(estado.profe.abonos.filter { $0.tipo == .mensual }.map(\.id)) }
    }
}

// MARK: - Cobros

struct PantallaCobros: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @State private var mes: String?

    var body: some View {
        @Bindable var estado = estado
        let c = estado.profe.cobros
        PantallaProfe {
            CabezaGestion(titulo: "Cobros", bajada: "Cómo te pagan, el recordatorio y la historia de cada mes.")
            HStack(spacing: 8) {
                Boton(titulo: "Ver cuotas", icono: .plata, variante: .yema, ancho: true) { nav.ir(.cuotas) }
                CompartirBoton(generar: { estado.csvCobros() }) {
                    HStack(spacing: 8) { IconoVista(.recibo, tamano: 20); Text("Excel").tipo(.texto(16, 700)) }
                        .foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 48)
                        .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("Exportar cobros a Excel")
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 16)
        } cuerpo: {
            TituloSeccion("Recordatorio automático", arriba: 0)
            Tarjeta(relleno: 16) {
                Toggle(isOn: $estado.profe.cobros.recordatorioActivo) {
                    NomSub(nombre: "Recordarles a los que deben", sub: Text(c.recordatorioActivo ? "El día \(c.diaRecordatorio) de cada mes, por WhatsApp" : "Apagado"))
                }
                .tint(Color.ok)
                if c.recordatorioActivo {
                    Paso(etiqueta: "Día del mes", valor: Binding(get: { Double(c.diaRecordatorio) }, set: { estado.profe.cobros.diaRecordatorio = Int($0) }), rango: 1...28)
                        .padding(.horizontal, -16)
                    Text("«¡Hola! Te recuerdo que la cuota vence el \(c.vence). Podés pagar desde tu link.»")
                        .tipo(.texto(14, 400)).italic().foregroundStyle(Color.arena700).padding(12)
                        .background(Color.arena50, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
            }
            TituloSeccion("Dónde te pagan")
            Tarjeta(relleno: 16) {
                Campo(etiqueta: "Alias", texto: $estado.profe.cobros.alias, ejemplo: "lucia.entrena.mdp")
                Campo(etiqueta: "CBU / CVU", texto: $estado.profe.cobros.cbu, ejemplo: "22 números", teclado: .numberPad).padding(.top, 12)
                Campo(etiqueta: "Titular", texto: $estado.profe.cobros.titular, ejemplo: "Tu nombre").padding(.top, 12)
                Etiqueta("Medios que aceptás").padding(.top, 16)
                ChipsClaros(opciones: MedioPago.allCases.map(\.rawValue), elegidas: Set(c.medios.map(\.rawValue))) { m in
                    guard let mp = MedioPago(rawValue: m) else { return }
                    if let i = estado.profe.cobros.medios.firstIndex(of: mp) { estado.profe.cobros.medios.remove(at: i) } else { estado.profe.cobros.medios.append(mp) }
                }
                .padding(.top, 8)
            }
            TituloSeccion("Historial por mes")
            Tarjeta {
                ForEach(Array(estado.mesesConPagos.enumerated()), id: \.element) { i, m in
                    if i > 0 { Divisor() }
                    let p = estado.pagos(delMes: m)
                    Button { mes = m } label: {
                        HStack {
                            NomSub(nombre: Fecha.mes("\(m)-01").capitalized + " " + m.prefix(4), sub: Text("\(p.count) cuotas"))
                            Text(Formato.plata(p.reduce(0) { $0 + $1.monto })).tipo(.numero(20), alto: 20).foregroundStyle(Color.berenjena800)
                            IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
                        }
                        .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onDisappear { estado.guardar(cobros: estado.profe.cobros) }
        .sheet(item: Binding(get: { mes.map { MesElegido(id: $0) } }, set: { mes = $0?.id })) { HojaMesCobros(mes: $0.id) }
    }

    private struct MesElegido: Identifiable { let id: String }
}

struct HojaMesCobros: View {
    @Environment(Estado.self) private var estado
    let mes: String
    var body: some View {
        let p = estado.pagos(delMes: mes)
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "\(p.count) cuotas · \(Formato.plata(p.reduce(0) { $0 + $1.monto }))", titulo: Fecha.mes("\(mes)-01").capitalized)
            ScrollView {
                Tarjeta {
                    ForEach(Array(p.enumerated()), id: \.element.id) { i, x in
                        if i > 0 { Divisor() }
                        HStack {
                            NomSub(nombre: estado.alumno(x.alumnoId)?.nombre ?? x.alumnoId, sub: Text("\(x.medio.rawValue) · el \(Fecha.corta(x.fecha))"))
                            Text(Formato.plata(x.monto)).tipo(.numero(18), alto: 18).foregroundStyle(Color.tinta)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }
                }
                .padding(.top, 20).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            CompartirBoton(generar: { estado.csvCobros(mes: mes) }) {
                HStack(spacing: 8) { IconoVista(.recibo, tamano: 20).foregroundStyle(Color.yema); Text("Exportar a Excel (CSV)").tipo(.texto(16, 700)) }
                    .foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            }
            .buttonStyle(Apretable())
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
    }
}

// MARK: - Clases

struct PantallaClases: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @State private var editar: ClaseFija?
    @State private var nueva: String?

    var body: some View {
        PantallaProfe {
            CabezaGestion(titulo: "Clases", bajada: "Tu horario fijo, la lista de espera y las clases especiales.")
            HStack(spacing: 8) {
                Boton(titulo: "Clase fija", icono: .mas, variante: .yema, ancho: true) { nueva = estado.hoy }
                Boton(titulo: "Evento", icono: .estrella, variante: .osc, ancho: true) { nueva = Fecha.sumar(4, a: estado.hoy) }
                Boton(titulo: "Semana", icono: .cal, variante: .osc, ancho: true) { nav.inicio.append(.horario) }
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 16)
        } cuerpo: {
            TituloSeccion("Todas las semanas", arriba: 0)
            VStack(spacing: 12) {
                ForEach(estado.profe.horario) { c in
                    Button { editar = c } label: {
                        Tarjeta(relleno: 16) {
                            HStack(spacing: 16) {
                                Text(c.hora).tipo(.numero(28), alto: 28).foregroundStyle(Color.berenjena800).frame(width: 72, alignment: .leading)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(c.nombre).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                                    Text("\(c.dias.map { Fecha.cortos[$0 - 1] }.joined(separator: " · ")) · \(c.lugar)").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                                    if !c.espera.isEmpty {
                                        Text("\(c.espera.count) en lista de espera").tipo(.texto(13, 700)).foregroundStyle(Color.yema700)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                Text("\(c.inscriptos.count)/\(c.cupo)").tipo(.numero(16), alto: 16)
                                    .foregroundStyle(c.inscriptos.count >= c.cupo ? Color.error : Color.berenjena800)
                            }
                        }
                    }
                    .buttonStyle(Apretable())
                }
            }
            TituloSeccion("Especiales")
            let unicas = estado.profe.clasesUnicas
            if unicas.isEmpty {
                Tarjeta(relleno: 20) {
                    Text("Ninguna por ahora").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                    Text("Una clase en la playa, un entrenamiento abierto, una clase de prueba.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        .fixedSize(horizontal: false, vertical: true).padding(.top, 4)
                    Boton(titulo: "Sumar un evento", icono: .estrella, variante: .prim, alto: .chico, ancho: true) { nueva = Fecha.sumar(4, a: estado.hoy) }
                        .padding(.top, 12)
                }
            } else {
                Tarjeta {
                    ForEach(Array(unicas.enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Divisor() }
                        HStack {
                            NomSub(nombre: c.nombre, sub: Text("\(Fecha.largo(c.fecha ?? estado.hoy)) · \(c.hora) · \(c.lugar)"))
                            Button { nav.hoja = .clase(c.id) } label: { Text("Ver").tipo(.texto(15, 700)).foregroundStyle(Color.yema700).frame(height: 44) }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 8)
                    }
                }
            }
        }
        .sheet(item: $editar) { HojaEditarClase(clase: $0) }
        .sheet(item: Binding(get: { nueva.map { FechaId(id: $0) } }, set: { nueva = $0?.id })) { HojaNuevaClase(fecha: $0.id) }
    }

    private struct FechaId: Identifiable { let id: String }
}

struct HojaEditarClase: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State var clase: ClaseFija
    @State private var borrar = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Clase fija", titulo: clase.nombre)
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Campo(etiqueta: "Nombre", texto: $clase.nombre, ejemplo: "Funcional")
                    HStack(spacing: 12) {
                        Campo(etiqueta: "Hora", texto: $clase.hora, ejemplo: "18:00")
                        Campo(etiqueta: "Lugar", texto: $clase.lugar, ejemplo: "Plaza Mitre")
                    }
                    Tarjeta { Paso(etiqueta: "Cupo", valor: Binding(get: { Double(clase.cupo) }, set: { clase.cupo = Int($0) }), rango: 1...40) }
                    Etiqueta("Días")
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { d in
                            let on = clase.dias.contains(d)
                            Button { if on { clase.dias.removeAll { $0 == d } } else { clase.dias.append(d); clase.dias.sort() } } label: {
                                Text(Fecha.cortos[d - 1].uppercased()).tipo(.etiqueta).foregroundStyle(on ? Color.yema : Color.berenjena800)
                                    .frame(maxWidth: .infinity).frame(height: 48)
                                    .background(on ? Color.berenjena800 : Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                            }
                            .buttonStyle(Apretable())
                        }
                    }
                    TituloSeccion(texto: "Lista de espera", arriba: 8) {
                        Text("\(clase.espera.count)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    }
                    if clase.espera.isEmpty {
                        Text("Nadie espera lugar. Cuando la clase se llena, quien quiera sumarse queda acá.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                    } else {
                        Tarjeta {
                            ForEach(Array(clase.espera.enumerated()), id: \.element) { i, id in
                                if i > 0 { Divisor() }
                                HStack {
                                    NomSub(nombre: estado.alumno(id)?.nombre ?? id, sub: Text("\(i + 1).º en la lista"))
                                    Boton(titulo: "Darle lugar", variante: .suave, alto: .chico) {
                                        estado.pasarDeEspera(id, en: clase.id)
                                        clase.espera.removeAll { $0 == id }; clase.inscriptos.append(id)
                                    }
                                }
                                .padding(.horizontal, 16).padding(.vertical, 8)
                            }
                        }
                    }
                    Button { borrar = true } label: {
                        Text("Sacar esta clase del horario").tipo(.texto(15, 700)).foregroundStyle(Color.error).frame(maxWidth: .infinity).frame(height: 48)
                    }
                }
                .padding(.top, 24).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            Boton(titulo: "Guardar", icono: .tilde, variante: .prim, alto: .alto, ancho: true) { estado.guardar(claseFija: clase); dismiss() }
                .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .confirmationDialog("¿Sacar «\(clase.nombre)» de tu horario?", isPresented: $borrar, titleVisibility: .visible) {
            Button("Sacar", role: .destructive) { estado.borrar(claseFija: clase.id); dismiss() }
            Button("Cancelar", role: .cancel) {}
        }
    }
}

// MARK: - Avisos

struct PantallaAvisos: View {
    @Environment(Estado.self) private var estado
    @State private var nuevo = false
    var body: some View {
        PantallaProfe {
            CabezaGestion(titulo: "Avisos", bajada: "Lluvia, feriado, cambio de horario: a toda la clase de una.")
            Boton(titulo: "Mandar un aviso", icono: .wa, variante: .yema, ancho: true) { nuevo = true }
                .padding(.horizontal, Espacio.margen).padding(.top, 16)
        } cuerpo: {
            TituloSeccion(texto: "Enviados", arriba: 0) { Text("\(estado.profe.avisos.count)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2) }
            if estado.profe.avisos.isEmpty {
                Tarjeta(relleno: 20) { Text("Todavía no mandaste avisos.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2) }
            }
            VStack(spacing: 12) {
                ForEach(estado.profe.avisos) { a in TarjetaAviso(aviso: a) }
            }
        }
        .sheet(isPresented: $nuevo) { HojaAviso() }
    }
}

struct TarjetaAviso: View {
    let aviso: AvisoProfe
    var body: some View {
        Tarjeta(relleno: 16) {
            HStack {
                Etiqueta(aviso.titulo, color: .yema700)
                Spacer()
                Text(Fecha.corta(aviso.fecha)).tipo(.texto(13, 600)).foregroundStyle(Color.arena500)
            }
            Text(aviso.texto).tipo(.texto(15, 400)).foregroundStyle(Color.tinta).padding(.top, 6).fixedSize(horizontal: false, vertical: true)
            Text("Para: \(aviso.para) · \(aviso.cantidad) personas").tipo(.texto(13, 600)).foregroundStyle(Color.texto2).padding(.top, 8)
        }
        .accessibilityElement(children: .combine)
    }
}

struct HojaAviso: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State private var plantilla = "Lluvia"
    @State private var texto = plantillasAviso[0].1
    @State private var para = "Todos"

    var body: some View {
        let grupos = ["Todos", "Los que deben"] + Array(Set(estado.profe.horario.filter { $0.particular == nil }.map(\.nombre))).sorted()
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Por WhatsApp", titulo: "Mandar un aviso")
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Etiqueta("Plantilla")
                    ChipsClaros(opciones: plantillasAviso.map(\.0), elegidas: [plantilla]) { p in
                        plantilla = p; texto = plantillasAviso.first { $0.0 == p }?.1 ?? texto
                    }
                    Campo(etiqueta: "Mensaje", texto: $texto, ejemplo: "Escribí el aviso", varias: true)
                    Etiqueta("Para quién")
                    ChipsClaros(opciones: grupos, elegidas: [para]) { para = $0 }
                    Text("Le llega a \(Set(estado.destinatarios(para)).count) personas desde el número de Otra Más, con tu nombre.")
                        .tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                }
                .padding(.top, 24).padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            Boton(titulo: "Mandar a \(Set(estado.destinatarios(para)).count)", icono: .wa, variante: .prim, alto: .alto, ancho: true) {
                estado.enviar(aviso: plantilla, texto: texto, para: para); dismiss()
            }
            .disabled(texto.isEmpty)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
    }
}

// MARK: - Ajustes del profe

struct AjustesProfe: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @AppStorage("lado") private var lado = ""
    @State private var perfil = false
    @State private var integracion: Integracion?
    @State private var ayuda = false

    var body: some View {
        @Bindable var estado = estado
        let p = estado.perfilProfe
        PantallaProfe {
            CabezaGestion(titulo: "Ajustes")
            HStack(spacing: 12) {
                FotoPerfil(perfil: p, tamano: 56)
                VStack(alignment: .leading, spacing: 2) {
                    Text(p.nombre).tipo(.texto(18, 700)).foregroundStyle(Color.hueso)
                    Text("Tu perfil está al \(p.completitud) %").tipo(.texto(14, 400)).foregroundStyle(Color.berenjena300)
                }
                Spacer()
                Boton(titulo: "Ver", variante: .osc, alto: .chico) { perfil = true }
            }
            .padding(.horizontal, Espacio.margen).padding(.top, 16)
        } cuerpo: {
            TituloSeccion("Tu link público", arriba: 0)
            Tarjeta(relleno: 16) {
                Text("otramas.com.ar/\(p.usuario)").tipo(.texto(17, 700)).foregroundStyle(Color.tinta)
                HStack(spacing: 8) {
                    Boton(titulo: "Copiar", icono: .copiar, variante: .suave, alto: .chico, ancho: true) {
                        UIPasteboard.general.string = p.link.absoluteString; estado.avisar("Link copiado.")
                    }
                    ShareLink(item: p.link) {
                        Text("Compartir").tipo(.texto(16, 700)).foregroundStyle(Color.hueso).frame(maxWidth: .infinity).frame(height: 44)
                            .background(Color.berenjena800, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    }
                }
                .padding(.top, 12)
            }
            TituloSeccion("Tu trabajo")
            Tarjeta {
                fila(.rayo, "Tu plan de Otra Más", estado.enPrueba ? "Pro · te quedan \(estado.diasDePrueba) días de prueba" : "\(estado.suscripcion.plan.nombre) · \(estado.activos) de \(estado.tope) alumnos") { nav.inicio.append(.plan) }
                Divisor()
                fila(.plata, "Cobros", "Alias, medios y recordatorio") { nav.inicio.append(.cobros) }
                Divisor()
                fila(.recibo, "Planes y precios", "\(estado.profe.abonos.count) abonos") { nav.inicio.append(.planes) }
                Divisor()
                fila(.cal, "Horarios y clases", "\(estado.profe.horario.count) clases fijas") { nav.inicio.append(.clases) }
                Divisor()
                fila(.wa, "Avisos", "Plantillas e historial") { nav.inicio.append(.avisos) }
            }
            TituloSeccion("Notificaciones")
            Tarjeta {
                ForEach(Array(estado.profe.notificaciones.keys.sorted().enumerated()), id: \.element) { i, k in
                    if i > 0 { Divisor() }
                    Toggle(isOn: Binding(get: { estado.profe.notificaciones[k] ?? false }, set: { estado.profe.notificaciones[k] = $0 })) {
                        Text(k).tipo(.texto(16, 600)).foregroundStyle(Color.tinta)
                    }
                    .tint(Color.ok).padding(.horizontal, 16).frame(minHeight: 56)
                }
            }
            TituloSeccion("Integraciones")
            Tarjeta {
                ForEach(Array(estado.profe.integraciones.enumerated()), id: \.element.id) { i, x in
                    if i > 0 { Divisor() }
                    Button { integracion = x } label: {
                        HStack(spacing: 12) {
                            LogoIntegracion(id: x.id)
                            NomSub(nombre: x.nombre, sub: Text(x.para))
                            Text(x.conectada ? "Conectada" : "Conectar").tipo(.texto(13, 700))
                                .foregroundStyle(x.conectada ? Color.ok : Color.yema700)
                        }
                        .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            TituloSeccion("Tus datos")
            Tarjeta {
                CompartirBoton(generar: { estado.exportarTodo() }) {
                    filaContenido(.recibo, "Exportar todos tus datos", "Alumnos, clases, rutinas y cobros (JSON)")
                }
                .buttonStyle(.plain)
                Divisor()
                CompartirBoton(generar: { estado.csvCobros() }) {
                    filaContenido(.plata, "Cobros a Excel", "Todos los meses (CSV)")
                }
                .buttonStyle(.plain)
            }
            TituloSeccion("Ayuda")
            Tarjeta {
                fila(.estrella, "Preguntas frecuentes", "Cobros, rutinas, alumnos") { ayuda = true }
                Divisor()
                fila(.wa, "Escribinos", "Te responde una persona") { estado.avisar("Abrimos WhatsApp con el equipo de Otra Más.") }
                Divisor()
                fila(.cambio, "Ver la app del alumno", "Para mostrarle cómo la ve") { withAnimation { lado = Lado.alumno.rawValue } }
            }
            Button { withAnimation { estado.borrarPerfil(); lado = "" } } label: {
                Text("Cerrar sesión").tipo(.texto(16, 700)).foregroundStyle(Color.error)
                    .frame(maxWidth: .infinity).frame(height: 52)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            }
            .buttonStyle(Apretable())
            .padding(.top, 8)
            .accessibilityHint("Vuelve a elegir profe o alumno")
        }
        .onDisappear { estado.guardar(cobros: estado.profe.cobros) }
        .sheet(isPresented: $perfil) { TuPerfil() }
        .sheet(item: $integracion) { HojaIntegracion(integracion: $0) }
        .sheet(isPresented: $ayuda) { HojaAyuda() }
    }

    private func fila(_ i: Icono, _ t: String, _ s: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) { filaContenido(i, t, s) }.buttonStyle(.plain)
    }

    private func filaContenido(_ i: Icono, _ t: String, _ s: String) -> some View {
        HStack(spacing: 12) {
            IconoVista(i, tamano: 20).foregroundStyle(Color.berenjena800).frame(width: 40, height: 40).background(Color.berenjena100, in: Circle())
            NomSub(nombre: t, sub: Text(s))
            IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
        }
        .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
    }
}

struct LogoIntegracion: View {
    let id: String
    var body: some View {
        let (t, c): (String, Color) = {
            switch id {
            case "mp": return ("MP", Color(hex: 0x009EE3))
            case "gcal": return ("31", Color(hex: 0x1A73E8))
            case "sheets": return ("▦", Color(hex: 0x188038))
            default: return ("♥", Color.salud)
            }
        }()
        Text(t).font(.system(size: 15, weight: .heavy)).foregroundStyle(.white)
            .frame(width: 40, height: 40).background(c, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// Pantalla de conexión (simulada) de una integración.
struct HojaIntegracion: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let integracion: Integracion
    @State private var conectando = false

    var body: some View {
        let x = estado.profe.integraciones.first { $0.id == integracion.id } ?? integracion
        VStack(alignment: .leading, spacing: 16) {
            CabezaHoja(etiqueta: "Integración", titulo: x.nombre)
            HStack(spacing: 16) {
                LogoIntegracion(id: x.id).scaleEffect(1.4).frame(width: 56, height: 56)
                Image(systemName: "arrow.left.arrow.right").foregroundStyle(Color.arena500)
                Image("mas-uno").resizable().scaledToFit().frame(width: 56)
            }
            .frame(maxWidth: .infinity).padding(.vertical, 8)
            Text(x.para).tipo(.texto(18, 700)).foregroundStyle(Color.tinta)
            Text(explicacion(x.id)).tipo(.texto(15, 400)).foregroundStyle(Color.texto2).fixedSize(horizontal: false, vertical: true)
            Spacer()
            if x.conectada {
                HStack(spacing: 8) { IconoVista(.tilde, tamano: 20); Text("Conectada").tipo(.texto(16, 700)) }
                    .foregroundStyle(Color.ok).frame(maxWidth: .infinity).frame(height: 48)
                    .background(Color.okFondo, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                Button { estado.conectar(x.id, false); dismiss() } label: {
                    Text("Desconectar").tipo(.texto(15, 700)).foregroundStyle(Color.error).frame(maxWidth: .infinity).frame(height: 48)
                }
            } else {
                Boton(titulo: conectando ? "Conectando…" : "Conectar \(x.nombre)", variante: .prim, alto: .alto, ancho: true) {
                    conectando = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) { estado.conectar(x.id, true); dismiss() }
                }
                .disabled(conectando)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.bottom, 8)
        .estiloHoja([.medium])
    }

    private func explicacion(_ id: String) -> String {
        switch id {
        case "mp": return "Cada alumno recibe su link de pago. Cuando paga, la cuota queda al día sola y te llega el aviso. Sin comisión de Otra Más."
        case "gcal": return "Tus clases fijas y especiales aparecen en tu Google Calendar, y se actualizan cuando suspendés una."
        case "sheets": return "Una planilla con todos los cobros, que se completa sola cada vez que alguien paga."
        default: return "Si tus alumnos lo permiten, ves sus pasos del día en la ficha. Nada más de su salud."
        }
    }
}

struct HojaAyuda: View {
    private let preguntas: [(String, String)] = [
        ("¿Cómo cobro sin perseguir a nadie?", "Activá el recordatorio automático en Cobros. A los que deben les llega un WhatsApp el día que elijas, con su link de pago."),
        ("¿Mis alumnos tienen que bajarse la app?", "No. Les llega un link y ven su rutina, sus clases y su cuota desde el navegador. Si quieren, bajan la app."),
        ("¿Puedo usar una plantilla y cambiarla?", "Sí. En Rutinas, abrí una plantilla y tocá «Usar como base». Queda en Mías y la editás."),
        ("¿Qué pasa si suspendo una clase?", "Les avisamos a todos y, si lo dejás activado, les queda para recuperar otro día."),
        ("¿Mis datos son míos?", "Sí. En Ajustes › Tus datos los exportás cuando quieras."),
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Ayuda", titulo: "Preguntas frecuentes")
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(preguntas, id: \.0) { p, r in
                        Tarjeta(relleno: 16) {
                            Text(p).tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                            Text(r).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .padding(.top, 20).padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
    }
}
