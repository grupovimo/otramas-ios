import SwiftUI

/// 9 · Tu mes: lo cobrado, los últimos seis meses, tres números y cómo te pagan.
struct TuMes: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let r = estado.profe.resumen
        PantallaProfe {
            NavBanda(atras: "Inicio", accionAtras: { dismiss() }) { EmptyView() }
            CabeceraPestana(titulo: "Tu mes") { LadoCabecera(texto: r.mes.capitalized) }
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 8) {
                        Etiqueta("Cobrado", color: .berenjena300)
                        Text(Formato.plata(r.cobrado)).tipo(.numero(40), alto: 40).foregroundStyle(Color.hueso)
                            .contentTransition(.numericText(value: Double(r.cobrado)))
                    }
                    Spacer(minLength: 8)
                    HStack(spacing: 4) {
                        IconoVista(.sube, tamano: 16)
                        Text("\(r.variacion) % más que \(r.mesAnterior)").tipo(.texto(14, 700)).lineLimit(1).minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(Color.yema)
                    .padding(.bottom, 4)
                }
                GraficoIngresos(valores: r.ingresos, meses: r.meses, esperado: Double(estado.esperado) / 1000)
                    .padding(.top, 16)
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 16)
        } cuerpo: {
            HStack(spacing: 12) {
                dato("\(r.alumnosActivos)", nil, "Alumnos activos")
                dato("\(r.asistencia)", "%", "Asistencia promedio")
                dato("+\(r.nuevos)", nil, "Nuevos este mes")
            }
            TituloSeccion(texto: "Cómo te pagan") {
                Text("\(r.medios.reduce(0) { $0 + $1.cuotas }) cuotas").tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            }
            pagan(r)
        }
    }

    private func dato(_ n: String, _ chico: String?, _ l: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Numero(valor: n, tamano: 28, chico: chico, tamanoChico: 20)
            Text(l).tipo(.texto(14, 600)).foregroundStyle(Color.arena700).lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 104, alignment: .topLeading)
        .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .sombraTarjeta()
        .accessibilityElement(children: .combine)
    }

    private func pagan(_ r: ResumenMes) -> some View {
        let total = r.medios.reduce(0) { $0 + $1.cuotas }
        let colores: [MedioPago: Color] = [.transferencia: .berenjena800, .efectivo: .yema, .mercadoPago: .berenjena300]
        let primero = r.medios.first
        let pct = total == 0 ? 0 : Int((Double(primero?.cuotas ?? 0) / Double(total) * 100).rounded())
        return Tarjeta(relleno: 16) {
            HStack(spacing: 24) {
                Anillo(tamano: 112, grosor: 14, total: Double(total),
                       segmentos: r.medios.map { .init(valor: Double($0.cuotas), color: colores[$0.medio] ?? .arena300) },
                       pista: .arena50, separacion: 3) {
                    VStack(spacing: 4) {
                        Text("\(pct)%").tipo(.numero(28), alto: 28).foregroundStyle(Color.berenjena800)
                        Text("transfieren").tipo(.texto(12, 600)).foregroundStyle(Color.texto2)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(pct) por ciento transfieren")
                VStack(spacing: 12) {
                    ForEach(r.medios, id: \.medio) { m in
                        HStack(spacing: 8) {
                            RoundedRectangle(cornerRadius: 3).fill(colores[m.medio] ?? .arena300).frame(width: 12, height: 12)
                            Text(m.medio.rawValue).tipo(.texto(16, 600)).foregroundStyle(Color.arena700).lineLimit(1).minimumScaleFactor(0.8)
                            Spacer(minLength: 4)
                            Text("\(m.cuotas)").tipo(.numero(20), alto: 20).foregroundStyle(Color.tinta)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
    }
}
