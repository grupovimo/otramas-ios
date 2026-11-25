import SwiftUI

/// 7 · Logros: la racha, los pasos de Apple Salud (de muestra), el récord y las medallas.
struct LogrosAlumno: View {
    @Environment(Estado.self) private var estado

    var body: some View {
        let a = estado.alumno, l = a.logros
        PantallaAlumno {
            CabeceraAlumno(profe: a.profe, alumno: a.nombre, foto: a.fotoProfe)
            HStack(spacing: 12) {
                IconoVista(.fuego, tamano: 40, grosor: 2).foregroundStyle(Color.racha)
                HStack(spacing: 12) {
                    Text("\(l.rachaSemanas)").tipo(.numero(64), alto: 64).foregroundStyle(Color.racha)
                    VStack(alignment: .leading, spacing: 0) {
                        Titulo("Semanas", tamano: 20, color: .hueso)
                        Titulo("seguidas", tamano: 20, color: .hueso)
                    }
                }
                Spacer(minLength: 8)
                VStack(spacing: 4) {
                    Anillo(tamano: 64, grosor: 8, total: Double(l.semanaMeta),
                           segmentos: Array(repeating: .init(valor: 1, color: .yema), count: l.semanaHechas),
                           pista: .berenjena700, separacion: 12, redondo: true) {
                        HStack(alignment: .firstTextBaseline, spacing: 0) {
                            Text("\(l.semanaHechas)").tipo(.numero(20)).foregroundStyle(Color.hueso)
                            Text("/\(l.semanaMeta)").tipo(.numero(14)).foregroundStyle(Color.berenjena300)
                        }
                    }
                    Text("esta semana").tipo(.texto(12, 600)).foregroundStyle(Color.berenjena300)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Esta semana: \(l.semanaHechas) de \(l.semanaMeta) clases")
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 24)
            .accessibilityElement(children: .contain)
        } cuerpo: {
            Tarjeta(relleno: 16) {
                HStack {
                    Etiqueta("Pasos de hoy")
                    Spacer()
                    DeAppleSalud()
                }
                Numero(valor: Formato.miles(l.pasosHoy), tamano: 28, unidad: "de \(Formato.miles(l.pasosMeta))")
                    .padding(.top, 8)
                BarraProgreso(fraccion: Double(l.pasosHoy) / Double(max(l.pasosMeta, 1)))
                    .padding(.top, 12)
                    .accessibilityHidden(true)
            }
            Tarjeta(relleno: 16) {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 4) {
                            IconoVista(.trofeo, tamano: 16)
                            Text("NUEVO RÉCORD · \(l.record.cuando.uppercased())").tipo(.etiqueta).lineLimit(1)
                        }
                        .foregroundStyle(Color.yema700)
                        Numero(valor: Formato.decimal(l.record.kilos), tamano: 40, unidad: "kg").padding(.top, 8)
                        Text(l.record.ejercicio).tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4)
                    }
                    Spacer(minLength: 0)
                    GraficoRecord(valores: l.record.valores, meses: l.record.meses)
                }
            }
            .padding(.top, 12)
            TituloSeccion(texto: "Medallas") {
                (Text("\(l.medallas.filter(\.ganada).count)").foregroundColor(.tinta).bold() + Text(" de \(l.medallas.count)"))
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 16) {
                ForEach(l.medallas) { m in
                    MedallaVista(medalla: m)
                }
            }
        }
    }
}

extension Medalla {
    var icono: Icono { Icono(rawValue: iconoNombre) ?? .estrella }
}

/// 8 · Mi plan: el pack, la próxima clase, recuperar y pagar.
struct MiPlan: View {
    @Environment(Estado.self) private var estado
    @State private var elegirDia = false

