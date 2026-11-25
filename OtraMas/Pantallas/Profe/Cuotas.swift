import SwiftUI

/// 2 · Cuotas: la dona del mes, los comprobantes por confirmar y los que deben.
struct Cuotas: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dynamicTypeSize) private var dts
    @State private var mes = "Noviembre"

    var body: some View {
        PantallaProfe {
            CabeceraPestana(titulo: "Cuotas") {
                Menu {
                    ForEach(["Noviembre", "Octubre", "Septiembre"], id: \.self) { m in
                        Button(m) { mes = m; if m != "Noviembre" { estado.avisar("En la maqueta sólo está noviembre.") } }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Text("Noviembre").tipo(.texto(16, 700))
                        IconoVista(.abajo, tamano: 16)
                    }
                    .foregroundStyle(Color.hueso)
                    .padding(.horizontal, 14)
                    .frame(height: 44)
                    .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                }
                .accessibilityLabel("Mes: \(mes)")
            }
            hero
        } cuerpo: {
            if estado.porConfirmar.isEmpty && estado.deben.isEmpty {
                vacio
            }
            if !estado.porConfirmar.isEmpty {
                TituloSeccion(texto: "Por confirmar", arriba: 0) {
                    Text("\(estado.porConfirmar.count) · \(Formato.plata(estado.montoPorConfirmar))")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                }
                Tarjeta {
                    ForEach(Array(estado.porConfirmar.enumerated()), id: \.element.alumno.id) { i, p in
                        if i > 0 { Divisor() }
                        filaComprobante(p.alumno, p.comprobante)
                            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .trailing).combined(with: .opacity)))
                    }
                }
            }
            if !estado.deben.isEmpty {
                TituloSeccion(texto: "Deben", arriba: estado.porConfirmar.isEmpty ? 0 : 24) {
                    Text("\(estado.deben.count) · \(Formato.plata(estado.montoDeben))")
                        .tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                }
                Tarjeta {
                    ForEach(Array(estado.deben.enumerated()), id: \.element.alumno.id) { i, d in
                        if i > 0 { Divisor() }
                        filaDeuda(d.alumno, d.deuda)
                    }
                }
            }
        }
    }

    private var hero: some View {
        HStack(spacing: 24) {
            Anillo(tamano: 128, grosor: 14, total: Double(estado.total),
                   segmentos: [.init(valor: Double(estado.pagaron), color: .yema),
                               .init(valor: Double(estado.porConfirmar.count), color: .hueso),
                               .init(valor: Double(estado.deben.count), color: .errorClaro)],
                   pista: .berenjena700, separacion: 4) {
                VStack(spacing: 4) {
                    Text("\(estado.porcentajeAlDia)%").tipo(.numero(40), alto: 40).foregroundStyle(Color.hueso)
                        .contentTransition(.numericText(value: Double(estado.porcentajeAlDia)))
                    Text("al día").tipo(.texto(12, 600)).foregroundStyle(Color.berenjena300)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(estado.porcentajeAlDia) por ciento al día")
            VStack(alignment: .leading, spacing: 8) {
                leyenda(.yema, "Pagaron", estado.pagaron)
                leyenda(.hueso, "Por confirmar", estado.porConfirmar.count)
                leyenda(.errorClaro, "Deben", estado.deben.count)
                Boton(titulo: "Recordar a los \(estado.deben.count)", icono: .wa, variante: .yema, alto: .chico, ancho: true) {
                    estado.recordarDeudas()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 16)
    }

    private func leyenda(_ color: Color, _ texto: String, _ n: Int) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 3).fill(color).frame(width: 12, height: 12)
            Text(texto).tipo(.texto(16, 400)).foregroundStyle(Color.berenjena300)
            Spacer(minLength: 4)
            Text("\(n)").tipo(.numero(20), alto: 20).monospacedDigit().foregroundStyle(Color.hueso)
                .contentTransition(.numericText(value: Double(n)))
        }
        .frame(minHeight: 20)
        .accessibilityElement(children: .combine)
    }

    private func filaComprobante(_ a: Alumno, _ c: Comprobante) -> some View {
        HStack(spacing: 12) {
            Ticket()
            NomSub(nombre: a.nombre, sub: negrita(Formato.plata(c.monto), dts: dts) + Text(" · \(c.cuando)"))
            Boton(titulo: "Confirmar", icono: .tilde, variante: .prim, alto: .chico) {
                estado.confirmar(alumnoId: a.id)
            }
            .accessibilityLabel("Confirmar el pago de \(a.nombre)")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
    }

    private func filaDeuda(_ a: Alumno, _ d: Deuda) -> some View {
        HStack(spacing: 12) {
            Iniciales(texto: a.iniciales, tono: a.tono, tamano: 36)
            VStack(alignment: .leading, spacing: 0) {
                Text(a.nombre).tipo(.texto(16, 700)).foregroundStyle(Color.tinta).lineLimit(1)
                Text("Hace \(d.dias) días")
                    .tipo(.texto(14, d.dias > 10 ? 600 : 400))
                    .foregroundStyle(d.dias > 10 ? Color.error : Color.texto2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(Formato.plata(d.monto)).tipo(.numero(20), alto: 20).foregroundStyle(Color.tinta)
            Button { estado.recordarDeudas([a.id]) } label: {
                IconoVista(.wa, tamano: 20)
                    .foregroundStyle(Color.ok)
                    .frame(width: 44, height: 44)
                    .background(Color.okFondo, in: Circle())
            }
            .buttonStyle(Apretable())
            .accessibilityLabel("Recordarle a \(a.nombre) por WhatsApp")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: 56)
    }

    private var vacio: some View {
        Tarjeta(relleno: 24) {
            VStack(spacing: 12) {
                IconoVista(.tilde, tamano: 24).foregroundStyle(Color.berenjena800)
                    .frame(width: 56, height: 56).background(Color.yema, in: Circle())
                Text("Todos al día").tipo(.texto(20, 700)).foregroundStyle(Color.tinta)
                Text("No hay comprobantes para confirmar ni cuotas atrasadas.")
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
        .transition(.opacity)
    }
}

/// El comprobante dibujado (.ticket): renglones arena y uno verde.
struct Ticket: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Capsule().fill(Color.arena300).frame(height: 3)
            Capsule().fill(Color.arena300).frame(width: 18 * 0.65, height: 3)
            Capsule().fill(Color.ok).frame(width: 18 * 0.7, height: 4)
            Capsule().fill(Color.arena300).frame(height: 3)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 5)
        .frame(width: 28, height: 36, alignment: .topLeading)
        .background(Color.arena50, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
        .accessibilityHidden(true)
    }
}

