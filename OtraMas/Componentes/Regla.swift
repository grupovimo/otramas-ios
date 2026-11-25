import SwiftUI

/// Regla deslizable para números (peso, altura, edad): se arrastra y el valor queda en el centro, marcado en yema.
struct Regla: View {
    @Binding var valor: Double
    var rango: ClosedRange<Double>
    var paso: Double = 1
    var unidad: String
    /// Cada cuántos pasos va una marca larga con número.
    var cadaLarga: Int = 10

    @State private var posicion: Int?
    private let ancho: CGFloat = 12

    private var cantidad: Int { Int(((rango.upperBound - rango.lowerBound) / paso).rounded()) }
    private func valorDe(_ i: Int) -> Double { rango.lowerBound + Double(i) * paso }
    private func indiceDe(_ v: Double) -> Int { Int(((min(max(v, rango.lowerBound), rango.upperBound) - rango.lowerBound) / paso).rounded()) }

    var body: some View {
        VStack(spacing: 20) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(Formato.decimal(valor))
                    .tipo(.numero(88))
                    .foregroundStyle(Color.yema)
                    .contentTransition(.numericText(value: valor))
                    .animation(.snappy(duration: 0.15), value: valor)
                Text(unidad).tipo(.texto(20, 700)).foregroundStyle(Color.berenjena300)
            }
            .frame(height: 96)
            .accessibilityHidden(true)

            GeometryReader { g in
                ScrollView(.horizontal) {
                    LazyHStack(spacing: 0) {
                        ForEach(0...cantidad, id: \.self) { i in
                            let larga = i % cadaLarga == 0
                            let media = !larga && i % (cadaLarga / 2 == 0 ? 1 : cadaLarga / 2) == 0
                            VStack(spacing: 6) {
                                Capsule()
                                    .fill(Color.hueso.opacity(larga ? 0.7 : 0.28))
                                    .frame(width: larga ? 2.5 : 1.5, height: larga ? 40 : media ? 28 : 18)
                                    .frame(height: 40, alignment: .bottom)
                                Text(larga ? Formato.decimal(valorDe(i)) : " ")
                                    .tipo(.texto(12, 700))
                                    .foregroundStyle(Color.berenjena300)
                                    .fixedSize()
                                    .frame(width: ancho)
                            }
                            .frame(width: ancho)
                            .id(i)
                        }
                    }
                    .scrollTargetLayout()
                }
                .contentMargins(.horizontal, (g.size.width - ancho) / 2, for: .scrollContent)
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $posicion, anchor: .center)
                .scrollIndicators(.hidden)
                .overlay {
                    // El indicador del centro.
                    Capsule().fill(Color.yema).frame(width: 4, height: 56).offset(y: -8).allowsHitTesting(false)
                }
                .mask(LinearGradient(stops: [.init(color: .clear, location: 0), .init(color: .black, location: 0.18),
                                             .init(color: .black, location: 0.82), .init(color: .clear, location: 1)],
                                     startPoint: .leading, endPoint: .trailing))
            }
            .frame(height: 72)
        }
        .onAppear { posicion = indiceDe(valor) }
        .onChange(of: posicion) { _, nuevo in
            guard let nuevo else { return }
            let v = valorDe(nuevo)
            if v != valor { Haptico.seleccion(); valor = v }
        }
        .accessibilityElement()
        .accessibilityLabel(unidad)
        .accessibilityValue("\(Formato.decimal(valor)) \(unidad)")
        .accessibilityAdjustableAction { d in
            let i = indiceDe(valor) + (d == .increment ? 1 : -1)
            guard i >= 0 && i <= cantidad else { return }
            valor = valorDe(i)
            posicion = i
        }
    }
}
