import SwiftUI

/// Los íconos de identidad de Otra Más, copiados tal cual de los `<symbol>` de app-v4.html (viewBox 24×24,
/// trazo redondo). Lo genérico del sistema (compartir, ajustes) va con SF Symbols.
enum Icono: String, CaseIterable {
    case casa, casaOn, gente, plata, cal, pesa, atras, der, abajo, wa, tilde, camara, mas, menos, cerrar,
         cambio, reloj, puntos, copiar, candado, recarga, play, agarre, lluvia, pin, trofeo, recibo, fuego,
         sol, bandera, rayo, estrella, diez, sube, corazon

    fileprivate enum Elemento {
        case trazo(String)
        case relleno(String)
        case trazoYRelleno(String)
        case circulo(CGFloat, CGFloat, CGFloat)
        case circuloLleno(CGFloat, CGFloat, CGFloat)
        case rect(CGFloat, CGFloat, CGFloat, CGFloat, CGFloat)
    }

    fileprivate var elementos: [Elemento] {
        switch self {
        case .casa: return [.trazo("M3.5 10.5 12 3.5l8.5 7"), .trazo("M5.5 9v10.5h4.5v-6h4v6h4.5V9")]
        case .casaOn: return [.relleno("M12 3.2 2.9 10.6a.9.9 0 0 0 1.1 1.4l.9-.7v8.4c0 .6.4 1 1 1h4.1v-6h4v6h4.1c.6 0 1-.4 1-1v-8.4l.9.7a.9.9 0 0 0 1.1-1.4Z")]
        case .gente: return [.circulo(9, 8, 3.5), .trazo("M2.5 20c.6-3.6 3.2-5.5 6.5-5.5s5.9 1.9 6.5 5.5"), .trazo("M15.5 4.8a3.5 3.5 0 0 1 0 6.4M18 14.8c2 .6 3.2 2.4 3.5 5.2")]
        case .plata: return [.rect(2.5, 6, 19, 12.5, 2.5), .circulo(12, 12.25, 2.75), .trazo("M6 9.5v.01M18 15v.01")]
        case .cal: return [.rect(3, 4.5, 18, 16, 3), .trazo("M3 9.5h18M8 2.8v3.4M16 2.8v3.4"), .trazo("M7.5 13.5h2M11 13.5h2M14.5 13.5h2M7.5 17h2M11 17h2")]
        case .pesa: return [.trazo("M6.5 7v10M17.5 7v10M3.5 9.5v5M20.5 9.5v5M6.5 12h11")]
        case .atras: return [.trazo("M15 5l-7 7 7 7")]
        case .der: return [.trazo("M9 5l7 7-7 7")]
        case .abajo: return [.trazo("M6 9l6 6 6-6")]
        case .wa: return [.trazo("M12 3a9 9 0 0 0-7.8 13.5L3 21l4.6-1.2A9 9 0 1 0 12 3Z"),
                          .relleno("M9 8.3c.2-.4.5-.4.8-.4h.5c.2 0 .4.1.5.4l.7 1.7c.1.2 0 .5-.1.6l-.6.7c.6 1.2 1.6 2.1 2.8 2.7l.7-.7c.2-.2.4-.2.6-.1l1.7.8c.2.1.3.3.3.5v.5c0 .4-.2.7-.6.9-.9.4-2 .3-3.5-.5a9.4 9.4 0 0 1-3.6-3.6c-.7-1.5-.8-2.6-.2-3.5Z")]
        case .tilde: return [.trazo("M5 12.5l4.5 4.5L19 7.5")]
        case .camara: return [.trazo("M4 8.5A2.5 2.5 0 0 1 6.5 6h1.3l1.4-2h5.6l1.4 2h1.3A2.5 2.5 0 0 1 20 8.5v9a2.5 2.5 0 0 1-2.5 2.5h-11A2.5 2.5 0 0 1 4 17.5Z"), .circulo(12, 13, 3.5)]
        case .mas: return [.trazo("M12 5v14M5 12h14")]
        case .menos: return [.trazo("M5 12h14")]
        case .cerrar: return [.trazo("M6.5 6.5l11 11M17.5 6.5l-11 11")]
        case .cambio: return [.trazo("M4 8h13l-3.5-3.5M20 16H7l3.5 3.5")]
        case .reloj: return [.circulo(12, 12, 8.5), .trazo("M12 7.5V12l3 2")]
        case .puntos: return [.circuloLleno(5.5, 12, 1.4), .circuloLleno(12, 12, 1.4), .circuloLleno(18.5, 12, 1.4)]
        case .copiar: return [.rect(8.5, 8.5, 12, 12, 2.5), .trazo("M15.5 8.5V6a2.5 2.5 0 0 0-2.5-2.5H6A2.5 2.5 0 0 0 3.5 6v7A2.5 2.5 0 0 0 6 15.5h2.5")]
        case .candado: return [.rect(5, 10.5, 14, 10, 2.5), .trazo("M8 10.5V8a4 4 0 0 1 8 0v2.5")]
        case .recarga: return [.trazo("M19.5 12a7.5 7.5 0 1 1-2.2-5.3M19.5 4v4.5H15")]
        case .play: return [.trazoYRelleno("M8 5.5v13l10.5-6.5Z")]
        case .agarre: return [.circuloLleno(9, 6, 1.3), .circuloLleno(15, 6, 1.3), .circuloLleno(9, 12, 1.3),
                              .circuloLleno(15, 12, 1.3), .circuloLleno(9, 18, 1.3), .circuloLleno(15, 18, 1.3)]
        case .lluvia: return [.trazo("M7 15.5a4.5 4.5 0 1 1 1.2-8.8A5.5 5.5 0 0 1 18.5 9 3.5 3.5 0 0 1 17.5 15.5Z"), .trazo("M8.5 18.5l-1 2M12.5 18.5l-1 2M16.5 18.5l-1 2")]
        case .pin: return [.trazo("M12 21s-6.5-5.7-6.5-11a6.5 6.5 0 0 1 13 0c0 5.3-6.5 11-6.5 11Z"), .circulo(12, 10, 2.3)]
        case .trofeo: return [.trazo("M7.5 4h9v5a4.5 4.5 0 0 1-9 0ZM7.5 6H4.5v1.5A3 3 0 0 0 7.6 10.5M16.5 6h3v1.5a3 3 0 0 1-3.1 3M12 13.5v3.5M8.5 20.5h7M9.5 20.5c0-2 1-3.5 2.5-3.5s2.5 1.5 2.5 3.5")]
        case .recibo: return [.trazo("M6 3.5h12v17l-2-1.3-2 1.3-2-1.3-2 1.3-2-1.3-2 1.3Z"), .trazo("M9 8h6M9 11.5h6M9 15h3.5")]
        case .fuego: return [.trazo("M12 21.2c-3.9 0-6.6-2.7-6.6-6.3 0-3.4 2.3-5.5 3.7-7.7.3 1.9 1.2 3.1 2.4 3.7-.1-3.1 1-5.8 3.3-7.4-.2 2.9 1 4.5 2.4 6.1 1 1.3 1.5 2.7 1.5 4.6 0 4.2-2.8 7-6.7 7Z"),
                             .trazo("M12 21.2c-1.7 0-2.9-1.2-2.9-2.9 0-1.8 1.4-2.8 2.4-4.3.4 1.2 1.1 1.9 1.9 2.3.7.4 1.4 1.1 1.4 2.1 0 1.6-1.2 2.8-2.8 2.8Z")]
        case .sol: return [.trazo("M5 17.5a7 7 0 0 1 14 0"), .trazo("M2.5 17.5h19M12 4v2.5M4.6 7.6l1.8 1.8M19.4 7.6l-1.8 1.8M7 20.5h10")]
        case .bandera: return [.trazo("M5.5 21V3.8"), .trazo("M5.5 4.5h11.5l-2.3 4 2.3 4H5.5")]
        case .rayo: return [.trazo("M13.5 2.8 5 13.5h6.2l-1 7.7 8.6-10.8h-6.3Z")]
        case .estrella: return [.trazo("M12 3.3l2.6 5.4 5.9.8-4.3 4.1 1 5.9L12 16.7l-5.2 2.8 1-5.9-4.3-4.1 5.9-.8Z")]
        case .diez: return [.trazo("M5 8.5 7.5 6.8V17.5"), .rect(11, 6.5, 8, 11, 4)]
        case .sube: return [.trazo("M4 16.5l5.5-5.5 4 4 6.5-6.5"), .trazo("M15 8.5h5v5")]
        case .corazon: return [.relleno("M12 21c-.3 0-.6-.1-.8-.3C7.6 17.6 2.5 13.6 2.5 8.9 2.5 6 4.7 3.8 7.5 3.8c1.8 0 3.4.9 4.5 2.4 1.1-1.5 2.7-2.4 4.5-2.4 2.8 0 5 2.2 5 5.1 0 4.7-5.1 8.7-8.7 11.8-.2.2-.5.3-.8.3Z")]
        }
    }

