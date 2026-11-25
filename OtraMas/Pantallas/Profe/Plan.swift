import SwiftUI

// MARK: - Franja de Inicio

/// Franja discreta en Inicio mientras dura la prueba (o si está en Gratis).
struct FranjaPlan: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav

    var body: some View {
        if let texto {
            Button { nav.inicio.append(.plan) } label: {
                HStack(spacing: 10) {
                    IconoVista(.rayo, tamano: 16).foregroundStyle(Color.berenjena800)
                        .frame(width: 28, height: 28).background(Color.yema, in: Circle())
                    Text(texto).tipo(.texto(14, 700)).foregroundStyle(Color.tinta)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Ver planes").tipo(.texto(14, 700)).foregroundStyle(Color.yema700)
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 48)
                .background(Color.yema100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            }
            .buttonStyle(Apretable())
            .padding(.bottom, 12)
        }
    }

    private var texto: String? {
        if estado.enPrueba {
            if let p = estado.suscripcion.planElegido { return "Prueba de Pro · después sigue \(p.nombre)" }
            let d = estado.diasDePrueba
            return d == 1 ? "Te queda 1 día de Pro" : "Te quedan \(d) días de Pro"
        }
        if estado.suscripcion.plan == .gratis { return "Plan Gratis · \(estado.activos) de \(estado.tope) alumnos" }
        return nil
    }
}

// MARK: - Tu plan

struct TuPlan: View {
    @Environment(Estado.self) private var estado
    @State private var elegir = false
    @State private var cancelar = false

    var body: some View {
        PantallaProfe {
            CabezaPlan()
            HStack(spacing: 20) {
                AnilloAlumnos()
                ResumenPlan()
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 20)
            Boton(titulo: estado.enPrueba && estado.suscripcion.planElegido == nil ? "Elegir mi plan" : "Cambiar de plan",
                  variante: .yema, alto: .alto, ancho: true) { elegir = true }
                .padding(.horizontal, Espacio.margen)
                .padding(.top, 20)
        } cuerpo: {
            IncluyePlan(plan: estado.planActual)
            AvisoPrecioFijo()
            TituloSeccion("Pagos y facturas")
            FacturasPlan()
            AccionesPlan(cancelar: $cancelar)
        }
        .sheet(isPresented: $elegir) { ElegirPlan() }
        .confirmationDialog("¿Cancelar la suscripción?", isPresented: $cancelar, titleVisibility: .visible) {
            Button("Cancelar suscripción", role: .destructive) { estado.cancelarSuscripcion() }
            Button("Seguir con mi plan", role: .cancel) {}
        } message: {
            Text("Seguís hasta el fin del período. Después pasás a Gratis y los alumnos que superen 10 quedan en pausa, sin borrarse.")
        }
    }
}

private struct CabezaPlan: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavBanda(atras: "Volver", accionAtras: { dismiss() }) { EmptyView() }
        VStack(alignment: .leading, spacing: 6) {
            Etiqueta("Tu plan", color: .berenjena300)
            Titulo(estado.enPrueba ? "Pro · prueba" : estado.suscripcion.plan.nombre, tamano: 40, color: .hueso)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
    }
}

/// Anillo de alumnos activos sobre el tope del plan (18/25).
private struct AnilloAlumnos: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let lleno = estado.activos >= estado.tope
        Anillo(tamano: 112, grosor: 12, total: Double(estado.tope),
               segmentos: [.init(valor: Double(min(estado.activos, estado.tope)), color: lleno ? .errorClaro : .yema)],
               pista: .berenjena700, redondo: true) {
            VStack(spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    Text("\(estado.activos)").tipo(.numero(32))
                    Text("/\(estado.tope)").tipo(.numero(18)).foregroundStyle(Color.berenjena300)
                }
                .foregroundStyle(Color.hueso)
                Text("alumnos").tipo(.texto(12, 600)).foregroundStyle(Color.berenjena300)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(estado.activos) de \(estado.tope) alumnos activos")
    }
}

