import SwiftUI

/// Gráficos de app-v4.html, dibujados con Canvas con las mismas medidas del SVG (sólo cambia el ancho,
/// que se adapta a la tarjeta).
private func textoEje(_ s: String, color: Color, tracking: Bool = false) -> Text {
    Text(s)
        .font(Tipo.uiFont(.figtree, tamano: 12, peso: 700).asFont)
        .tracking(tracking ? 12 * 0.07 : 0)
        .foregroundColor(color)
}

extension UIFont { var asFont: Font { Font(self) } }

/// Línea con relleno (la sentadilla goblet de la ficha): 100 de alto, grilla en 10 y 20.
struct GraficoProgreso: View {
    let valores: [Double]
    let meses: [String]
    var minimo: Double = 5
    var maximo: Double = 26
    var marcas: [Double] = [10, 20]

    var body: some View {
        Canvas { ctx, size in
            let W = size.width, H = size.height, iz: CGFloat = 24, de: CGFloat = 12, ar: CGFloat = 12, ab: CGFloat = 22
            let n = valores.count
            let x = { (i: Int) -> CGFloat in iz + CGFloat(i) * (W - iz - de) / CGFloat(max(n - 1, 1)) }
            let y = { (v: Double) -> CGFloat in ar + CGFloat(maximo - v) * (H - ar - ab) / CGFloat(maximo - minimo) }
            for v in marcas {
                var l = Path(); l.move(to: CGPoint(x: iz, y: y(v))); l.addLine(to: CGPoint(x: W, y: y(v)))
                ctx.stroke(l, with: .color(.arena100), lineWidth: 1)
                ctx.draw(textoEje(String(Int(v)), color: .arena600), at: CGPoint(x: 0, y: y(v)), anchor: .leading)
            }
            for (i, m) in meses.enumerated() where i % 2 == 0 {
                let ancla: UnitPoint = i == 0 ? .leading : i == n - 1 ? .trailing : .center
                let dx: CGFloat = i == 0 ? -6 : i == n - 1 ? 8 : 0
                ctx.draw(textoEje(m, color: .arena600, tracking: true), at: CGPoint(x: x(i) + dx, y: H - 6), anchor: ancla)
            }
            let puntos = valores.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element)) }
            var area = Path()
            area.addLines(puntos)
            area.addLine(to: CGPoint(x: x(n - 1), y: H - ab))
            area.addLine(to: CGPoint(x: x(0), y: H - ab))
            area.closeSubpath()
            ctx.fill(area, with: .color(Color.yema.opacity(0.22)))
            var linea = Path(); linea.addLines(puntos)
            ctx.stroke(linea, with: .color(.berenjena800), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            for (i, p) in puntos.enumerated() {
                let ultimo = i == n - 1
                let r: CGFloat = ultimo ? 5.5 : 3
                let c = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
                ctx.fill(c, with: .color(ultimo ? .yema : .white))
                ctx.stroke(c, with: .color(.berenjena800), lineWidth: ultimo ? 2.2 : 2)
            }
        }
        .frame(height: 100)
        .accessibilityElement()
        .accessibilityLabel("Progreso de \(meses.first ?? "") a \(meses.last ?? ""): de \(Int(valores.first ?? 0)) a \(Int(valores.last ?? 0)) kilos")
    }
}

/// Línea chica del récord (132 × 88): cuatro meses, el último en yema.
struct GraficoRecord: View {
    let valores: [Double]
    let meses: [String]
    var minimo: Double = 26
    var maximo: Double = 52

    var body: some View {
        Canvas { ctx, size in
            let W = size.width, H = size.height, iz: CGFloat = 14, de: CGFloat = 14, ar: CGFloat = 10, ab: CGFloat = 22
            let n = valores.count
            let x = { (i: Int) -> CGFloat in iz + CGFloat(i) * (W - iz - de) / CGFloat(max(n - 1, 1)) }
            let y = { (v: Double) -> CGFloat in ar + CGFloat(maximo - v) * (H - ar - ab) / CGFloat(maximo - minimo) }
            var base = Path(); base.move(to: CGPoint(x: 0, y: H - ab + 6)); base.addLine(to: CGPoint(x: W, y: H - ab + 6))
            ctx.stroke(base, with: .color(.arena100), lineWidth: 1)
            for (i, m) in meses.enumerated() {
                ctx.draw(textoEje(m, color: .arena600, tracking: true), at: CGPoint(x: x(i), y: H - 6), anchor: .center)
            }
            let puntos = valores.enumerated().map { CGPoint(x: x($0.offset), y: y($0.element)) }
            var linea = Path(); linea.addLines(puntos)
            ctx.stroke(linea, with: .color(.berenjena800), style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            for (i, p) in puntos.enumerated() {
                let ultimo = i == n - 1
                let r: CGFloat = ultimo ? 5.5 : 3
                let c = Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r * 2, height: r * 2))
                ctx.fill(c, with: .color(ultimo ? .yema : .white))
                ctx.stroke(c, with: .color(.berenjena800), lineWidth: ultimo ? 2.2 : 2)
            }
        }
        .frame(width: 132, height: 88)
        .accessibilityElement()
        .accessibilityLabel("Mejor marca por mes: \(valores.map { String(format: "%g", $0) }.joined(separator: ", ")) kilos")
    }
}