    /// Partes trazadas y rellenas, en coordenadas del viewBox (24×24). Se calculan una sola vez.
    fileprivate var partes: (trazo: Path, relleno: Path) {
        if let p = Icono.cachePartes[self] { return p }
        var t = Path(), r = Path()
        for e in elementos {
            switch e {
            case .trazo(let d): t.addPath(SVGPath.path(d))
            case .relleno(let d): r.addPath(SVGPath.path(d))
            case .trazoYRelleno(let d): let p = SVGPath.path(d); t.addPath(p); r.addPath(p)
            case .circulo(let x, let y, let rr): t.addEllipse(in: CGRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2))
            case .circuloLleno(let x, let y, let rr): r.addEllipse(in: CGRect(x: x - rr, y: y - rr, width: rr * 2, height: rr * 2))
            case .rect(let x, let y, let w, let h, let rx):
                t.addRoundedRect(in: CGRect(x: x, y: y, width: w, height: h), cornerSize: CGSize(width: rx, height: rx))
            }
        }
        Icono.cachePartes[self] = (t, r)
        return (t, r)
    }
    nonisolated(unsafe) private static var cachePartes: [Icono: (trazo: Path, relleno: Path)] = [:]
}

/// Dibuja un ícono a 24 (navegación), 20 (botones) o 16 (junto a texto), con el grosor del CSS
/// (1,8 · 2 · 2,2 en unidades del viewBox).
struct IconoVista: View {
    let icono: Icono
    var tamano: CGFloat = 24
    var grosor: CGFloat? = nil