private struct ResumenPlan: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if estado.enPrueba {
                linea("Prueba", estado.diasDePrueba == 1 ? "Queda 1 día" : "Quedan \(estado.diasDePrueba) días", destacado: true)
                linea("Termina", Fecha.largo(estado.suscripcion.pruebaHasta ?? estado.hoy))
                linea("Después", estado.suscripcion.planElegido.map { "\($0.nombre) · \(Formato.plata($0.precio(estado.suscripcion.periodo)))" } ?? "Gratis, si no elegís")
            } else {
                let s = estado.suscripcion
                linea("Precio", s.plan == .gratis ? "$0" : "\(Formato.plata(s.plan.precio(s.periodo)))\(s.periodo.unidad)", destacado: true)
                linea("Próximo cobro", s.proximoCobro.map { s.renueva ? Fecha.largo($0) : "No se renueva" } ?? "—")
                linea("Medio", s.plan == .gratis ? "—" : "App Store")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func linea(_ e: String, _ v: String, destacado: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(e).tipo(.texto(12, 600)).foregroundStyle(Color.berenjena300)
            Text(v).tipo(.texto(destacado ? 17 : 15, 700)).foregroundStyle(destacado ? Color.yema : Color.hueso)
                .lineLimit(2).fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct IncluyePlan: View {
    let plan: PlanOM
    var body: some View {
        Tarjeta(relleno: 16) {
            Etiqueta("Lo que tenés en \(plan.nombre)")
            VStack(alignment: .leading, spacing: 8) {
                ForEach(plan.incluye, id: \.self) { t in
                    HStack(spacing: 10) {
                        IconoVista(.tilde, tamano: 16, grosor: 2.6).foregroundStyle(Color.ok)
                        Text(t).tipo(.texto(15, 600)).foregroundStyle(Color.tinta)
                    }
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct AvisoPrecioFijo: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            IconoVista(.candado, tamano: 16).foregroundStyle(Color.yema700)
            Text("Precio de lanzamiento fijo hasta \(Fecha.mes(estado.suscripcion.precioFijoHasta)) de \(String(estado.suscripcion.precioFijoHasta.prefix(4))). El alumno nunca paga nada.")
                .tipo(.texto(14, 400)).foregroundStyle(Color.arena700).fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.yema100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
        .padding(.top, 12)
    }
}

private struct FacturasPlan: View {
    @Environment(Estado.self) private var estado
    var body: some View {
        let f = estado.suscripcion.facturas
        if f.isEmpty {
            Tarjeta(relleno: 20) {
                Text(estado.enPrueba ? "Todavía no pagaste nada" : "Sin pagos").tipo(.texto(16, 700)).foregroundStyle(Color.tinta)
                Text(estado.enPrueba ? "Estás en la prueba gratis, sin tarjeta. Las facturas van a aparecer acá." : "Cuando pagues un plan, las facturas van a aparecer acá.")
                    .tipo(.texto(14, 400)).foregroundStyle(Color.texto2).padding(.top, 4).fixedSize(horizontal: false, vertical: true)
            }
        } else {
            Tarjeta {
                ForEach(Array(f.enumerated()), id: \.element.id) { i, x in
                    if i > 0 { Divisor() }
                    FilaFactura(factura: x)
                }
            }
        }
    }
}

private struct FilaFactura: View {
    @Environment(Estado.self) private var estado
    let factura: FacturaOM
    var body: some View {
        HStack(spacing: 12) {
            NomSub(nombre: factura.concepto, sub: Text("Factura \(factura.numero) · \(Fecha.corta(factura.fecha))"))
            Text(Formato.plata(factura.monto)).tipo(.numero(18), alto: 18).foregroundStyle(Color.tinta)
            CompartirBoton(generar: { FacturaPDF.generar(factura, titular: estado.perfilProfe.nombre) }) {
                IconoVista(.recibo, tamano: 18).foregroundStyle(Color.berenjena800)
                    .frame(width: 44, height: 44).background(Color.berenjena100, in: Circle())
            }
            .accessibilityLabel("Descargar factura")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }
}

private struct AccionesPlan: View {
    @Environment(Estado.self) private var estado
    @Binding var cancelar: Bool
    var body: some View {
        VStack(spacing: 0) {
            Button { estado.restaurarCompras() } label: {
                Text("Restaurar compras").tipo(.texto(15, 700)).foregroundStyle(Color.berenjena800).frame(maxWidth: .infinity).frame(height: 48)
            }
            if estado.suscripcion.plan != .gratis && estado.suscripcion.renueva && !estado.enPrueba {
                Button { cancelar = true } label: {
                    Text("Cancelar suscripción").tipo(.texto(15, 700)).foregroundStyle(Color.error).frame(maxWidth: .infinity).frame(height: 48)
                }
            }
            Text("La suscripción se cobra en tu cuenta de App Store y se renueva sola. Podés cancelarla cuando quieras desde acá o desde Ajustes del iPhone. Términos · Privacidad")
                .tipo(.texto(12, 400)).foregroundStyle(Color.arena500).multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
        }
        .padding(.top, 16)
    }
}

// MARK: - Elegir plan (carrito)

struct ElegirPlan: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    var inicial: PlanOM?
    @State private var plan: PlanOM = .pro
    @State private var periodo: PeriodoPlan = .mensual
    @State private var comprando = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "El alumno nunca paga", titulo: "Elegí tu plan")
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    SelectorPeriodo(periodo: $periodo)
                    ForEach(PlanOM.allCases, id: \.self) { p in
                        TarjetaPlan(plan: p, periodo: periodo, elegido: plan == p) {
                            Haptico.seleccion()
                            withAnimation(.snappy(duration: 0.2)) { plan = p }
                        }
                    }
                    TicketPlan(plan: plan, periodo: periodo)
                        .padding(.top, 8)
                }
                .padding(.top, 20)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            BotonComprar(plan: plan, periodo: periodo) {
                if plan == .gratis {
                    estado.comprar(.gratis, periodo); dismiss()
                } else {
                    comprando = true
                }
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
        .onAppear { plan = inicial ?? (estado.suscripcion.planElegido ?? estado.planQueAlcanza) }
        .sheet(isPresented: $comprando) {
            CompraAppStore(plan: plan, periodo: periodo) { dismiss() }
        }
    }
}

private struct SelectorPeriodo: View {
    @Binding var periodo: PeriodoPlan
    var body: some View {
        HStack(spacing: 4) {
            ForEach(PeriodoPlan.allCases, id: \.self) { p in
                Button { Haptico.seleccion(); withAnimation(.snappy(duration: 0.2)) { periodo = p } } label: {
                    HStack(spacing: 6) {
                        Text(p.titulo).tipo(.texto(15, 700))
                        if p == .anual {
                            Text("2 meses gratis").tipo(.texto(11, 700))
                                .padding(.horizontal, 6).frame(height: 20)
                                .background(periodo == .anual ? Color.berenjena800 : Color.yema, in: Capsule())
                                .foregroundStyle(periodo == .anual ? Color.yema : Color.berenjena800)
                        }
                    }
                    .foregroundStyle(periodo == p ? Color.hueso : Color.berenjena800)
                    .frame(maxWidth: .infinity).frame(height: 44)
                    .background(periodo == p ? Color.berenjena800 : Color.clear, in: Capsule())
                }
                .buttonStyle(Apretable())
                .accessibilityAddTraits(periodo == p ? .isSelected : [])
            }
        }
        .padding(4)
        .background(Color.berenjena100, in: Capsule())
    }
}

private struct TarjetaPlan: View {
    @Environment(Estado.self) private var estado
    let plan: PlanOM
    let periodo: PeriodoPlan
    let elegido: Bool
    var tocar: () -> Void

    var body: some View {
        Button(action: tocar) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(plan.nombre.uppercased()).tipo(.titulo(24), alto: 26).foregroundStyle(Color.berenjena800)
                        Text(plan.bajada).tipo(.texto(13, 400)).foregroundStyle(Color.texto2)
                    }
                    Spacer()
                    PrecioPlan(plan: plan, periodo: periodo)
                }
                Text(plan.incluye.joined(separator: " · ")).tipo(.texto(13, 600)).foregroundStyle(Color.arena700)
                    .fixedSize(horizontal: false, vertical: true)
                EtiquetaAlcance(plan: plan)
            }
            .padding(16)
            .background(elegido ? Color.yema100 : Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                .strokeBorder(elegido ? Color.berenjena800 : Color.arena200, lineWidth: elegido ? 2.5 : 1))
            .overlay(alignment: .topTrailing) {
                if plan == estado.planQueAlcanza && plan != .gratis {
                    Text("Para vos").tipo(.texto(11, 700)).foregroundStyle(Color.berenjena800)
                        .padding(.horizontal, 8).frame(height: 22).background(Color.yema, in: Capsule())
                        .offset(x: -14, y: -11)
                }
            }
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}

private struct PrecioPlan: View {
    let plan: PlanOM
    let periodo: PeriodoPlan
    var body: some View {
        VStack(alignment: .trailing, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(Formato.plata(plan.precio(periodo))).tipo(.numero(26), alto: 26).foregroundStyle(Color.berenjena800)
                Text(periodo.unidad).tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
            }
            if periodo == .anual && plan.precioMes > 0 {
                Text("ahorrás \(Formato.plata(plan.precioMes * 2))").tipo(.texto(12, 700)).foregroundStyle(Color.ok)
            }
        }
    }
}

