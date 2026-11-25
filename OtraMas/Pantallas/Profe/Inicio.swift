import SwiftUI

/// 1 · Inicio del profe: cuánto cobró, la próxima clase y lo que hay para resolver.
struct Inicio: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @Environment(\.dynamicTypeSize) private var dts

    var body: some View {
        PantallaProfe {
            Encabezado(fecha: estado.profe.fecha, titulo: "Hola, \(estado.profe.profe.nombre)", foto: estado.profe.profe.foto)
            hero
            Boton(titulo: "Recordar a los \(estado.deben.count) que deben", icono: .wa, variante: .yema, alto: .alto, ancho: true) {
                estado.recordarDeudas()
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 24)
        } cuerpo: {
            if let c = estado.proxima { proxima(c) }
            TituloSeccion("Para resolver")
            Tarjeta {
                filaResolver(numero: estado.porConfirmar.count, nombre: "Comprobantes", sub: "para confirmar") {
                    Boton(titulo: "Confirmar", icono: .tilde, variante: .prim, alto: .chico) { nav.ir(.cuotas) }
                }
                Divisor()
                filaResolver(numero: estado.profe.resumen.noVienen, nombre: "No vienen", sub: "hace más de 7 días") {
                    Boton(titulo: "Escribir", icono: .wa, variante: .suave, alto: .chico) {
                        estado.avisar("Les escribimos a los \(estado.profe.resumen.noVienen) por WhatsApp.")
                    }
                }
                let sin = estado.sinRutina
                if !sin.isEmpty {
                    Divisor()
                    filaResolver(numero: sin.count, nombre: "Sin rutina", sub: sin.prefix(3).map(\.primerNombre).joined(separator: ", ")) {
                        Boton(titulo: "Asignar", icono: .pesa, variante: .suave, alto: .chico) {
                            nav.hoja = .elegirRutina(sin.map(\.id))
                        }
                    }
                }
            }
            if let t = estado.tip(.profe) {
                TipVista(tip: t).padding(.top, 24)
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 24) {
            Anillo(tamano: 136, grosor: 12, total: Double(estado.total),
                   segmentos: [.init(valor: Double(estado.pagaron), color: .yema)],
                   pista: .berenjena700, redondo: true) {
                VStack(spacing: 4) {
                    Text("\(estado.pagaron)").tipo(.numero(64), alto: 64).foregroundStyle(Color.hueso)
                        .contentTransition(.numericText(value: Double(estado.pagaron)))
                    Text("de \(estado.total)\npagaron").tipo(.texto(12, 600)).foregroundStyle(Color.berenjena300)
                        .multilineTextAlignment(.center).lineSpacing(1)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Pagaron \(estado.pagaron) de \(estado.total)")
            VStack(alignment: .leading, spacing: 0) {
                Etiqueta("Cobrado en \(estado.profe.resumen.mes)", color: .berenjena300)
                Text(Formato.plata(estado.profe.resumen.cobrado))
                    .tipo(.numero(40), alto: 40)
                    .foregroundStyle(Color.hueso)
                    .contentTransition(.numericText(value: Double(estado.profe.resumen.cobrado)))
                    .padding(.top, 8)
                (Text("Faltan ").foregroundColor(.berenjena300)
                 + Text(Formato.plata(estado.faltan)).font(Estilo.texto(16, 700).font(dts)).foregroundColor(.yema))
                    .tipo(.texto(16, 400))
                    .padding(.top, 8)
                HStack(spacing: 8) {
                    Boton(titulo: "Tu mes", iconoDerecha: .der, variante: .osc, alto: .chico,
                          relleno: EdgeInsets(top: 0, leading: 14, bottom: 0, trailing: 10)) {
                        nav.inicio.append(.tuMes)
                    }
                    Boton(titulo: "Semana", icono: .cal, variante: .osc, alto: .chico,
                          relleno: EdgeInsets(top: 0, leading: 10, bottom: 0, trailing: 12)) {
                        nav.inicio.append(.horario)
                    }
                    .accessibilityLabel("Tu semana de clases")
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 24)
    }

    private func proxima(_ c: Clase) -> some View {
        Button { nav.inicio.append(.horario) } label: {
            Tarjeta(relleno: 16) {
                HStack(spacing: 16) {
                    Text(c.hora).tipo(.numero(40), alto: 40).foregroundStyle(Color.berenjena800)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Circle().fill(Color.yema).frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.yema700, lineWidth: 1))
                            Etiqueta("Próxima · \(estado.profe.proximaEn)", color: .tinta)
                        }
                        NomSub(nombre: c.nombre,
                               sub: negrita("\(c.vienen) de \(c.cupo)", dts: dts) + Text(" vienen · \(c.lugar)"))
                            .padding(.top, 4)
                    }
                    IconoVista(.der, tamano: 20).foregroundStyle(Color.arena300)
                }
            }
        }
        .buttonStyle(Apretable())
        .accessibilityLabel("Próxima clase, \(c.hora), \(c.nombre), vienen \(c.vienen) de \(c.cupo), \(c.lugar)")
    }

    private func filaResolver<B: View>(numero: Int, nombre: String, sub: String, @ViewBuilder boton: () -> B) -> some View {
        HStack(spacing: 12) {
            Text("\(numero)").tipo(.numero(28), alto: 28).foregroundStyle(Color.berenjena800).frame(width: 28)
                .contentTransition(.numericText(value: Double(numero)))
            NomSub(nombre: nombre, sub: Text(sub))
            boton()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(minHeight: 64)
    }
}

/// Encabezado del Inicio: fecha, «Hola, Lucía» y la foto (dejándola apretada se cambia de lado).
struct Encabezado: View {
    let fecha: String
    let titulo: String
    let foto: String

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(fecha).tipo(.texto(14, 600)).foregroundStyle(Color.berenjena300)
                Titulo(titulo, tamano: 40, color: .hueso)
            }
            Spacer(minLength: 0)
            FotoRedonda(nombre: foto, tamano: 44)
                .cambiaDeLado()
                .accessibilityLabel("Tu foto. Tocala para ajustes; dejala apretada para cambiar de lado.")
                .accessibilityHidden(false)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
    }
}

/// Título grande de pestaña con algo a la derecha («Cuotas» + Noviembre).
struct CabeceraPestana<Derecha: View>: View {
    let titulo: String
    @ViewBuilder var derecha: () -> Derecha

    var body: some View {
        HStack(alignment: .bottom, spacing: 12) {
            Titulo(titulo, tamano: 40, color: .hueso)
            Spacer(minLength: 0)
            derecha()
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
    }
}

/// El «Noviembre» lila de la derecha de una cabecera (.lado).
struct LadoCabecera: View {
    let texto: String
    var body: some View {
        Text(texto).tipo(.texto(16, 600)).foregroundStyle(Color.berenjena300).padding(.bottom, 6)
    }
}
