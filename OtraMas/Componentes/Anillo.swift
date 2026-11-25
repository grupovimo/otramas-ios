import SwiftUI

/// Anillos y donas: el algoritmo `data-anillo` de app-v4.html, porteado.
///
/// - `segmentos`: valor y color, en orden horario desde las 12.
/// - `total`: lo que vale la vuelta entera; lo que no cubren los segmentos queda con el color de `pista`.
/// - `separacion` (gap): con separación, la pista también se dibuja como un segmento más.
/// - `remate` redondo: el trazo se acorta su propio grosor para que la punta redonda no se pase.
/// - `partir`: cada unidad de cada segmento va por separado (el pack de clases).
struct Anillo<Centro: View>: View {
    struct Segmento: Equatable {
        var valor: Double
        var color: Color
    }

    var tamano: CGFloat
    var grosor: CGFloat
    var total: Double
    var segmentos: [Segmento]
    var pista: Color
    var separacion: CGFloat = 0
    var redondo = false
    var partir = false
    @ViewBuilder var centro: () -> Centro

    var body: some View {
        let r = (tamano - grosor) / 2
        let c = 2 * .pi * r
        let ext: CGFloat = redondo ? grosor : 0
        let tramos = calcularTramos(circunferencia: c, ext: ext)
        ZStack {
            if separacion == 0 {
                Circle().stroke(pista, lineWidth: grosor).padding(grosor / 2)
            }
            ForEach(Array(tramos.enumerated()), id: \.offset) { _, t in
                Circle()
                    .trim(from: t.desde, to: t.hasta)
                    .stroke(t.color, style: StrokeStyle(lineWidth: grosor, lineCap: redondo ? .round : .butt))
                    .rotationEffect(.degrees(-90))
                    .padding(grosor / 2)
            }
            centro()
        }
        .frame(width: tamano, height: tamano)
    }

    private struct Tramo { var desde: CGFloat; var hasta: CGFloat; var color: Color }

    private func calcularTramos(circunferencia c: CGFloat, ext: CGFloat) -> [Tramo] {
        var segs: [(Double, Color, Bool)] = []
        for s in segmentos {
            if partir {
                for _ in 0..<Int(s.valor.rounded()) { segs.append((1, s.color, false)) }
            } else {
                segs.append((s.valor, s.color, false))
            }
        }
        let usado = segs.reduce(0) { $0 + $1.0 }
        if usado < total { segs.append((total - usado, pista, true)) }
        var out: [Tramo] = []
        var acc: CGFloat = 0
        for (k, (v, color, esPista)) in segs.enumerated() {
            let len = CGFloat(v / total) * c
            let soloPista = esPista && separacion == 0 && k == segs.count - 1
            if !soloPista {
                let dash = max(len - separacion - ext, 0.01)
                let ini = acc + separacion / 2 + ext / 2
                out.append(Tramo(desde: ini / c, hasta: min((ini + dash) / c, 1), color: color))
            }
            acc += len
        }
        return out
    }
}