    init(_ icono: Icono, tamano: CGFloat = 24, grosor: CGFloat? = nil) {
        self.icono = icono; self.tamano = tamano; self.grosor = grosor
    }

    var body: some View {
        let g = grosor ?? (tamano <= 16 ? 2.2 : tamano <= 20 ? 2 : 1.8)
        let partes = icono.partes
        Canvas { ctx, size in
            let s = size.width / 24
            let tr = CGAffineTransform(scaleX: s, y: s)
            ctx.stroke(partes.trazo.applying(tr), with: .foreground,
                       style: StrokeStyle(lineWidth: g * s, lineCap: .round, lineJoin: .round))
            ctx.fill(partes.relleno.applying(tr), with: .foreground)
        }
        .frame(width: tamano, height: tamano)
        .accessibilityHidden(true)
    }
}

/// El hexágono de las medallas (symbol #hex, viewBox 64×70).
struct Hexagono: Shape {
    func path(in rect: CGRect) -> Path {
        let base = SVGPath.path("M32 3.5 58.5 18.5v33L32 66.5 5.5 51.5v-33Z")
        let s = min(rect.width / 64, rect.height / 70)
        let dx = rect.minX + (rect.width - 64 * s) / 2, dy = rect.minY + (rect.height - 70 * s) / 2
        return base.applying(CGAffineTransform(scaleX: s, y: s).concatenating(CGAffineTransform(translationX: dx, y: dy)))
    }
}