/// «Te alcanza» o cuántos quedarían en pausa con ese plan.
private struct EtiquetaAlcance: View {
    @Environment(Estado.self) private var estado
    let plan: PlanOM
    var body: some View {
        let sobran = estado.activos - plan.tope
        HStack(spacing: 6) {
            IconoVista(sobran > 0 ? .reloj : .tilde, tamano: 14, grosor: 2.4)
            Text(sobran > 0 ? "Tenés \(estado.activos): \(sobran) quedarían en pausa" : "Te alcanza para tus \(estado.activos) alumnos")
                .tipo(.texto(13, 700))
        }
        .foregroundStyle(sobran > 0 ? Color.error : Color.ok)
    }
}

/// El ticket: qué comprás, hoy pagás, primer cobro y después.
private struct TicketPlan: View {
    @Environment(Estado.self) private var estado
    let plan: PlanOM
    let periodo: PeriodoPlan

    var body: some View {
        let monto = plan.precio(periodo)
        let hoyPaga = (estado.enPrueba || plan == .gratis) ? 0 : monto
        VStack(alignment: .leading, spacing: 10) {
            Etiqueta("Tu resumen")
            renglon("Plan", "\(plan.nombre) · \(periodo.titulo.lowercased())")
            if plan != .gratis {
                renglon("Primer cobro", estado.enPrueba ? "\(Fecha.largo(estado.primerCobro)), cuando termina la prueba" : "Hoy")
                renglon("Después", "\(Formato.plata(monto)) \(periodo == .mensual ? "cada mes" : "cada año")")
                renglon("Precio fijo", "Hasta \(Fecha.mes(estado.suscripcion.precioFijoHasta)) de \(String(estado.suscripcion.precioFijoHasta.prefix(4)))")
                renglon("Medio de pago", "App Store")
            } else {
                renglon("Alumnos", "Hasta 10 activos; el resto queda en pausa")
            }
            Rectangle().fill(Color.arena200).frame(height: 1).padding(.vertical, 4)
            HStack(alignment: .firstTextBaseline) {
                Text("HOY PAGÁS").tipo(.titulo(22), alto: 24).foregroundStyle(Color.berenjena800)
                Spacer()
                Text(Formato.plata(hoyPaga)).tipo(.numero(40), alto: 40).foregroundStyle(Color.berenjena800)
                    .contentTransition(.numericText())
            }
        }
        .padding(16)
        .background(Color.arena50, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
            .strokeBorder(Color.arena300, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4])))
    }

    private func renglon(_ e: String, _ v: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(e).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
            Spacer(minLength: 8)
            Text(v).tipo(.texto(14, 700)).foregroundStyle(Color.tinta).multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct BotonComprar: View {
    @Environment(Estado.self) private var estado
    let plan: PlanOM
    let periodo: PeriodoPlan
    var accion: () -> Void
    var body: some View {
        let hoy = (estado.enPrueba || plan == .gratis) ? 0 : plan.precio(periodo)
        let titulo = plan == .gratis ? "Quedarme en Gratis" : "Suscribirme · \(Formato.plata(hoy)) hoy"
        VStack(spacing: 6) {
            ResumenFijo(plan: plan, periodo: periodo, hoy: hoy)
            Boton(titulo: titulo, variante: .prim, alto: .alto, ancho: true, accion: accion)
            Text("Se renueva solo. Cancelás cuando quieras.").tipo(.texto(12, 400)).foregroundStyle(Color.arena500)
        }
    }
}

/// Lo esencial del ticket, siempre a la vista sobre el botón.
private struct ResumenFijo: View {
    @Environment(Estado.self) private var estado
    let plan: PlanOM
    let periodo: PeriodoPlan
    let hoy: Int
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Hoy pagás").tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                Text(Formato.plata(hoy)).tipo(.numero(28), alto: 28).foregroundStyle(Color.berenjena800)
                    .contentTransition(.numericText())
            }
            Spacer()
            Text(despues).tipo(.texto(13, 600)).foregroundStyle(Color.arena700).multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 8)
    }
    private var despues: String {
        if plan == .gratis { return "Sin cobros" }
        let desde = estado.enPrueba ? "desde el \(Fecha.corta(estado.primerCobro))" : "desde hoy"
        return "Después \(Formato.plata(plan.precio(periodo)))\(periodo.unidad)\n\(desde)"
    }
}

