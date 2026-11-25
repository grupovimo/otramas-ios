import SwiftUI

/// 11 · Menú del +1: «Sumá uno más» con las cuatro acciones rápidas.
struct MenuMasUno: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Titulo("Sumá uno más", tamano: 28)
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    accion(.plata, "Cobrar", "Efectivo o transferencia") { nav.hoja = .cobrar(nil) }
                    accion(.tilde, "Pasar lista", "La clase de las \(estado.proxima?.hora ?? "8:00")") { nav.hoja = .lista(estado.profe.proxima) }
                }
                GridRow {
                    accion(.gente, "Alumno nuevo", "Con su link listo") { nav.hoja = .nuevo }
                    accion(.pesa, "Rutina nueva", "De cero o desde una foto") { nav.edicion = .nueva }
                }
            }
            HStack(spacing: 8) {
                chica(.wa, "Aviso") { nav.pestana = .inicio; nav.inicio = [.avisos] }
                chica(.cal, "Clase") { nav.pestana = .inicio; nav.inicio = [.clases] }
                chica(.recibo, "Precios") { nav.pestana = .inicio; nav.inicio = [.planes] }
            }
        }
        .padding(20)
        .background(Color.hueso, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .sombraMenu()
    }

    private func chica(_ i: Icono, _ t: String, _ hacer: @escaping () -> Void) -> some View {
        Button {
            Haptico.seleccion()
            withAnimation(.spring(duration: 0.3)) { nav.menuAbierto = false }
            hacer()
        } label: {
            HStack(spacing: 6) { IconoVista(i, tamano: 18); Text(t).tipo(.texto(15, 700)) }
                .foregroundStyle(Color.berenjena800).frame(maxWidth: .infinity).frame(height: 44)
                .background(Color.berenjena100, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
        }
        .buttonStyle(Apretable())
    }

    private func accion(_ i: Icono, _ t: String, _ s: String, _ hacer: @escaping () -> Void) -> some View {
        Button {
            Haptico.seleccion()
            withAnimation(.spring(duration: 0.3)) { nav.menuAbierto = false }
            hacer()
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                IconoVista(i, tamano: 22, grosor: 1.8)
                    .foregroundStyle(Color.berenjena800)
                    .frame(width: 44, height: 44)
                    .background(Color.yema, in: Circle())
                    .padding(.bottom, 8)
                Text(t).tipo(.texto(17, 700)).foregroundStyle(Color.berenjena800)
                Text(s).tipo(.texto(13, 400)).foregroundStyle(Color.arena600)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(1)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 146, alignment: .topLeading)
            .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .shadow(color: Color.berenjena800.opacity(0.05), radius: 1, y: 1)
            .shadow(color: Color.berenjena800.opacity(0.08), radius: 12, y: 10)
            .contentShape(RoundedRectangle(cornerRadius: Radio.tarjeta))
        }
        .buttonStyle(Apretable())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Hojas de las acciones

/// Encabezado común de las hojas: agarradera, etiqueta y título.
struct CabezaHoja: View {
    var etiqueta: String?
    let titulo: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Capsule().fill(Color.arena300).frame(width: 36, height: 5).frame(maxWidth: .infinity).padding(.bottom, 16)
            if let etiqueta { Etiqueta(etiqueta).padding(.bottom, 8) }
            Titulo(titulo, tamano: 28)
        }
        .padding(.top, 8)
    }
}

extension View {
    func estiloHoja(_ detents: Set<PresentationDetent> = [.large]) -> some View {
        self
            .presentationDetents(detents)
            .presentationCornerRadius(Radio.tarjeta)
            .presentationBackground(Color.hueso)
            .presentationDragIndicator(.hidden)
    }
}