/// Lector mínimo de `d` de SVG (M L H V C S Q T A Z, absolutos y relativos, con repetición implícita).
enum SVGPath {
    static func path(_ d: String) -> Path {
        var p = Path()
        var s = Escaner(Array(d.utf8))
        var actual = CGPoint.zero, inicio = CGPoint.zero
        var ultimoControl: CGPoint? = nil
        var comando: UInt8 = 0
        while true {
            s.saltarSeparadores()
            guard let c = s.mirar() else { break }
            if Escaner.esLetra(c) { comando = c; s.i += 1 } else if comando == 0 { break }
            let rel = comando >= 97
            let base = rel ? actual : .zero
            switch comando | 0x20 { // en minúscula
            case UInt8(ascii: "m"):
                guard let x = s.numero(), let y = s.numero() else { return p }
                actual = CGPoint(x: base.x + x, y: base.y + y); inicio = actual
                p.move(to: actual)
                comando = rel ? UInt8(ascii: "l") : UInt8(ascii: "L") // pares siguientes: lineto
                ultimoControl = nil
            case UInt8(ascii: "l"):
                guard let x = s.numero(), let y = s.numero() else { return p }
                actual = CGPoint(x: base.x + x, y: base.y + y); p.addLine(to: actual); ultimoControl = nil
            case UInt8(ascii: "h"):
                guard let x = s.numero() else { return p }
                actual = CGPoint(x: (rel ? actual.x : 0) + x, y: actual.y); p.addLine(to: actual); ultimoControl = nil
            case UInt8(ascii: "v"):
                guard let y = s.numero() else { return p }
                actual = CGPoint(x: actual.x, y: (rel ? actual.y : 0) + y); p.addLine(to: actual); ultimoControl = nil
            case UInt8(ascii: "c"):
                guard let x1 = s.numero(), let y1 = s.numero(), let x2 = s.numero(), let y2 = s.numero(),
                      let x = s.numero(), let y = s.numero() else { return p }
                let c1 = CGPoint(x: base.x + x1, y: base.y + y1), c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addCurve(to: actual, control1: c1, control2: c2); ultimoControl = c2
            case UInt8(ascii: "s"):
                guard let x2 = s.numero(), let y2 = s.numero(), let x = s.numero(), let y = s.numero() else { return p }
                let c1 = ultimoControl.map { CGPoint(x: 2 * actual.x - $0.x, y: 2 * actual.y - $0.y) } ?? actual
                let c2 = CGPoint(x: base.x + x2, y: base.y + y2)
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addCurve(to: actual, control1: c1, control2: c2); ultimoControl = c2
            case UInt8(ascii: "q"):
                guard let x1 = s.numero(), let y1 = s.numero(), let x = s.numero(), let y = s.numero() else { return p }
                let c = CGPoint(x: base.x + x1, y: base.y + y1)
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addQuadCurve(to: actual, control: c); ultimoControl = c
            case UInt8(ascii: "t"):
                guard let x = s.numero(), let y = s.numero() else { return p }
                let c = ultimoControl.map { CGPoint(x: 2 * actual.x - $0.x, y: 2 * actual.y - $0.y) } ?? actual
                actual = CGPoint(x: base.x + x, y: base.y + y)
                p.addQuadCurve(to: actual, control: c); ultimoControl = c
            case UInt8(ascii: "a"):
                guard let rx = s.numero(), let ry = s.numero(), let rot = s.numero(),
                      let grande = s.bandera(), let barrido = s.bandera(),
                      let x = s.numero(), let y = s.numero() else { return p }
                let fin = CGPoint(x: base.x + x, y: base.y + y)
                arco(&p, desde: actual, hasta: fin, rx: rx, ry: ry, rotacion: rot, grande: grande, barrido: barrido)
                actual = fin; ultimoControl = nil
            case UInt8(ascii: "z"):
                p.closeSubpath(); actual = inicio; ultimoControl = nil
                comando = 0
                continue
            default:
                return p
            }
        }
        return p
    }