// MARK: - Compra (estilo App Store)

/// Hoja de compra simulada, como la del sistema (StoreKit).
struct CompraAppStore: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let plan: PlanOM
    let periodo: PeriodoPlan
    var listo: () -> Void
    @State private var paso = 0

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("App Store").font(.system(size: 17, weight: .semibold))
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.system(size: 13, weight: .bold)).foregroundStyle(.secondary)
                        .frame(width: 30, height: 30).background(Color(.tertiarySystemFill), in: Circle())
                }
                .frame(width: 44, height: 44)
                .accessibilityLabel("Cerrar")
            }
            .padding(.top, 8)
            DetalleCompra(plan: plan, periodo: periodo)
            Spacer(minLength: 16)
            if paso == 2 {
                Image(systemName: "checkmark.circle.fill").font(.system(size: 56)).foregroundStyle(.blue)
                    .transition(.scale.combined(with: .opacity))
                Text("Listo").font(.system(size: 17, weight: .semibold)).padding(.top, 8)
            } else {
                Button { pagar() } label: {
                    Group {
                        if paso == 1 { ProgressView().tint(.white) } else { Text("Suscribirse").font(.system(size: 17, weight: .semibold)) }
                    }
                    .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 50)
                    .background(Color.blue, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(paso != 0)
            }
            Text("Simulado: en la maqueta no se cobra nada.").font(.system(size: 12)).foregroundStyle(.secondary).padding(.top, 10)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 8)
        .presentationDetents([.height(440)])
        .presentationBackground(Color(.systemBackground))
    }

    private func pagar() {
        withAnimation { paso = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.spring(duration: 0.4)) { paso = 2 }
            estado.comprar(plan, periodo)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { dismiss(); listo() }
        }
    }
}