    var body: some View {
        let a = estado.alumno, p = a.plan
        let quedan = p.clasesTotal - p.clasesUsadas
        PantallaAlumno {
            CabeceraAlumno(profe: a.profe, alumno: a.nombre, foto: a.fotoProfe)
            HStack(spacing: 24) {
                Anillo(tamano: 112, grosor: 10, total: Double(p.clasesTotal),
                       segmentos: [.init(valor: Double(p.clasesUsadas), color: Color.hueso.opacity(0.28)),
                                   .init(valor: Double(quedan), color: .yema)],
                       pista: .berenjena700, separacion: 6, partir: true) {
                    VStack(spacing: 4) {
                        Text("\(quedan)").tipo(.numero(64), alto: 64).foregroundStyle(Color.yema)
                        Etiqueta(quedan == 1 ? "te queda" : "te quedan", color: .hueso)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Te \(quedan == 1 ? "queda" : "quedan") \(quedan) de \(p.clasesTotal) clases")
                VStack(alignment: .leading, spacing: 8) {
                    Titulo(p.nombre, tamano: 28, color: .hueso)
                    Text("\(p.mes)\n\(p.vence)").tipo(.texto(14, 400)).foregroundStyle(Color.berenjena300).lineSpacing(3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 24)
        } cuerpo: {
            Tarjeta {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Etiqueta(p.proxima.diaCorto, color: .yema700)
                            Text("\(p.proxima.dia)").tipo(.numero(40), alto: 40).foregroundStyle(Color.berenjena800)
                        }
                        .frame(width: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Etiqueta("Próxima clase")
                            Text(p.proxima.hora).tipo(.numero(28), alto: 28).foregroundStyle(Color.tinta)
                            HStack(spacing: 4) {
                                IconoVista(.pin, tamano: 16)
                                Text(p.proxima.lugar).tipo(.texto(14, 400))
                            }
                            .foregroundStyle(Color.texto2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .accessibilityElement(children: .combine)
                    if p.avisoFalta {
                        HStack(spacing: 8) {
                            IconoVista(.tilde, tamano: 20).foregroundStyle(Color.ok)
                            Text("Avisaste que faltás").tipo(.texto(16, 700)).foregroundStyle(Color.ok)
                        }
                        .frame(maxWidth: .infinity).frame(height: 48)
                        .background(Color.okFondo, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    } else {
                        Boton(titulo: "Aviso que falto", variante: .suave, ancho: true) { estado.avisarFalta() }
                    }
                }
                .padding(16)
                Divisor()
                HStack(spacing: 12) {
                    IconoVista(.cambio, tamano: 24).foregroundStyle(Color.yema700).frame(width: 56)
                    NomSub(nombre: p.paraRecuperar == 0 ? "Nada para recuperar" : "\(p.paraRecuperar) para recuperar",
                           sub: Text("Hasta el \(p.recuperarHasta)"))
                    if p.paraRecuperar > 0 {
                        Boton(titulo: "Elegir día", variante: .prim, alto: .chico) { elegirDia = true }
                    }
                }
                .padding(16)
            }
            Boton(titulo: "Pagar \(p.proximoMes) · \(Formato.plata(p.proximoMonto))", variante: .yema, alto: .alto, ancho: true) {
                UIPasteboard.general.string = p.alias
                estado.avisar("Copiamos el alias. Pagá desde tu banco y mandá el comprobante.")
            }
            .padding(.top, 16)
            HStack {
                (Text("Alias") + Text("  ") + Text(p.alias).font(Estilo.texto(16, 700).font()).foregroundColor(.tinta))
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).lineLimit(1).minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                Boton(titulo: "Copiar", icono: .copiar, variante: .suave, alto: .chico) {
                    UIPasteboard.general.string = p.alias
                    Haptico.exito()
                    estado.avisar("Alias copiado.")
                }
            }
            .padding(.leading, 4)
            .frame(height: 44)
            .padding(.top, 8)
        }
        .confirmationDialog("¿Qué día recuperás?", isPresented: $elegirDia, titleVisibility: .visible) {
            ForEach(["lunes 30 a las 8:00", "martes 1/12 a las 18:00", "jueves 3/12 a las 10:30"], id: \.self) { d in
                Button(d.prefix(1).uppercased() + d.dropFirst()) { estado.elegirRecuperar(d) }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }
}