    /// Arco elíptico de SVG pasado a curvas de Bézier (parametrización por centro, W3C F.6).
    private static func arco(_ p: inout Path, desde p0: CGPoint, hasta p1: CGPoint, rx rx0: CGFloat, ry ry0: CGFloat,
                             rotacion: CGFloat, grande: Bool, barrido: Bool) {
        var rx = abs(rx0), ry = abs(ry0)
        if rx == 0 || ry == 0 || p0 == p1 { p.addLine(to: p1); return }
        let phi = rotacion * .pi / 180, cp = cos(phi), sp = sin(phi)
        let dx = (p0.x - p1.x) / 2, dy = (p0.y - p1.y) / 2
        let x1 = cp * dx + sp * dy, y1 = -sp * dx + cp * dy
        let lambda = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
        if lambda > 1 { rx *= sqrt(lambda); ry *= sqrt(lambda) }
        let num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
        let den = rx * rx * y1 * y1 + ry * ry * x1 * x1
        var coef = sqrt(max(0, num / den))
        if grande == barrido { coef = -coef }
        let cxp = coef * rx * y1 / ry, cyp = -coef * ry * x1 / rx
        let cx = cp * cxp - sp * cyp + (p0.x + p1.x) / 2
        let cy = sp * cxp + cp * cyp + (p0.y + p1.y) / 2
        func angulo(_ ux: CGFloat, _ uy: CGFloat, _ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let a = atan2(ux * vy - uy * vx, ux * vx + uy * vy)
            return a
        }
        let t1 = angulo(1, 0, (x1 - cxp) / rx, (y1 - cyp) / ry)
        var dt = angulo((x1 - cxp) / rx, (y1 - cyp) / ry, (-x1 - cxp) / rx, (-y1 - cyp) / ry)
        if !barrido && dt > 0 { dt -= 2 * .pi } else if barrido && dt < 0 { dt += 2 * .pi }
        let n = max(1, Int(ceil(abs(dt) / (.pi / 2))))
        let paso = dt / CGFloat(n)
        let k = 4.0 / 3.0 * tan(paso / 4)
        func punto(_ t: CGFloat) -> CGPoint {
            CGPoint(x: cx + rx * cos(t) * cp - ry * sin(t) * sp, y: cy + rx * cos(t) * sp + ry * sin(t) * cp)
        }
        func derivada(_ t: CGFloat) -> CGPoint {
            CGPoint(x: -rx * sin(t) * cp - ry * cos(t) * sp, y: -rx * sin(t) * sp + ry * cos(t) * cp)
        }
        var t = t1
        for _ in 0..<n {
            let a = punto(t), b = punto(t + paso), da = derivada(t), db = derivada(t + paso)
            p.addCurve(to: b, control1: CGPoint(x: a.x + k * da.x, y: a.y + k * da.y),
                       control2: CGPoint(x: b.x - k * db.x, y: b.y - k * db.y))
            t += paso
        }
    }

    private struct Escaner {
        let b: [UInt8]
        var i = 0
        init(_ b: [UInt8]) { self.b = b }
        func mirar() -> UInt8? { i < b.count ? b[i] : nil }
        static func esLetra(_ c: UInt8) -> Bool { (c >= 65 && c <= 90) || (c >= 97 && c <= 122) && c != 101 }
        mutating func saltarSeparadores() {
            while i < b.count, b[i] == 32 || b[i] == 44 || b[i] == 10 || b[i] == 9 || b[i] == 13 { i += 1 }
        }
        mutating func bandera() -> Bool? {
            saltarSeparadores()
            guard i < b.count else { return nil }
            let c = b[i]
            if c == 48 || c == 49 { i += 1; return c == 49 }
            return nil
        }
        mutating func numero() -> CGFloat? {
            saltarSeparadores()
            let ini = i
            if i < b.count, b[i] == 43 || b[i] == 45 { i += 1 }
            var punto = false, digitos = false
            while i < b.count {
                let c = b[i]
                if c >= 48 && c <= 57 { digitos = true; i += 1 }
                else if c == 46 && !punto { punto = true; i += 1 }
                else if (c == 101 || c == 69) && digitos {
                    i += 1
                    if i < b.count, b[i] == 43 || b[i] == 45 { i += 1 }
                } else { break }
            }
            guard digitos, let s = String(bytes: b[ini..<i], encoding: .ascii), let v = Double(s) else { i = ini; return nil }
            return CGFloat(v)
        }
    }
}
