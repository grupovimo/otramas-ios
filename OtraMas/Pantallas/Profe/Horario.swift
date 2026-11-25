import SwiftUI

/// 5 · Horario del día: la semana arriba y las clases del día elegido. Tocar una clase que todavía no
/// empezó abre «Suspender»; una que terminó, la lista.
struct Horario: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @State private var dia = 24

    var body: some View {
        PantallaProfe {
            CabeceraPestana(titulo: "Horario") { LadoCabecera(texto: "Noviembre") }
            semana
        } cuerpo: {
            let d = estado.profe.semana.first { $0.numero == dia }
            if dia == estado.profe.hoy {
                VStack(spacing: 12) {
                    ForEach(estado.profe.clases) { c in fila(c) }
                }
            } else if let d, !d.conClases {
                vacio(d)
            } else {
                VStack(spacing: 12) {
                    ForEach(clasesDe(dia)) { c in fila(c) }
                }
            }
        }
    }

    private var semana: some View {
        HStack(spacing: 4) {
            ForEach(estado.profe.semana) { d in
                let on = d.numero == dia
                Button {
                    Haptico.seleccion()
                    withAnimation(.snappy(duration: 0.25)) { dia = d.numero }
                } label: {
                    VStack(spacing: 4) {
                        Text(d.corto.uppercased()).tipo(.etiqueta).foregroundStyle(on ? Color.berenjena800 : Color.berenjena300)
                        Text("\(d.numero)")
                            .tipo(.numero(20), alto: 20)
                            .strikethrough(d.feriado, pattern: .solid, color: on ? .berenjena800 : .berenjena500)
                            .foregroundStyle(on ? Color.berenjena800 : (d.feriado ? Color.berenjena500 : Color.hueso))
                        Circle()
                            .fill(d.conClases ? (on ? Color.berenjena800 : Color.berenjena300) : Color.clear)
                            .frame(width: 4, height: 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 72)
                    .background(on ? Color.yema : Color.clear, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
                .accessibilityLabel("\(d.corto) \(d.numero)\(d.feriado ? ", feriado" : "")\(d.conClases ? "" : ", sin clases")")
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }

    private func fila(_ c: Clase) -> some View {
        let hecha = c.estado == .termino
        let suspendida: String? = { if case .suspendida(let m) = c.estado { return m }; return nil }()
        return Button {
            switch c.estado {
            case .falta: nav.hoja = .suspender(c.id)
            case .termino: if c.particular == nil { nav.hoja = .lista(c.id) }
            case .suspendida: break
            }
        } label: {
            Tarjeta(relleno: 16) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(c.hora).tipo(.numero(28), alto: 28)
                            .foregroundStyle(hecha || suspendida != nil ? Color.arena500 : Color.berenjena800)
                            .strikethrough(suspendida != nil, color: .arena500)
                        Text(textoEstado(c.estado)).tipo(.texto(12, 400)).foregroundStyle(Color.texto2).lineLimit(1)
                    }
                    .frame(width: 64, alignment: .leading)
                    NomSub(nombre: c.nombre, sub: Text(suspendida.map { "Suspendida · \($0)" } ?? c.lugar))
                    if let p = c.particular, let a = estado.alumno(p) {
                        Iniciales(texto: a.iniciales, tono: .yema, tamano: 48)
                    } else if suspendida != nil {
                        IconoVista(.lluvia, tamano: 24).foregroundStyle(Color.arena500).frame(width: 48, height: 48)
                    } else {
                        Anillo(tamano: 48, grosor: 5, total: Double(c.cupo),
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
        .accessibilityLabel("\(c.hora), \(c.nombre), \(c.lugar), \(textoEstado(c.estado))")
    }

    private func textoEstado(_ e: EstadoClase) -> String {
        switch e {
        case .termino: return "Terminó"
        case .falta(let t): return t
        case .suspendida: return "Suspendida"
        }
    }

    /// Las clases fijas de los otros días de la semana (lun, mié y vie a la mañana; todos a la tarde).
    private func clasesDe(_ n: Int) -> [Clase] {
        let base = estado.profe.clases
        var out: [Clase] = []
        let corto = estado.profe.semana.first { $0.numero == n }?.corto ?? ""
        if ["Lun", "Mié", "Vie"].contains(corto), var m = base.first(where: { $0.id == "c1" }) {
            m.id = "c1-\(n)"; m.estado = .falta("Inscriptos"); m.presentes = Set(m.inscriptos)
            out.append(m)
        }
        if corto == "Jue", var p = base.first(where: { $0.id == "c2" }) {
            p.id = "c2-\(n)"; p.estado = .falta("Particular"); out.append(p)
        }
        if corto != "Sáb", var t = base.first(where: { $0.id == "c3" }) {
            t.id = "c3-\(n)"; t.estado = .falta("Inscriptos"); t.presentes = Set(t.inscriptos.prefix(10))
            out.append(t)
        }
        if corto == "Sáb" {
            out.append(Clase(id: "s-\(n)", hora: "9:30", nombre: "Funcional sábado", lugar: "Costanera", estado: .falta("Inscriptos"),
                             cupo: 15, inscriptos: [], presentes: Set(base.first?.inscriptos ?? [])))
        }
        return out
    }

    private func vacio(_ d: DiaSemana) -> some View {
        Tarjeta(relleno: 24) {
            VStack(spacing: 8) {
                IconoVista(d.feriado ? .bandera : .sol, tamano: 24).foregroundStyle(Color.yema700)
                Text(d.feriado ? "Feriado" : "Día libre").tipo(.texto(20, 700)).foregroundStyle(Color.tinta)
                Text(d.feriado ? "No hay clases. Tus alumnos ya lo saben." : "Los domingos no das clases.")
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
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
        let c = estado.profe.clases.first { $0.id == claseId }
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color.arena300).frame(width: 36, height: 5).frame(maxWidth: .infinity).padding(.bottom, 16)
            if let c {
                Etiqueta("\(c.nombre) · \(c.hora) · \(c.lugar)")
                Titulo("Suspender la clase de hoy", tamano: 28).padding(.top, 8)
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