/// Cobrar: a quién, cuánto y cómo. Marca la cuota como pagada.
struct HojaCobrar: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    var alumnoId: String?
    @State private var elegido: String?
    @State private var medio: MedioPago = .efectivo

    var body: some View {
        let candidatos: [(Alumno, Int)] = estado.deben.map { ($0.alumno, $0.deuda.monto) }
            + estado.porConfirmar.map { ($0.alumno, $0.comprobante.monto) }
        let fijo = alumnoId.flatMap { estado.alumno($0) }
        let lista: [(Alumno, Int)] = fijo.map { f in [(f, candidatos.first { $0.0.id == f.id }?.1 ?? 45000)] } ?? candidatos
        let sel = elegido ?? alumnoId ?? lista.first?.0.id
        let monto = lista.first { $0.0.id == sel }?.1 ?? 0
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Noviembre", titulo: "Cobrar")
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if lista.isEmpty {
                        Text("Nadie te debe este mes.").tipo(.texto(16, 600)).foregroundStyle(Color.texto2).padding(.top, 24)
                    } else {
                        Tarjeta {
                            ForEach(Array(lista.enumerated()), id: \.element.0.id) { i, par in
                                if i > 0 { Divisor() }
                                Button {
                                    Haptico.seleccion(); elegido = par.0.id
                                } label: {
                                    HStack(spacing: 12) {
                                        Iniciales(texto: par.0.iniciales, tono: par.0.tono, tamano: 40)
                                        NomSub(nombre: par.0.nombre, sub: Text(Formato.plata(par.1)))
                                        Circle()
                                            .strokeBorder(sel == par.0.id ? Color.berenjena800 : Color.arena300, lineWidth: 2)
                                            .background(Circle().fill(sel == par.0.id ? Color.berenjena800 : .clear).padding(6))
                                            .frame(width: 24, height: 24)
                                    }
                                    .padding(.horizontal, 16).padding(.vertical, 12).frame(minHeight: 64)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                .accessibilityAddTraits(sel == par.0.id ? .isSelected : [])
                            }
                        }
                        .padding(.top, 24)
                        Etiqueta("Cómo te pagó").padding(.top, 24).padding(.bottom, 8)
                        HStack(spacing: 8) {
                            ForEach([MedioPago.efectivo, .transferencia], id: \.self) { m in
                                Chip(titulo: m.rawValue, elegido: medio == m, elegidoOscuro: true, ancho: true) {
                                    Haptico.seleccion(); medio = m
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            if let sel, monto > 0 {
                Boton(titulo: "Registrar \(Formato.plata(monto))", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                    estado.registrarCobro(alumnoId: sel, monto: monto, medio: medio)
                    dismiss()
                }
                .padding(.bottom, 8)
            }
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja(alumnoId == nil ? [.large] : [.medium])
    }
}

/// Pasar lista de una clase: los inscriptos, tildables.
struct HojaPasarLista: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    let claseId: String
    @State private var presentes: Set<String>?

    var body: some View {
        let c = estado.clase(claseId)
        let marcados = presentes ?? c?.presentes ?? []
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: c.map { "\($0.nombre) · \($0.lugar)" }, titulo: "Pasar lista · \(c?.hora ?? "")")
            ScrollView {
                Tarjeta {
                    ForEach(Array((c?.inscriptos ?? []).enumerated()), id: \.element) { i, id in
                        if let a = estado.alumno(id) {
                            if i > 0 { Divisor() }
                            let vino = marcados.contains(id)
                            Button {
                                Haptico.seleccion()
                                var s = marcados
                                if vino { s.remove(id) } else { s.insert(id) }
                                withAnimation(.snappy(duration: 0.2)) { presentes = s }
                            } label: {
                                HStack(spacing: 12) {
                                    Iniciales(texto: a.iniciales, tono: a.tono, tamano: 40)
                                    NomSub(nombre: a.nombre, sub: Text(vino ? "Vino" : "No vino"))
                                    IconoVista(.tilde, tamano: 20, grosor: 2.6)
                                        .foregroundStyle(vino ? Color.yema : Color.clear)
                                        .frame(width: 32, height: 32)
                                        .background(vino ? Color.berenjena800 : Color.clear, in: Circle())
                                        .overlay(Circle().strokeBorder(vino ? Color.clear : Color.arena300, lineWidth: 2))
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12).frame(minHeight: 64)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(a.nombre)
                            .accessibilityValue(vino ? "Vino" : "No vino")
                        }
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 16)
            }
            .scrollIndicators(.hidden)
            Boton(titulo: "Guardar · vinieron \(marcados.count) de \(c?.inscriptos.count ?? 0)", icono: .tilde,
                  variante: .prim, alto: .alto, ancho: true) {
                estado.guardarAsistencia(claseId: claseId, presentes: marcados)
                dismiss()
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja()
    }
}

/// Alumno nuevo: nombre y plan; se crea y queda su link copiado.
struct HojaAlumnoNuevo: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dismiss) private var dismiss
    @State private var nombre = ""
    @State private var plan = "Mensual"
    @FocusState private var foco: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            CabezaHoja(etiqueta: "Con su link listo", titulo: "Alumno nuevo")
            Etiqueta("Nombre y apellido").padding(.top, 24).padding(.bottom, 8)
            TextField("", text: $nombre, prompt: Text("Ej.: Sofía Méndez").foregroundColor(.arena500))
                .font(Estilo.texto(17, 600).font())
                .foregroundStyle(Color.tinta)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($foco)
                .padding(.horizontal, 16)
                .frame(height: 56)
                .background(Color.white, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous)
                    .strokeBorder(foco ? Color.berenjena800 : Color.arena300, lineWidth: foco ? 2 : 1))
            Etiqueta("Plan").padding(.top, 24).padding(.bottom, 8)
            HStack(spacing: 8) {
                ForEach(["Mensual", "Pack de 8", "Particular"], id: \.self) { p in
                    Chip(titulo: p, elegido: plan == p, elegidoOscuro: true, ancho: true) { Haptico.seleccion(); plan = p }
                }
            }
            Spacer(minLength: 24)
            Boton(titulo: "Crear y copiar su link", icono: .tilde, variante: .prim, alto: .alto, ancho: true) {
                estado.crearAlumno(nombre: nombre, plan: plan)
                dismiss()
            }
            .disabled(nombre.trimmingCharacters(in: .whitespaces).count < 2)
            .opacity(nombre.trimmingCharacters(in: .whitespaces).count < 2 ? 0.45 : 1)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, Espacio.margen)
        .estiloHoja([.medium, .large])
    }
}