private struct DetalleCompra: View {
    @Environment(Estado.self) private var estado
    let plan: PlanOM
    let periodo: PeriodoPlan
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image("mas-uno").resizable().scaledToFit().padding(8)
                    .frame(width: 60, height: 60).background(Color.berenjena800, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Otra Más \(plan.nombre)").font(.system(size: 17, weight: .semibold))
                    Text("Suscripción \(periodo == .mensual ? "mensual" : "anual")").font(.system(size: 14)).foregroundStyle(.secondary)
                    Text(estado.enPrueba ? "Prueba gratis hasta el \(Fecha.corta(estado.primerCobro))" : "Empieza hoy").font(.system(size: 14)).foregroundStyle(.secondary)
                }
            }
            Divider()
            fila("Precio", "\(Formato.plata(plan.precio(periodo)))\(periodo.unidad)")
            fila("Primer cobro", estado.enPrueba ? Fecha.corta(estado.primerCobro) : "Hoy")
            fila("Cuenta", estado.suscripcion.cuenta)
            Divider()
        }
        .padding(.top, 12)
    }
    private func fila(_ e: String, _ v: String) -> some View {
        HStack { Text(e).foregroundStyle(.secondary); Spacer(); Text(v).fontWeight(.medium) }.font(.system(size: 15))
    }
}

