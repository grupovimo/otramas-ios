import SwiftUI
import PhotosUI

enum DestinoAlumno: Hashable { case historial, progreso, clases, pagos, avisos, perfil }

/// Pantalla de la app del alumno con banda y volver.
private struct PantallaSub<C: View>: View {
    @Environment(\.dismiss) private var dismiss
    let titulo: String
    var bajada: String?
    @ViewBuilder var cuerpo: () -> C
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Banda {
                    NavBanda(atras: "Más", accionAtras: { dismiss() }) { EmptyView() }
                    VStack(alignment: .leading, spacing: 6) {
                        Titulo(titulo, tamano: 40, color: .hueso)
                        if let bajada { Text(bajada).tipo(.texto(15, 400)).foregroundStyle(Color.berenjena300) }
                    }
                    .padding(.horizontal, Espacio.margen).padding(.top, 8)
                }
                VStack(alignment: .leading, spacing: 0) { cuerpo() }
                    .padding(.horizontal, Espacio.margen).padding(.top, 24).padding(.bottom, 32)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.hueso.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Pestaña «Más»: todo lo del alumno, a la vista.
struct MasAlumno: View {
    @Environment(Estado.self) private var estado
    @State private var camino: [DestinoAlumno]

    init(inicial: DestinoAlumno? = nil) { _camino = State(initialValue: inicial.map { [$0] } ?? []) }

    var body: some View {
        let a = estado.alumno
        NavigationStack(path: $camino) {
            PantallaAlumno {
                CabeceraAlumno(profe: a.profe, alumno: a.nombre, foto: a.fotoProfe)
                Titulo("Más", tamano: 40, color: .hueso).padding(.horizontal, Espacio.margen).padding(.top, 20)
            } cuerpo: {
                Tarjeta {
                    fila(.historial, .cal, "Historial", "\(a.historial.filter { $0.fecha.hasPrefix("2026-11") }.count) entrenamientos en noviembre")
                    Divisor()
                    fila(.progreso, .sube, "Progreso", "Peso, medidas y récords")
                    Divisor()
                    fila(.clases, .reloj, "Mis clases", a.plan.paraRecuperar > 0 ? "\(a.plan.paraRecuperar) para recuperar" : "Tu horario fijo")
                    Divisor()
                    fila(.pagos, .plata, "Pagos", a.cuotaPagada ? "Diciembre pagado" : a.comprobanteEnRevision ? "Comprobante en revisión" : "Diciembre · \(Formato.plata(a.plan.proximoMonto))",
                         alerta: !a.cuotaPagada && !a.comprobanteEnRevision)
                    Divisor()
                    fila(.avisos, .wa, "Avisos de \(a.profe)", "\(estado.avisosDelAlumno.count) avisos")
                    Divisor()
                    fila(.perfil, .gente, "Tu perfil", "Tus datos y Apple Salud")
                }
                if let t = estado.tip(.alumno, salto: 3) { TipVista(tip: t).padding(.top, 24) }
                BannerGrupo(.deAPoco)
            }
            .navigationDestination(for: DestinoAlumno.self) { d in
                switch d {
                case .historial: HistorialAlumno()
                case .progreso: ProgresoAlumno()
                case .clases: MisClases()
                case .pagos: PagosAlumno()
                case .avisos: AvisosAlumno()
                case .perfil: PerfilAlumnoVista()
                }
            }
        }
    }