/// Barras de pasos de 7 días (120 × 44) con la línea punteada del promedio.
struct GraficoPasos: View {
    let pasos: [Double]
    var maximo: Double = 10500

    var body: some View {
        Canvas { ctx, size in
            let W = size.width, H = size.height, bw: CGFloat = 10
            let paso = (W - bw) / CGFloat(max(pasos.count - 1, 1))
            for (i, v) in pasos.enumerated() {
                let h = CGFloat(v / maximo) * H
                ctx.fill(Path(roundedRect: CGRect(x: CGFloat(i) * paso, y: H - h, width: bw, height: h), cornerRadius: 3),
                         with: .color(Color(hex: 0xDCD2E2)))
            }
            let prom = pasos.reduce(0, +) / Double(max(pasos.count, 1))
            let yp = H - CGFloat(prom / maximo) * H
            var l = Path(); l.move(to: CGPoint(x: 0, y: yp)); l.addLine(to: CGPoint(x: W, y: yp))
            ctx.stroke(l, with: .color(Color.berenjena800.opacity(0.5)), style: StrokeStyle(lineWidth: 1.5, dash: [3, 3]))
        }
        .frame(width: 120, height: 44)
        .accessibilityHidden(true)
    }
}

/// Ingresos de los últimos 6 meses sobre la banda (148 de alto), con el «esperado» punteado del mes en curso.
struct GraficoIngresos: View {
    /// En miles de pesos.
    let valores: [Double]
    let meses: [String]
    let esperado: Double
    var maximo: Double = 1600

    var body: some View {
        Canvas { ctx, size in
            let W = size.width, H = size.height, iz: CGFloat = 56, ab: CGFloat = 24, ar: CGFloat = 20
            let y = { (v: Double) -> CGFloat in ar + CGFloat(maximo - v) * (H - ar - ab) / CGFloat(maximo) }
            let ancho = (W - iz) / CGFloat(max(valores.count, 1)), bw: CGFloat = 28
            for (v, t) in [(0.0, "0"), (500, "$500 mil"), (1000, "$1 M"), (1500, "$1,5 M")] {
                var l = Path(); l.move(to: CGPoint(x: iz, y: y(v))); l.addLine(to: CGPoint(x: W, y: y(v)))
                ctx.stroke(l, with: .color(Color.hueso.opacity(v == 0 ? 0.25 : 0.1)), lineWidth: 1)
                ctx.draw(textoEje(t, color: .berenjena300), at: CGPoint(x: 0, y: y(v)), anchor: .leading)
            }
            for (i, v) in valores.enumerated() {
                let cx = iz + ancho * CGFloat(i) + ancho / 2, ult = i == valores.count - 1
                if ult && esperado > v {
                    let r = CGRect(x: cx - bw / 2 + 1, y: y(esperado) + 1, width: bw - 2, height: y(v) - y(esperado))
                    ctx.stroke(Path(roundedRect: r, cornerRadius: 6), with: .color(.yema), style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                    ctx.draw(textoEje("esperado", color: .yema), at: CGPoint(x: cx + bw / 2 + 4, y: y(esperado) - 10), anchor: .trailing)
                }
                let t = y(v), b = y(0)
                let barra = Path(roundedRect: CGRect(x: cx - bw / 2, y: t, width: bw, height: b - t),
                                 cornerRadii: RectangleCornerRadii(topLeading: 6, bottomLeading: 0, bottomTrailing: 0, topTrailing: 6))
                ctx.fill(barra, with: .color(ult ? Color.yema : Color.hueso.opacity(0.2)))
                ctx.draw(textoEje(meses[i], color: ult ? .yema : .berenjena300, tracking: true), at: CGPoint(x: cx, y: H - 6), anchor: .center)
            }
        }
        .frame(height: 148)
        .accessibilityElement()
        .accessibilityLabel("Cobrado por mes, en miles: " + zip(meses, valores).map { "\($0.0) \(Int($0.1))" }.joined(separator: ", "))
    }
}

/// Barra de progreso de 8 (pasos de hoy).
struct BarraProgreso: View {
    let fraccion: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.arena100)
                Capsule().fill(Color.yema).frame(width: g.size.width * min(max(fraccion, 0), 1))
            }
        }
        .frame(height: 8)
    }
}

/// Medalla hexagonal: berenjena con el ícono en yema (o naranja la de racha); bloqueada en arena.
struct MedallaVista: View {
    let medalla: Medalla

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Hexagono()
                    .fill(medalla.ganada ? Color.berenjena800 : Color.arena100)
                    .overlay(Hexagono().stroke(medalla.ganada ? Color.berenjena800 : Color.arena100,
                                               style: StrokeStyle(lineWidth: 4.4, lineJoin: .round)))
                    .frame(width: 56, height: 62)
                IconoVista(medalla.icono, tamano: 24)
                    .foregroundStyle(medalla.ganada ? (medalla.deRacha ? Color.racha : Color.yema) : Color.arena500)
            }
            .frame(width: 56, height: 62)
            Text(medalla.titulo)
                .tipo(.texto(12, medalla.ganada ? 700 : 600))
                .foregroundStyle(medalla.ganada ? Color.tinta : Color.arena600)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(medalla.titulo), \(medalla.ganada ? "ganada" : "todavía no")")
    }
}