// MARK: - Tope

/// «Llegaste a 10 alumnos»: cuando en Gratis se quiere sumar uno más.
struct HojaTope: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    var nombre: String
    @State private var elegir: PlanOM?

    var body: some View {
        let quien = nombre.split(separator: " ").first.map(String.init) ?? "a tu alumno nuevo"
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Plan \(estado.planActual.nombre)", titulo: "Llegaste a \(estado.tope) alumnos")
            Text("Pasá a \(siguiente.nombre) para sumar a \(quien). Tus alumnos no pagan nada extra.")
                .tipo(.texto(16, 400)).foregroundStyle(Color.texto2).padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
            VStack(spacing: 12) {
                ForEach([PlanOM.personal, .pro].filter { $0.tope > estado.tope }, id: \.self) { p in
                    MiniPlan(plan: p) { elegir = p }
                }
            }
            .padding(.top, 20)
            Spacer()
            Button { dismiss() } label: {
                Text("Ahora no").tipo(.texto(15, 700)).foregroundStyle(Color.berenjena800).frame(maxWidth: .infinity).frame(height: 48)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja([.medium, .large])
        .sheet(item: $elegir) { p in ElegirPlan(inicial: p) }
    }

    private var siguiente: PlanOM { PlanOM.allCases.first { $0.tope > estado.tope } ?? .pro }
}

extension PlanOM: Identifiable { var id: String { rawValue } }

private struct MiniPlan: View {
    let plan: PlanOM
    var tocar: () -> Void
    var body: some View {
        Button(action: tocar) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(plan.nombre.uppercased()).tipo(.titulo(22), alto: 24).foregroundStyle(Color.berenjena800)
                    Text("Hasta \(plan.tope) alumnos").tipo(.texto(14, 600)).foregroundStyle(Color.texto2)
                }
                Spacer()
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(Formato.plata(plan.precioMes)).tipo(.numero(22), alto: 22).foregroundStyle(Color.berenjena800)
                    Text("/mes").tipo(.texto(13, 600)).foregroundStyle(Color.texto2)
                }
                IconoVista(.der, tamano: 16).foregroundStyle(Color.arena300)
            }
            .padding(16)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .sombraTarjeta()
        }
        .buttonStyle(Apretable())
    }
}

// MARK: - Factura

enum FacturaPDF {
    @MainActor
    static func generar(_ f: FacturaOM, titular: String) -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("Factura \(f.numero).pdf")
        let vista = VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image("mas-uno").resizable().scaledToFit().frame(width: 34)
                Text("OTRA MÁS").font(Estilo.titulo(22).font()).foregroundStyle(Color.berenjena800)
                Spacer()
                Text("FACTURA \(f.numero)").font(Estilo.etiqueta.font()).foregroundStyle(Color.arena600)
            }
            Rectangle().fill(Color.arena100).frame(height: 1)
            Text("Para: \(titular)").font(Estilo.texto(13, 700).font())
            Text("Fecha: \(Fecha.largo(f.fecha))").font(Estilo.texto(13, 400).font())
            Text(f.concepto).font(Estilo.texto(15, 600).font()).padding(.top, 12)
            Text(Formato.plata(f.monto)).font(Estilo.numero(40).font()).foregroundStyle(Color.berenjena800)
            Text("IVA incluido · cobrado por App Store").font(Estilo.texto(11, 400).font()).foregroundStyle(Color.arena600)
            Spacer()
        }
        .padding(40).frame(width: 595, height: 842).background(Color.white)
        var caja = CGRect(x: 0, y: 0, width: 595, height: 842)
        if let ctx = CGContext(url as CFURL, mediaBox: &caja, nil) {
            ImageRenderer(content: vista).render { _, dibujar in ctx.beginPDFPage(nil); dibujar(ctx); ctx.endPDFPage() }
            ctx.closePDF()
        }
        return url
    }
}