    private func fila(_ d: DestinoAlumno, _ i: Icono, _ t: String, _ s: String, alerta: Bool = false) -> some View {
        NavigationLink(value: d) {
            HStack(spacing: 12) {
                IconoVista(i, tamano: 20).foregroundStyle(Color.berenjena800).frame(width: 40, height: 40).background(Color.berenjena100, in: Circle())
                NomSub(nombre: t, sub: Text(s))
                if alerta { Circle().fill(Color.yema).frame(width: 10, height: 10).accessibilityLabel("Pendiente") }
                IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
            }
            .padding(.horizontal, 16).frame(minHeight: 64).contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Historial

struct HistorialAlumno: View {
    @Environment(Estado.self) private var estado
    @State private var mes = "2026-11"
    @State private var dia: String?

    var body: some View {
        let hechos = Dictionary(uniqueKeysWithValues: estado.alumno.historial.map { ($0.fecha, $0) })
        let delMes = estado.alumno.historial.filter { $0.fecha.hasPrefix(mes) }
        PantallaSub(titulo: "Historial", bajada: "Lo que entrenaste, día por día.") {
            HStack {
                flecha(.atras, mes > "2026-09") { mes = mover(-1) }
                Spacer()
                Text(Fecha.mes("\(mes)-01").capitalized + " " + mes.prefix(4)).tipo(.texto(18, 700)).foregroundStyle(Color.tinta)
                Spacer()
                flecha(.der, mes < "2026-11") { mes = mover(1) }
            }
            Tarjeta(relleno: 12) {
                HStack(spacing: 0) {
                    ForEach(Fecha.cortos, id: \.self) { d in
                        Text(String(d.prefix(1))).tipo(.etiqueta).foregroundStyle(Color.texto2).frame(maxWidth: .infinity)
                    }
                }
                let primero = "\(mes)-01"
                let vacios = Fecha.diaSemana(primero) - 1
                let dias = Fecha.calendario.range(of: .day, in: .month, for: Fecha.fecha(primero))?.count ?? 30
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 6) {
                    ForEach(0..<(vacios + dias), id: \.self) { k in
                        if k < vacios { Color.clear.frame(height: 40) } else {
                            let iso = String(format: "%@-%02d", mes, k - vacios + 1)
                            let hecho = hechos[iso] != nil
                            let hoy = iso == estado.hoy
                            Button { if hecho { Haptico.seleccion(); dia = iso } } label: {
                                Text("\(k - vacios + 1)").tipo(.numero(16), alto: 16)
                                    .foregroundStyle(hecho ? Color.yema : iso > estado.hoy ? Color.arena300 : Color.tinta)
                                    .frame(maxWidth: .infinity).frame(height: 40)
                                    .background(hecho ? (dia == iso ? Color.berenjena600 : Color.berenjena800) : Color.clear,
                                                in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                                    .overlay { if hoy { RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.yema, lineWidth: 2) } }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(Fecha.largo(iso))\(hecho ? ", entrenaste" : "")")
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding(.top, 12)
            HStack(spacing: 12) {
                resumen("\(delMes.count)", "entrenamientos")
                resumen("\(delMes.reduce(0) { $0 + $1.minutos } / 60) h", "entrenando")
                resumen(Formato.miles(delMes.reduce(0) { $0 + $1.volumen }), "kg movidos")
            }
            .padding(.top, 12)
            if let d = dia.flatMap({ hechos[$0] }) ?? delMes.last {
                TituloSeccion(Fecha.largo(d.fecha))
                Tarjeta(relleno: 16) {
                    Etiqueta("\(d.rutina) · \(d.dia)", color: .yema700)
                    Text("\(d.minutos) min · \(d.series) series · \(Formato.miles(d.volumen)) kg").tipo(.texto(16, 700)).foregroundStyle(Color.tinta).padding(.top, 4)
                    ForEach(d.ejercicios, id: \.self) { e in
                        HStack(spacing: 8) {
                            IconoVista(.tilde, tamano: 14, grosor: 3).foregroundStyle(Color.ok)
                            Text(e).tipo(.texto(15, 400)).foregroundStyle(Color.arena700)
                        }
                        .padding(.top, 6)
                    }
                }
            } else {
                Tarjeta(relleno: 20) { Text("Este mes todavía no entrenaste. ¡Hoy es un buen día!").tipo(.texto(15, 400)).foregroundStyle(Color.texto2) }
                    .padding(.top, 24)
            }
        }
    }

    private func mover(_ d: Int) -> String {
        let f = Fecha.calendario.date(byAdding: .month, value: d, to: Fecha.fecha("\(mes)-01")) ?? Date()
        dia = nil
        return String(Fecha.iso(f).prefix(7))
    }

    private func flecha(_ i: Icono, _ on: Bool, _ a: @escaping () -> Void) -> some View {
        Button(action: a) { IconoVista(i, tamano: 20).foregroundStyle(on ? Color.berenjena800 : Color.arena300).frame(width: 44, height: 44) }
            .disabled(!on)
            .accessibilityLabel(i == .atras ? "Mes anterior" : "Mes siguiente")
    }

    private func resumen(_ n: String, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(n).tipo(.numero(22), alto: 22).foregroundStyle(Color.berenjena800)
            Text(l).tipo(.texto(12, 600)).foregroundStyle(Color.texto2)
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
        .sombraTarjeta()
    }
}

// MARK: - Progreso

struct ProgresoAlumno: View {
    @Environment(Estado.self) private var estado
    @State private var medicion = false
    var body: some View {
        let d = estado.detalle(estado.idAlumnoPropio)
        let m = (d?.mediciones ?? []).sorted { $0.fecha < $1.fecha }
        PantallaSub(titulo: "Progreso", bajada: "Cómo venís desde que empezaste.") {
            TituloSeccion(texto: "Peso", arriba: 0) {
                Button { medicion = true } label: { Text("Sumar").tipo(.texto(15, 700)).foregroundStyle(Color.yema700).frame(height: 44) }
            }
            if let u = m.last, let p = m.first {
                Tarjeta(relleno: 16) {
                    HStack(alignment: .bottom) {
                        Numero(valor: Formato.decimal(u.peso), tamano: 32, unidad: "kg")
                        Spacer()
                        Text("\(Formato.decimal(((p.peso - u.peso) * 10).rounded() / 10)) kg menos desde \(Fecha.mes(p.fecha))").tipo(.texto(14, 700)).foregroundStyle(Color.ok)
                    }
                    GraficoProgreso(valores: m.map(\.peso), meses: m.map { Fecha.mes($0.fecha).prefix(3).uppercased() },
                                    minimo: (m.map(\.peso).min() ?? 60) - 2, maximo: (m.map(\.peso).max() ?? 90) + 2,
                                    marcas: [(m.map(\.peso).min() ?? 60).rounded(), (m.map(\.peso).max() ?? 90).rounded()])
                        .padding(.top, 8)
                    HStack(spacing: 8) {
                        if let g = u.grasa { dato("Grasa", "\(Formato.decimal(g)) %") }
                        if let c = u.cintura { dato("Cintura", "\(Formato.decimal(c)) cm") }
                    }
                    .padding(.top, 12)
                }
            }
            TituloSeccion("Tus récords")
            Tarjeta {
                ForEach(Array((d?.marcas ?? []).enumerated()), id: \.element.id) { i, r in
                    if i > 0 { Divisor() }
                    HStack(spacing: 12) {
                        if let e = estado.ejercicio(r.ejercicioId) {
                            IlustracionEjercicio(ejercicio: e, sexo: estado.sexoIlustracion).frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                        }
                        NomSub(nombre: estado.ejercicio(r.ejercicioId)?.nombre ?? r.ejercicioId, sub: Text("El \(Fecha.corta(r.fecha))"))
                        Numero(valor: Formato.decimal(r.kilos), tamano: 24, unidad: "kg")
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
            }
            TituloSeccion("Evaluaciones")
            Tarjeta {
                let g = Dictionary(grouping: d?.evaluaciones ?? [], by: \.nombre).sorted { $0.key < $1.key }
                ForEach(Array(g.enumerated()), id: \.element.key) { i, x in
                    if i > 0 { Divisor() }
                    let h = x.value.sorted { $0.fecha < $1.fecha }
                    HStack {
                        NomSub(nombre: x.key, sub: Text(h.map { "\(Formato.decimal($0.valor)) \($0.unidad)" }.joined(separator: " → ")))
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
            }
        }
        .sheet(isPresented: $medicion) { HojaMedicion(alumnoId: estado.idAlumnoPropio) }
    }

    private func dato(_ e: String, _ v: String) -> some View {
        VStack(alignment: .leading, spacing: 2) { Etiqueta(e); Text(v).tipo(.numero(18), alto: 18).foregroundStyle(Color.berenjena800) }
            .padding(10).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.arena50, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
    }
}

// MARK: - Mis clases

struct MisClases: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let a = estado.alumno
        PantallaSub(titulo: "Mis clases", bajada: "Tu horario fijo, avisar si faltás y recuperar.") {
            Tarjeta(relleno: 16) {
                Etiqueta("Tu horario fijo")
                Text("Martes y jueves · 10:30").tipo(.texto(20, 700)).foregroundStyle(Color.tinta).padding(.top, 4)
                Text("Particular con \(a.profe) · \(a.plan.proxima.lugar)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            TituloSeccion("Próximas")
            Tarjeta {
                ForEach(Array(estado.proximasDelAlumno.prefix(5).enumerated()), id: \.element.id) { i, c in
                    if i > 0 { Divisor() }
                    let falta = a.faltas.contains(c.id)
                    let recupera = a.reservas.contains(c.id)
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Etiqueta(Fecha.cortos[Fecha.diaSemana(c.fecha ?? estado.hoy) - 1] + " " + String(Fecha.numero(c.fecha ?? estado.hoy)), color: .yema700)
                            Text(c.hora).tipo(.numero(22), alto: 22).foregroundStyle(Color.berenjena800)
                        }
                        .frame(width: 64, alignment: .leading)
                        NomSub(nombre: recupera ? "\(c.nombre) · recuperás" : c.nombre, sub: Text(c.lugar))
                        if falta {
                            Text("Avisaste").tipo(.texto(13, 700)).foregroundStyle(Color.texto2)
                        } else if !recupera {
                            Boton(titulo: "Falto", variante: .suave, alto: .chico) { estado.avisarFalta(en: c.id) }
                        }
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
            }
            TituloSeccion(texto: "Recuperar") {
                Text(a.plan.paraRecuperar == 1 ? "Te queda 1" : "Te quedan \(a.plan.paraRecuperar)").tipo(.texto(14, 600)).foregroundStyle(Color.texto2)
            }
            if a.plan.paraRecuperar == 0 {
                Tarjeta(relleno: 20) {
                    Text("No tenés clases para recuperar.").tipo(.texto(15, 600)).foregroundStyle(Color.tinta)
                    Text("Si avisás que faltás, te queda una para recuperar en otra clase con lugar.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4)
                }
            } else {
                Tarjeta {
                    ForEach(Array(estado.paraRecuperar.prefix(6).enumerated()), id: \.element.id) { i, c in
                        if i > 0 { Divisor() }
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Etiqueta(Fecha.cortos[Fecha.diaSemana(c.fecha ?? estado.hoy) - 1] + " " + String(Fecha.numero(c.fecha ?? estado.hoy)), color: .yema700)
                                Text(c.hora).tipo(.numero(22), alto: 22).foregroundStyle(Color.berenjena800)
                            }
                            .frame(width: 64, alignment: .leading)
                            NomSub(nombre: c.nombre, sub: Text("\(c.lugar) · \(c.cupo - c.vienen) lugares"))
                            Boton(titulo: "Reservar", variante: .prim, alto: .chico) { estado.reservar(c.id) }
                        }
                        .padding(.horizontal, 16).padding(.vertical, 10)
                    }
                }
            }
        }
    }
}

// MARK: - Pagos

struct PagosAlumno: View {
    @Environment(Estado.self) private var estado
    @State private var mp = false
    @State private var comprobante: PhotosPickerItem?

    var body: some View {
        let a = estado.alumno
        let pagos = (estado.detalle(estado.idAlumnoPropio)?.pagos ?? []).sorted { $0.fecha > $1.fecha }
        PantallaSub(titulo: "Pagos", bajada: "Tu cuota, cómo pagarla y lo que ya pagaste.") {
            Tarjeta(relleno: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Etiqueta("Diciembre · \(a.plan.nombre)")
                        Numero(valor: Formato.plata(a.plan.proximoMonto), tamano: 36)
                        Text(a.cuotaPagada ? "Pagada. ¡Gracias!" : a.comprobanteEnRevision ? "Comprobante enviado: \(a.profe) lo revisa" : "Vence el 10/12")
                            .tipo(.texto(14, 700)).foregroundStyle(a.cuotaPagada ? Color.ok : a.comprobanteEnRevision ? Color.yema700 : Color.texto2)
                    }
                    Spacer()
                    if a.cuotaPagada {
                        IconoVista(.tilde, tamano: 24, grosor: 2.6).foregroundStyle(Color.ok).frame(width: 48, height: 48).background(Color.okFondo, in: Circle())
                    }
                }
                if !a.cuotaPagada {
                    Boton(titulo: "Pagar con Mercado Pago", variante: .yema, alto: .alto, ancho: true) { mp = true }.padding(.top, 16)
                    PhotosPicker(selection: $comprobante, matching: .images) {
                        HStack(spacing: 8) { IconoVista(.recibo, tamano: 20); Text(a.comprobanteEnRevision ? "Cambiar comprobante" : "Subir comprobante de transferencia").tipo(.texto(16, 700)) }
                            .foregroundStyle(Color.berenjena800).frame(maxWidth: .infinity).frame(height: 48)
                            .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    }
                    .padding(.top, 8)
                    HStack {
                        Text("Alias").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        Text(a.plan.alias).tipo(.texto(15, 700)).foregroundStyle(Color.tinta)
                        Spacer()
                        Button { UIPasteboard.general.string = a.plan.alias; estado.avisar("Alias copiado.") } label: {
                            Text("Copiar").tipo(.texto(14, 700)).foregroundStyle(Color.yema700).frame(height: 44)
                        }
                    }
                    .padding(.top, 4)
                }
            }
            TituloSeccion("Lo que pagaste")
            Tarjeta {
                ForEach(Array(pagos.enumerated()), id: \.element.id) { i, p in
                    if i > 0 { Divisor() }
                    HStack {
                        NomSub(nombre: Fecha.mes("\(p.mes)-01").capitalized, sub: Text("\(p.medio.rawValue) · el \(Fecha.corta(p.fecha))"))
                        Text(Formato.plata(p.monto)).tipo(.numero(18), alto: 18).foregroundStyle(Color.tinta)
                    }
                    .padding(.horizontal, 16).padding(.vertical, 10)
                }
            }
        }
        .sheet(isPresented: $mp) { HojaPagoMP() }
        .onChange(of: comprobante) { _, i in
            guard let i else { return }
            Task { if let d = try? await i.loadTransferable(type: Data.self), let c = achicar(d) { estado.subirComprobanteAlumno(c) } }
        }
    }
}

/// Checkout de Mercado Pago (simulado).
struct HojaPagoMP: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State private var pagando = false
    @State private var listo = false
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CabezaHoja(etiqueta: "Mercado Pago", titulo: listo ? "¡Listo!" : "Pagar cuota")
            Tarjeta(relleno: 20) {
                HStack(spacing: 10) {
                    LogoIntegracion(id: "mp")
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(estado.alumno.plan.nombre) · diciembre").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                        Text("Para \(estado.alumno.profe) · Otra Más").tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                }
                Numero(valor: Formato.plata(estado.alumno.plan.proximoMonto), tamano: 40).padding(.top, 12)
                HStack(spacing: 8) {
                    Image(systemName: "creditcard.fill").foregroundStyle(Color.arena600)
                    Text("Visa terminada en 4821").tipo(.texto(15, 600)).foregroundStyle(Color.tinta)
                }
                .padding(.top, 8)
            }
            Spacer()
            if listo {
                HStack(spacing: 8) { IconoVista(.tilde, tamano: 20); Text("Pago acreditado").tipo(.texto(16, 700)) }
                    .foregroundStyle(Color.ok).frame(maxWidth: .infinity).frame(height: 56)
                    .background(Color.okFondo, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            } else {
                Boton(titulo: pagando ? "Pagando…" : "Pagar \(Formato.plata(estado.alumno.plan.proximoMonto))", variante: .prim, alto: .alto, ancho: true) {
                    pagando = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        estado.pagarCuotaAlumno(); withAnimation { listo = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { dismiss() }
                    }
                }
                .disabled(pagando)
            }
            Text("Simulado: en la maqueta no se cobra nada.").tipo(.texto(12, 400)).foregroundStyle(Color.arena500).frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.bottom, 8)
        .estiloHoja([.medium])
    }
}

// MARK: - Avisos

struct AvisosAlumno: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        PantallaSub(titulo: "Avisos", bajada: "Lo que te mandó \(estado.alumno.profe).") {
            let l = estado.avisosDelAlumno
            if l.isEmpty {
                Tarjeta(relleno: 20) { Text("No hay avisos. Cuando \(estado.alumno.profe) mande uno, aparece acá.").tipo(.texto(15, 400)).foregroundStyle(Color.texto2) }
            }
            VStack(spacing: 12) { ForEach(l) { TarjetaAviso(aviso: $0) } }
        }
    }
}

// MARK: - Perfil

struct PerfilAlumnoVista: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @AppStorage("lado") private var lado = ""
    @State private var p = DatosDeMuestra.perfilAlumno

    var body: some View {
        PantallaSub(titulo: "Tu perfil", bajada: "Lo que respondiste al empezar. Tu profe lo ve.") {
            VStack(alignment: .leading, spacing: 16) {
                Campo(etiqueta: "Nombre", texto: $p.nombre, ejemplo: "Nico")
                Etiqueta("Te identificás como")
                ChipsClaros(opciones: Sexo.allCases.map(\.titulo), elegidas: [p.sexo.titulo]) { t in
                    p.sexo = Sexo.allCases.first { $0.titulo == t } ?? .sinDecir
                }
                Tarjeta {
                    Paso(etiqueta: "Edad", valor: Binding(get: { Double(p.edad) }, set: { p.edad = Int($0) }), rango: 14...90)
                    Divisor()
                    Paso(etiqueta: "Peso (kg)", valor: $p.peso, paso: 0.5, rango: 35...180, formato: Formato.decimal)
                    Divisor()
                    Paso(etiqueta: "Altura (cm)", valor: Binding(get: { Double(p.altura) }, set: { p.altura = Int($0) }), rango: 120...220)
                }
                Etiqueta("Objetivo")
                ChipsClaros(opciones: Objetivo.allCases.map(\.titulo), elegidas: Set([p.objetivo?.titulo].compactMap { $0 })) { t in
                    p.objetivo = Objetivo.allCases.first { $0.titulo == t }
                }
                Etiqueta("Experiencia")
                ChipsClaros(opciones: Experiencia.allCases.map(\.titulo), elegidas: Set([p.experiencia?.titulo].compactMap { $0 })) { t in
                    p.experiencia = Experiencia.allCases.first { $0.titulo == t }
                }
                Tarjeta { Paso(etiqueta: "Días por semana", valor: Binding(get: { Double(p.diasPorSemana) }, set: { p.diasPorSemana = Int($0) }), rango: 1...7) }
                Etiqueta("Lesiones o molestias")
                ChipsClaros(opciones: ["Ninguna"] + lesionesComunes, elegidas: Set(p.lesiones.isEmpty ? ["Ninguna"] : p.lesiones)) { o in
                    if o == "Ninguna" { p.lesiones = [] } else if let i = p.lesiones.firstIndex(of: o) { p.lesiones.remove(at: i) } else { p.lesiones.append(o) }
                }
                Tarjeta(relleno: 16) {
                    Toggle(isOn: $p.saludConectada) {
                        HStack(spacing: 10) {
                            IconoVista(.corazon, tamano: 20).foregroundStyle(Color.salud)
                            NomSub(nombre: "Apple Salud", sub: Text(p.saludConectada ? "Tus pasos aparecen en Logros" : "Apagado"))
                        }
                    }
                    .tint(Color.ok)
                }
                Boton(titulo: "Guardar", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                    estado.guardarPerfil(p); Haptico.exito(); estado.avisar("Listo, tu perfil quedó al día."); dismiss()
                }
                Button { withAnimation { estado.borrarPerfil(); lado = "" } } label: {
                    Text("Cerrar sesión").tipo(.texto(15, 700)).foregroundStyle(Color.error).frame(maxWidth: .infinity).frame(height: 48)
                }
            }
        }
        .onAppear { if let x = estado.perfil, x.lado == .alumno { p = x } }
    }
}
