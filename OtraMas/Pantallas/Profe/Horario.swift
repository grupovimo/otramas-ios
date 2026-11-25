import SwiftUI

/// 5 · Horario: la semana arriba (con flechas para ir y venir) y las clases del día elegido, que salen del horario
/// semanal fijo. Pasado: lo que pasó (asistencia). Hoy: lo que está pasando. Futuro: quiénes vienen, suspender o anotar.
struct Horario: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @Environment(\.dismiss) private var dismiss
    var apilada = false
    @State private var dia: String?
    @State private var semana: String?
    @State private var nuevaClase: String?

    private var elegido: String { dia ?? estado.hoy }
    private var lunes: String { semana ?? Fecha.lunes(estado.hoy) }

    var body: some View {
        PantallaProfe {
            if apilada {
                NavBanda(atras: "Inicio", accionAtras: { dismiss() }) { EmptyView() }
            }
            CabeceraPestana(titulo: "Horario") {
                HStack(spacing: 4) {
                    flecha(.atras, "Semana anterior") { mover(-7) }
                    Text(Fecha.mes(Fecha.sumar(3, a: lunes)).capitalized).tipo(.texto(16, 600)).foregroundStyle(Color.berenjena300)
                        .frame(minWidth: 92)
                    flecha(.der, "Semana siguiente") { mover(7) }
                }
                .padding(.bottom, 2)
            }
            semanaVista
        } cuerpo: {
            cabeceraDia
            let clases = estado.clases(en: elegido)
            if let f = estado.feriado(elegido) {
                vacio(icono: .bandera, titulo: "Feriado", texto: "\(f). No hay clases y tus alumnos ya lo saben.", accion: "Sumar una clase igual")
            } else if clases.isEmpty {
                vacio(icono: .sol, titulo: "Este día no das clases", texto: "Si querés, sumá una clase única o una fija para todas las semanas.", accion: "Sumar una clase")
            } else {
                VStack(spacing: 12) {
                    ForEach(clases) { c in fila(c) }
                }
                Button { nuevaClase = elegido } label: {
                    HStack(spacing: 8) { IconoVista(.mas, tamano: 20); Text("Sumar una clase").tipo(.texto(16, 700)) }
                        .foregroundStyle(Color.berenjena800)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                            .strokeBorder(Color.arena300, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                }
                .buttonStyle(Apretable())
                .padding(.top, 12)
            }
        }
        .sheet(item: Binding(get: { nuevaClase.map { FechaElegida(iso: $0) } }, set: { nuevaClase = $0?.iso })) { f in
            HojaNuevaClase(fecha: f.iso)
        }
    }

    private struct FechaElegida: Identifiable { let iso: String; var id: String { iso } }

    private func mover(_ d: Int) {
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.25)) {
            semana = Fecha.sumar(d, a: lunes)
            dia = Fecha.sumar(Fecha.diaSemana(elegido) - 1, a: semana!)
        }
    }

    private func flecha(_ i: Icono, _ e: String, _ a: @escaping () -> Void) -> some View {
        Button(action: a) {
            IconoVista(i, tamano: 20).foregroundStyle(Color.hueso).frame(width: 44, height: 44).contentShape(Rectangle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(e)
    }

    private var semanaVista: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { k in
                let iso = Fecha.sumar(k, a: lunes)
                let on = iso == elegido
                let feriado = estado.feriado(iso) != nil
                let conClases = !estado.clases(en: iso).isEmpty
                Button {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.25)) { dia = iso }
                } label: {
                    VStack(spacing: 4) {
                        Text(Fecha.cortos[k].uppercased()).tipo(.etiqueta).foregroundStyle(on ? Color.berenjena800 : Color.berenjena300)
                        Text("\(Fecha.numero(iso))")
                            .tipo(.numero(20), alto: 20)
                            .strikethrough(feriado, pattern: .solid, color: on ? .berenjena800 : .berenjena500)
                            .foregroundStyle(on ? Color.berenjena800 : (feriado ? Color.berenjena500 : Color.hueso))
                        Circle()
                            .fill(conClases ? (on ? Color.berenjena800 : Color.berenjena300) : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(on ? Color.yema : Color.clear, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    .overlay {
                        if iso == estado.hoy && !on {
                            RoundedRectangle(cornerRadius: Radio.control, style: .continuous).strokeBorder(Color.hueso.opacity(0.25), lineWidth: 1)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("\(Fecha.largo(iso))\(feriado ? ", feriado" : "")\(conClases ? "" : ", sin clases")")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }

    @ViewBuilder
    private var cabeceraDia: some View {
        if elegido != estado.hoy {
            let n = Fecha.dias(entre: estado.hoy, y: elegido)
            HStack {
                Titulo(Fecha.largo(elegido), tamano: 20)
                Spacer()
                Text(n < 0 ? (n == -1 ? "Ayer" : "Hace \(-n) días") : (n == 1 ? "Mañana" : "En \(n) días"))
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            .padding(.bottom, 12)
        }
    }

    private func fila(_ c: Clase) -> some View {
        let hecha = c.estado == .termino
        let suspendida: String? = { if case .suspendida(let m) = c.estado { return m }; return nil }()
        let futura = (c.fecha ?? estado.hoy) > estado.hoy
        return Button {
            switch c.estado {
            case .falta: nav.hoja = futura ? .clase(c.id) : .suspender(c.id)
            case .termino: if c.particular == nil { nav.hoja = .lista(c.id) }
            case .suspendida: nav.hoja = .clase(c.id)
            }
        } label: {
            Tarjeta(relleno: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.hora).tipo(.numero(28), alto: 28)
                            .foregroundStyle(hecha || suspendida != nil ? Color.arena500 : Color.berenjena800)
                            .strikethrough(suspendida != nil, color: .arena500)
                        Text(textoEstado(c)).tipo(.texto(12, 400)).foregroundStyle(Color.texto2).lineLimit(1)
                    }
                    .frame(width: 64, alignment: .leading)
                    NomSub(nombre: c.nombre, sub: Text(sub(c, suspendida)))
                    if let p = c.particular, let a = estado.alumno(p) {
                        Iniciales(texto: a.iniciales, tono: .yema, tamano: 48)
                    } else if suspendida != nil {
                        IconoVista(.lluvia, tamano: 24).foregroundStyle(Color.arena500).frame(width: 48, height: 48)
                    } else {
                        Anillo(tamano: 48, grosor: 5, total: Double(max(c.cupo, 1)),
                               segmentos: [.init(valor: Double(c.vienen), color: hecha ? .arena300 : .berenjena800)],
                               pista: hecha ? .arena50 : .berenjena100, redondo: true) {
                            Text("\(c.vienen)/\(c.cupo)").tipo(.numero(14), alto: 14)
                                .foregroundStyle(hecha ? Color.arena600 : Color.berenjena800)
                        }
                    }
                }
            }
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("\(c.hora), \(c.nombre), \(c.lugar), \(textoEstado(c))")
    }

    private func sub(_ c: Clase, _ suspendida: String?) -> String {
        if let s = suspendida { return "Suspendida · \(s)" }
        if !c.recuperan.isEmpty { return "\(c.lugar) · \(c.recuperan.count) recupera\(c.recuperan.count == 1 ? "" : "n")" }
        return c.lugar
    }

    private func textoEstado(_ c: Clase) -> String {
        switch c.estado {
        case .termino: return c.fecha == estado.hoy ? "Terminó" : "Vinieron \(c.vienen)"
        case .falta(let t): return t
        case .suspendida: return "Suspendida"
        }
    }

    private func vacio(icono: Icono, titulo: String, texto: String, accion: String) -> some View {
        Tarjeta(relleno: 24) {
            VStack(spacing: 12) {
                IconoVista(icono, tamano: 28).foregroundStyle(Color.berenjena800)
                    .frame(width: 64, height: 64).background(Color.yema, in: Circle())
                Text(titulo).tipo(.texto(20, 700)).foregroundStyle(Color.tinta)
                Text(texto).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                Boton(titulo: accion, icono: .mas, variante: .prim, ancho: true) { nuevaClase = elegido }
                    .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// Una clase de un día que viene: quiénes vienen, anotar a alguien a recuperar o suspender esa fecha.
struct HojaClase: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @Environment(\.dismiss) private var dismiss
    let claseId: String
    @State private var anotando = false

    var body: some View {
        if let c = estado.clase(claseId) {
            let suspendida: String? = { if case .suspendida(let m) = c.estado { return m }; return nil }()
            VStack(alignment: .leading, spacing: 0) {
                CabezaHoja(etiqueta: "\(Fecha.largo(c.fecha ?? estado.hoy)) · \(c.lugar)", titulo: "\(c.nombre) · \(c.hora)")
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        if let suspendida {
                            Tarjeta(relleno: 16) {
                                Text("Suspendida · \(suspendida)").tipo(.texto(16, 700)).foregroundStyle(Color.error)
                                Text("Ya les avisamos a todos.").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                            }
                            .padding(.top, 24)
                        }
                        TituloSeccion(texto: anotando ? "Anotar a recuperar" : "Vienen") {
                            Text(anotando ? "Tocá a quién" : "\(c.vienen) de \(c.cupo)").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                        Tarjeta {
                            let lista = anotando ? estado.alumnos.filter { !c.inscriptos.contains($0.id) } : c.inscriptos.compactMap { estado.alumno($0) }
                            ForEach(Array(lista.enumerated()), id: \.element.id) { i, a in
                                if i > 0 { Divisor() }
                                Button {
                                    if anotando { estado.anotar(a.id, en: c.id); withAnimation { anotando = false } }
                                } label: {
                                    HStack(spacing: 12) {
                                        Iniciales(texto: a.iniciales, tono: a.tono, tamano: 40)
                                        NomSub(nombre: a.nombre, sub: Text(anotando ? a.horario : c.recuperan.contains(a.id) ? "Recupera" : c.presentes.contains(a.id) ? "Viene" : "Avisó que falta"))
                                        if anotando { IconoVista(.mas, tamano: 20).foregroundStyle(Color.berenjena800) }
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 12).frame(minHeight: 64)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .disabled(!anotando)
                            }
                        }
                    }
                    .padding(.bottom, 16)
                }
                .scrollIndicators(.hidden)
                if suspendida == nil {
                    HStack(spacing: 12) {
                        Boton(titulo: anotando ? "Cancelar" : "Anotar a alguien", icono: anotando ? nil : .mas, variante: .suave, alto: .alto, ancho: true) {
                            Haptico.seleccion(); withAnimation(.snappy) { anotando.toggle() }
                        }
                        if !anotando {
                            Boton(titulo: "Suspender", icono: .lluvia, variante: .prim, alto: .alto, ancho: true) {
                                dismiss()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { nav.hoja = .suspender(c.id) }
                            }
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, Espacio.margen)
            .estiloHoja([.large])
        }
    }
}

/// Sumar una clase: fija (todas las semanas) o única (sólo esa fecha).
struct HojaNuevaClase: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let fecha: String
    @State private var nombre = "Funcional"
    @State private var hora = "18:00"
    @State private var lugar = "Plaza Mitre"
    @State private var cupo: Double = 12
    @State private var fija = true
    @State private var dias: Set<Int> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: Fecha.largo(fecha), titulo: "Sumar una clase")
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    campo("Nombre", $nombre, "Funcional")
                    HStack(spacing: 12) {
                        campo("Hora", $hora, "18:00")
                        campo("Lugar", $lugar, "Plaza Mitre")
                    }
                    Tarjeta { Paso(etiqueta: "Cupo", valor: $cupo, rango: 1...40) }.padding(.top, 16)
                    Etiqueta("Se repite").padding(.top, 24).padding(.bottom, 8)
                    HStack(spacing: 8) {
                        Chip(titulo: "Todas las semanas", elegido: fija, elegidoOscuro: true, ancho: true) { fija = true }
                        Chip(titulo: "Sólo ese día", elegido: !fija, elegidoOscuro: true, ancho: true) { fija = false }
                    }
                    if fija {
                        HStack(spacing: 6) {
                            ForEach(1...7, id: \.self) { d in
                                let on = dias.contains(d)
                                Button { Haptico.seleccion(); if on { dias.remove(d) } else { dias.insert(d) } } label: {
                                    Text(Fecha.cortos[d - 1].uppercased()).tipo(.etiqueta)
                                        .foregroundStyle(on ? Color.yema : Color.berenjena800)
                                        .frame(maxWidth: .infinity).frame(height: 48)
                                        .background(on ? Color.berenjena800 : Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                                }
                                .buttonStyle(Apretable())
                                .accessibilityAddTraits(on ? .isSelected : [])
                            }
                        }
                        .padding(.top, 12)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            Boton(titulo: "Sumar clase", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                estado.crearClase(nombre: nombre, hora: hora, lugar: lugar, cupo: Int(cupo), dias: fija ? dias.sorted() : [],
                                  unica: fija ? nil : fecha)
                dismiss()
            }
            .disabled(nombre.trimmingCharacters(in: .whitespaces).isEmpty || (fija && dias.isEmpty))
            .opacity(nombre.trimmingCharacters(in: .whitespaces).isEmpty || (fija && dias.isEmpty) ? 0.45 : 1)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja([.large])
        .onAppear { dias = [Fecha.diaSemana(fecha)] }
    }

    private func campo(_ e: String, _ t: Binding<String>, _ ph: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Etiqueta(e)
            TextField("", text: t, prompt: Text(ph).foregroundColor(.arena500))
                .font(Estilo.texto(17, 600).font()).foregroundStyle(Color.tinta)
                .padding(.horizontal, 16).frame(height: 52)
                .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous).strokeBorder(Color.arena300, lineWidth: 1))
        }
        .padding(.top, 12)
    }
}

/// Hoja «Suspender la clase de hoy»: motivo, si les queda para recuperar, y avisar a todos.
struct HojaSuspender: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let claseId: String
    @State private var motivo = "Lluvia"
    @State private var recuperar = true

    var body: some View {
        let c = estado.clase(claseId)
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color.arena300).frame(width: 36, height: 5).frame(maxWidth: .infinity).padding(.bottom, 16)
            if let c {
                Etiqueta("\(c.nombre) · \(c.hora) · \(c.lugar)")
                Titulo(c.fecha == nil || c.fecha == estado.hoy ? "Suspender la clase de hoy" : "Suspender el \(Fecha.largo(c.fecha!).lowercased().split(separator: " ").prefix(2).joined(separator: " "))", tamano: 28).padding(.top, 8)
                HStack(spacing: 8) {
                    ForEach(["Lluvia", "Feriado", "Otro"], id: \.self) { m in
                        Boton(titulo: m, icono: m == "Lluvia" && motivo == m ? .lluvia : nil,
                              variante: motivo == m ? .prim : .suave, ancho: true,
                              relleno: EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8)) {
                            Haptico.seleccion(); withAnimation(.snappy(duration: 0.2)) { motivo = m }
                        }
                        .accessibilityAddTraits(motivo == m ? .isSelected : [])
                    }
                }
                .padding(.top, 24)
                Tarjeta(relleno: 16) {
                    Toggle(isOn: $recuperar) {
                        NomSub(nombre: "Les queda para recuperar", sub: Text("Eligen el día desde su link"))
                    }
                    .tint(Color.ok)
                }
                .padding(.top, 12)
                Boton(titulo: "Suspender y avisar a los \(c.vienen)", icono: .wa, variante: .prim, alto: .alto, ancho: true) {
                    estado.suspender(claseId: c.id, motivo: motivo, dejarRecuperar: recuperar)
                    dismiss()
                }
                .padding(.top, 24)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .presentationDetents([.height(362)])
        .presentationCornerRadius(Radio.tarjeta)
        .presentationBackground(Color.hueso)
        .presentationDragIndicator(.hidden)
    }
}
