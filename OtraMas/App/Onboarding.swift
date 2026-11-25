import SwiftUI

/// Los pasos del onboarding. El primero elige el lado; después cada lado tiene los suyos.
enum PasoOnboarding: String, CaseIterable {
    case lado, nombre, sexo, edad, peso, altura, objetivo, experiencia, dias, lesiones, salud
    case lugares, alumnos, cobros, horarios
    case listo

    static func pasos(_ lado: Lado) -> [PasoOnboarding] {
        lado == .alumno
            ? [.lado, .nombre, .sexo, .edad, .peso, .altura, .objetivo, .experiencia, .dias, .lesiones, .salud, .listo]
            : [.lado, .nombre, .lugares, .alumnos, .cobros, .horarios, .listo]
    }
}

/// Onboarding: una pregunta grande por pantalla, la barra de la serie arriba, Siguiente abajo.
struct Onboarding: View {
    var terminar: (Perfil) -> Void
    @State private var perfil: Perfil
    @State private var indice: Int
    @State private var adelante = true
    @State private var respondidos: Set<PasoOnboarding> = []
    @FocusState private var focoNombre: Bool

    init(lado: Lado = .profe, paso: Int = 0, perfil: Perfil? = nil, terminar: @escaping (Perfil) -> Void) {
        self.terminar = terminar
        let p = perfil ?? Perfil(lado: lado)
        _perfil = State(initialValue: p)
        _indice = State(initialValue: min(paso, PasoOnboarding.pasos(lado).count - 1))
        // Si arranca en un paso intermedio (capturas), lo anterior cuenta como respondido.
        _respondidos = State(initialValue: Set(PasoOnboarding.pasos(lado).prefix(paso)).union(perfil == nil ? [] : Set(PasoOnboarding.allCases)))
    }

    private var pasos: [PasoOnboarding] { PasoOnboarding.pasos(perfil.lado) }
    private var paso: PasoOnboarding { pasos[indice] }

    var body: some View {
        ZStack {
            Color.berenjena800.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                barra
                ScrollView {
                    contenido
                        .id(paso)
                        .transition(.asymmetric(
                            insertion: .move(edge: adelante ? .trailing : .leading).combined(with: .opacity),
                            removal: .move(edge: adelante ? .leading : .trailing).combined(with: .opacity)))
                        .padding(.horizontal, Espacio.margen)
                        .padding(.top, 24)
                        .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                Boton(titulo: paso == .listo ? "Empezar" : paso == .salud && !perfil.saludConectada ? "Ahora no" : "Siguiente",
                      iconoDerecha: .der, variante: .yema, alto: .alto, ancho: true) { siguiente() }
                    .disabled(!puedeSeguir)
                    .opacity(puedeSeguir ? 1 : 0.4)
                    .padding(.horizontal, Espacio.margen)
                    .padding(.bottom, 12)
                    .padding(.top, 8)
            }
        }
        .animation(.spring(duration: 0.42, bounce: 0.12), value: indice)
    }

    // MARK: - Barra: Atrás y la serie de pasos

    private var barra: some View {
        HStack(spacing: 16) {
            Button { atras() } label: {
                IconoVista(.atras, tamano: 24)
                    .foregroundStyle(Color.hueso)
                    .frame(width: 44, height: 44)
                    .background(Color.huesoOsc, in: Circle())
            }
            .buttonStyle(Apretable())
            .opacity(indice == 0 ? 0 : 1)
            .disabled(indice == 0)
            .accessibilityLabel("Atrás")
            HStack(spacing: 4) {
                ForEach(0..<pasos.count, id: \.self) { i in
                    Capsule()
                        .fill(i < indice ? Color.hueso : i == indice ? Color.yema : Color.hueso.opacity(0.18))
                        .frame(height: 4)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Paso \(indice + 1) de \(pasos.count)")
            Text("\(indice + 1)/\(pasos.count)")
                .tipo(.numero(20), alto: 20)
                .foregroundStyle(Color.berenjena300)
                .frame(minWidth: 44, alignment: .trailing)
                .contentTransition(.numericText(value: Double(indice)))
                .accessibilityHidden(true)
        }
        .padding(.horizontal, Espacio.margen)
        .frame(height: 56)
    }

    // MARK: - Contenido de cada paso

    @ViewBuilder
    private var contenido: some View {
        switch paso {
        case .lado:
            Pregunta(titulo: "¿Sos profe o alumno?", bajada: "Una app, dos lados. Lo podés cambiar después.") {
                VStack(spacing: 12) {
                    Opcion(titulo: "Soy profe", bajada: "Cobrás, pasás lista y armás rutinas", icono: .gente,
                           elegido: respondidos.contains(.lado) && perfil.lado == .profe) { elegirLado(.profe) }
                    Opcion(titulo: "Soy alumno", bajada: "Tu rutina de hoy, tus logros y tu plan", icono: .pesa,
                           elegido: respondidos.contains(.lado) && perfil.lado == .alumno) { elegirLado(.alumno) }
                }
            }
        case .nombre:
            Pregunta(titulo: perfil.lado == .profe ? "¿Cómo te llaman tus alumnos?" : "¿Cómo te llamás?",
                     bajada: perfil.lado == .profe ? "Así te ven en su link." : "Así te saluda tu profe.") {
                TextField("", text: $perfil.nombre, prompt: Text(perfil.lado == .profe ? "Lucía" : "Nico").foregroundColor(.berenjena500))
                    .font(Estilo.texto(28, 700).font())
                    .foregroundStyle(Color.hueso)
                    .tint(Color.yema)
                    .textContentType(.givenName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .submitLabel(.next)
                    .focused($focoNombre)
                    .onSubmit { if puedeSeguir { siguiente() } }
                    .padding(.horizontal, 20)
                    .frame(height: 72)
                    .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: Radio.control, style: .continuous)
                        .strokeBorder(focoNombre ? Color.yema : Color.clear, lineWidth: 2))
                    .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { focoNombre = true } }
            }
        case .sexo:
            Pregunta(titulo: "¿Con qué te identificás?", bajada: "Para mostrarte los ejercicios con alguien como vos.") {
                VStack(spacing: 12) {
                    ForEach(Sexo.allCases, id: \.self) { s in
                        Opcion(titulo: s.titulo, elegido: respondidos.contains(.sexo) && perfil.sexo == s) {
                            elegir(.sexo) { perfil.sexo = s }
                        }
                    }
                }
            }
        case .edad:
            Pregunta(titulo: "¿Cuántos años tenés?", bajada: "Deslizá la regla.") {
                Regla(valor: enlace(\.edad), rango: 14...90, unidad: "años", cadaLarga: 10)
                    .padding(.horizontal, -Espacio.margen)
                    .padding(.top, 24)
            }
        case .peso:
            Pregunta(titulo: "¿Cuánto pesás?", bajada: "Sólo lo ve tu profe. Sirve para medir tu avance.") {
                Regla(valor: $perfil.peso, rango: 35...180, paso: 0.5, unidad: "kg", cadaLarga: 10)
                    .padding(.horizontal, -Espacio.margen)
                    .padding(.top, 24)
            }
        case .altura:
            Pregunta(titulo: "¿Cuánto medís?", bajada: "En centímetros.") {
                Regla(valor: enlace(\.altura), rango: 120...220, unidad: "cm", cadaLarga: 10)
                    .padding(.horizontal, -Espacio.margen)
                    .padding(.top, 24)
            }
        case .objetivo:
            Pregunta(titulo: "¿Qué querés lograr?", bajada: "Elegí lo más importante para vos.") {
                VStack(spacing: 12) {
                    ForEach(Objetivo.allCases, id: \.self) { o in
                        Opcion(titulo: o.titulo, bajada: o.bajada, elegido: perfil.objetivo == o) {
                            elegir(.objetivo) { perfil.objetivo = o }
                        }
                    }
                }
            }
        case .experiencia:
            Pregunta(titulo: "¿Cuánto entrenaste?", bajada: "Así tu profe arranca en el punto justo.") {
                VStack(spacing: 12) {
                    ForEach(Experiencia.allCases, id: \.self) { e in
                        Opcion(titulo: e.titulo, bajada: e.bajada, elegido: perfil.experiencia == e) {
                            elegir(.experiencia) { perfil.experiencia = e }
                        }
                    }
                }
            }
        case .dias:
            Pregunta(titulo: "¿Cuántos días por semana?", bajada: "Los que de verdad podés sostener.") {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 8) {
                        ForEach(1...7, id: \.self) { n in
                            let on = perfil.diasPorSemana == n
                            Button { elegir(.dias) { perfil.diasPorSemana = n } } label: {
                                Text("\(n)")
                                    .tipo(.numero(28), alto: 28)
                                    .foregroundStyle(on ? Color.berenjena800 : Color.hueso)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 64)
                                    .background(on ? Color.yema : Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                            }
                            .buttonStyle(Apretable())
                            .accessibilityLabel("\(n) \(n == 1 ? "día" : "días")")
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    Text(textoDias(perfil.diasPorSemana))
                        .tipo(.texto(16, 400)).foregroundStyle(Color.berenjena300)
                        .contentTransition(.opacity)
                }
            }
        case .lesiones:
            Pregunta(titulo: "¿Te duele algo?", bajada: "Lesiones o molestias. Tu profe las va a tener en cuenta.") {
                Chips(opciones: ["Ninguna"] + lesionesComunes,
                      elegidas: Set(perfil.lesiones.isEmpty && respondidos.contains(.lesiones) ? ["Ninguna"] : perfil.lesiones)) { o in
                    elegir(.lesiones) {
                        if o == "Ninguna" { perfil.lesiones = [] }
                        else if let i = perfil.lesiones.firstIndex(of: o) { perfil.lesiones.remove(at: i) }
                        else { perfil.lesiones.append(o) }
                    }
                }
            }
        case .salud:
            Pregunta(titulo: "Sumá tus pasos", bajada: "Conectá Apple Salud y vas a ver tus pasos de cada día en Logros. Tu profe ve el promedio, nada más.") {
                VStack(spacing: 20) {
                    ZStack {
                        Circle().fill(Color.huesoOsc).frame(width: 160, height: 160)
                        Circle().fill(Color.hueso).frame(width: 112, height: 112)
                        IconoVista(.corazon, tamano: 56).foregroundStyle(Color.salud)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                    VStack(alignment: .leading, spacing: 12) {
                        linea(.tilde, "Sólo leemos pasos. Nada de tu salud se comparte.")
                        linea(.tilde, "Lo podés apagar cuando quieras.")
                        linea(.tilde, "Te lo pide el iPhone la primera vez que entrenes.")
                    }
                    if perfil.saludConectada {
                        HStack(spacing: 8) {
                            IconoVista(.tilde, tamano: 20)
                            Text("Listo, la conectamos al entrenar").tipo(.texto(16, 700))
                        }
                        .foregroundStyle(Color.okClaro)
                        .frame(maxWidth: .infinity).frame(height: 56)
                        .background(Color.okClaro.opacity(0.12), in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        Boton(titulo: "Conectar Apple Salud", icono: .corazon, variante: .osc, alto: .alto, ancho: true,
                              colorIcono: .salud) {
                            elegir(.salud) { perfil.saludConectada = true }
                        }
                    }
                }
            }
        case .lugares:
            Pregunta(titulo: "¿Dónde das clases?", bajada: "Elegí todos los que correspondan.") {
                VStack(spacing: 12) {
                    ForEach(LugarClase.allCases, id: \.self) { l in
                        Opcion(titulo: l.titulo, icono: icono(l), elegido: perfil.lugares.contains(l), multiple: true) {
                            elegir(.lugares) { alternar(&perfil.lugares, l) }
                        }
                    }
                }
            }
        case .alumnos:
            Pregunta(titulo: "¿Cuántos alumnos tenés?", bajada: "Más o menos. Después los vas sumando.") {
                VStack(spacing: 24) {
                    HStack(spacing: 24) {
                        BotonOscuro(icono: .menos, etiqueta: "Menos alumnos") { cambiarAlumnos(-1) }
                        Text("\(perfil.cantidadAlumnos)")
                            .tipo(.numero(88), alto: 88)
                            .foregroundStyle(Color.yema)
                            .contentTransition(.numericText(value: Double(perfil.cantidadAlumnos)))
                            .frame(minWidth: 140)
                        BotonOscuro(icono: .mas, etiqueta: "Más alumnos") { cambiarAlumnos(1) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    HStack(spacing: 8) {
                        ForEach([5, 10, 20, 30, 50], id: \.self) { n in
                            Chip(titulo: "\(n)", elegido: perfil.cantidadAlumnos == n, sobreBanda: true, ancho: true) {
                                elegir(.alumnos) { perfil.cantidadAlumnos = n }
                            }
                        }
                    }
                }
            }
        case .cobros:
            Pregunta(titulo: "¿Cómo te pagan?", bajada: "Elegí todos los que uses.") {
                VStack(spacing: 12) {
                    ForEach(MedioPago.allCases, id: \.self) { m in
                        Opcion(titulo: m.rawValue, icono: m == .efectivo ? .plata : m == .transferencia ? .cambio : .recibo,
                               elegido: perfil.cobros.contains(m), multiple: true) {
                            elegir(.cobros) { alternar(&perfil.cobros, m) }
                        }
                    }
                }
            }
        case .horarios:
            Pregunta(titulo: "¿Cuándo das clases?", bajada: "Los días y las franjas. Lo afinás en Horario.") {
                VStack(alignment: .leading, spacing: 24) {
                    Etiqueta("Días", color: .berenjena300)
                    HStack(spacing: 6) {
                        ForEach(["Lun", "Mar", "Mié", "Jue", "Vie", "Sáb", "Dom"], id: \.self) { d in
                            let on = perfil.dias.contains(d)
                            Button { elegir(.horarios) { alternar(&perfil.dias, d) } } label: {
                                Text(d.uppercased()).tipo(.etiqueta)
                                    .foregroundStyle(on ? Color.berenjena800 : Color.hueso)
                                    .frame(maxWidth: .infinity).frame(height: 56)
                                    .background(on ? Color.yema : Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                            }
                            .buttonStyle(Apretable())
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    .padding(.top, -12)
                    Etiqueta("Franjas", color: .berenjena300)
                    VStack(spacing: 8) {
                        ForEach(FranjaHoraria.allCases, id: \.self) { f in
                            Opcion(titulo: f.titulo, bajada: "De \(f.horas) h", elegido: perfil.franjas.contains(f), multiple: true, compacta: true) {
                                elegir(.horarios) { alternar(&perfil.franjas, f) }
                            }
                        }
                    }
                    .padding(.top, -12)
                }
            }
        case .listo:
            Listo(perfil: perfil)
        }
    }

    // MARK: - Lógica

    private var puedeSeguir: Bool {
        switch paso {
        case .lado: return respondidos.contains(.lado)
        case .nombre: return perfil.nombre.trimmingCharacters(in: .whitespaces).count >= 2
        case .sexo: return respondidos.contains(.sexo)
        case .objetivo: return perfil.objetivo != nil
        case .experiencia: return perfil.experiencia != nil
        case .lugares: return !perfil.lugares.isEmpty
        case .cobros: return !perfil.cobros.isEmpty
        case .horarios: return !perfil.dias.isEmpty && !perfil.franjas.isEmpty
        default: return true
        }
    }

    private func siguiente() {
        guard puedeSeguir else { return }
        focoNombre = false
        if paso == .listo {
            Haptico.exito()
            perfil.nombre = perfil.nombre.trimmingCharacters(in: .whitespaces)
            terminar(perfil)
            return
        }
        Haptico.suave()
        adelante = true
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) { indice = min(indice + 1, pasos.count - 1) }
        if paso == .listo { Haptico.exito() }
    }

    private func atras() {
        guard indice > 0 else { return }
        focoNombre = false
        Haptico.seleccion()
        adelante = false
        withAnimation(.spring(duration: 0.42, bounce: 0.12)) { indice -= 1 }
    }

    private func elegirLado(_ l: Lado) {
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.2)) {
            if perfil.lado != l { let n = perfil.nombre; perfil = Perfil(lado: l); perfil.nombre = n }
            respondidos.insert(.lado)
        }
    }

    private func elegir(_ p: PasoOnboarding, _ cambio: () -> Void) {
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.2)) {
            cambio()
            respondidos.insert(p)
        }
    }

    private func alternar<T: Equatable>(_ lista: inout [T], _ v: T) {
        if let i = lista.firstIndex(of: v) { lista.remove(at: i) } else { lista.append(v) }
    }

    private func cambiarAlumnos(_ d: Int) {
        let n = max(1, min(300, perfil.cantidadAlumnos + d))
        elegir(.alumnos) { perfil.cantidadAlumnos = n }
    }

    private func enlace(_ k: WritableKeyPath<Perfil, Int>) -> Binding<Double> {
        Binding(get: { Double(perfil[keyPath: k]) }, set: { perfil[keyPath: k] = Int($0) })
    }

    private func textoDias(_ n: Int) -> String {
        switch n {
        case 1: return "Un día ya es empezar."
        case 2: return "Dos días: buen comienzo, se nota en un mes."
        case 3: return "Tres días: el punto justo para la mayoría."
        case 4, 5: return "\(n) días: vas en serio. Ojo con descansar."
        default: return "\(n) días: dejá al menos uno para descansar."
        }
    }

    private func icono(_ l: LugarClase) -> Icono {
        switch l { case .gimnasio: return .pesa; case .plaza: return .sol; case .domicilio: return .casa; case .online: return .camara }
    }

    private func linea(_ i: Icono, _ t: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            IconoVista(i, tamano: 20).foregroundStyle(Color.yema)
            Text(t).tipo(.texto(16, 400)).foregroundStyle(Color.hueso.opacity(0.85)).fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Piezas del onboarding

/// La pregunta grande (Archivo 62, mayúsculas) con su bajada y las respuestas.
struct Pregunta<Respuestas: View>: View {
    let titulo: String
    var bajada: String?
    @ViewBuilder var respuestas: () -> Respuestas

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titulo.uppercased(with: Locale(identifier: "es_AR")))
                .tipo(.titulo(40))
                .foregroundStyle(Color.hueso)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let bajada {
                Text(bajada).tipo(.texto(16, 400)).foregroundStyle(Color.berenjena300)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 12)
            }
            respuestas().padding(.top, 32)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Respuesta en tarjeta grande sobre berenjena. Elegida: yema con tilde.
struct Opcion: View {
    let titulo: String
    var bajada: String?
    var icono: Icono?
    var elegido: Bool
    var multiple = false
    var compacta = false
    var accion: () -> Void

    var body: some View {
        Button(action: accion) {
            HStack(spacing: 16) {
                if let icono {
                    IconoVista(icono, tamano: 24)
                        .foregroundStyle(elegido ? Color.yema : Color.berenjena800)
                        .frame(width: 48, height: 48)
                        .background(elegido ? Color.berenjena800 : Color.yema, in: Circle())
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(titulo).tipo(.texto(compacta ? 17 : 19, 700))
                    if let bajada {
                        Text(bajada).tipo(.texto(14, 400)).opacity(0.75)
                    }
                }
                .foregroundStyle(elegido ? Color.berenjena800 : Color.hueso)
                .frame(maxWidth: .infinity, alignment: .leading)
                ZStack {
                    if multiple {
                        RoundedRectangle(cornerRadius: 7).strokeBorder(elegido ? Color.berenjena800 : Color.hueso.opacity(0.35), lineWidth: 2)
                    } else {
                        Circle().strokeBorder(elegido ? Color.berenjena800 : Color.hueso.opacity(0.35), lineWidth: 2)
                    }
                    if elegido {
                        IconoVista(.tilde, tamano: 16, grosor: 3).foregroundStyle(Color.berenjena800)
                    }
                }
                .frame(width: 26, height: 26)
            }
            .padding(.horizontal, 20)
            .frame(minHeight: compacta ? 64 : 80)
            .background(elegido ? Color.yema : Color.hueso.opacity(0.08), in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                .strokeBorder(elegido ? Color.clear : Color.hueso.opacity(0.1), lineWidth: 1))
            .scaleEffect(elegido ? 1 : 0.99)
            .contentShape(RoundedRectangle(cornerRadius: Radio.tarjeta))
        }
        .buttonStyle(Apretable())
        .accessibilityAddTraits(elegido ? .isSelected : [])
    }
}

/// Chips grandes que fluyen en varias líneas.
struct Chips: View {
    let opciones: [String]
    let elegidas: Set<String>
    var tocar: (String) -> Void

    var body: some View {
        Fluir(espacio: 8) {
            ForEach(opciones, id: \.self) { o in
                let on = elegidas.contains(o)
                Button { tocar(o) } label: {
                    HStack(spacing: 8) {
                        if on { IconoVista(.tilde, tamano: 16, grosor: 3) }
                        Text(o).tipo(.texto(17, 700))
                    }
                    .foregroundStyle(on ? Color.berenjena800 : Color.hueso)
                    .padding(.horizontal, 20)
                    .frame(height: 52)
                    .background(on ? Color.yema : Color.hueso.opacity(0.08), in: Capsule())
                    .overlay(Capsule().strokeBorder(on ? Color.clear : Color.hueso.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(Apretable())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

/// Distribución que acomoda a los hijos en filas.
struct Fluir: Layout {
    var espacio: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let ancho = proposal.width ?? 360
        var x: CGFloat = 0, y: CGFloat = 0, alto: CGFloat = 0
        for s in subviews {
            let t = s.sizeThatFits(.unspecified)
            if x > 0 && x + t.width > ancho { x = 0; y += alto + espacio; alto = 0 }
            x += t.width + espacio
            alto = max(alto, t.height)
        }
        return CGSize(width: ancho, height: y + alto)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, alto: CGFloat = 0
        for s in subviews {
            let t = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + t.width > bounds.maxX { x = bounds.minX; y += alto + espacio; alto = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(t))
            x += t.width + espacio
            alto = max(alto, t.height)
        }
    }
}

/// −/+ grande sobre berenjena.
struct BotonOscuro: View {
    let icono: Icono
    var etiqueta: String
    var accion: () -> Void
    var body: some View {
        Button(action: accion) {
            IconoVista(icono, tamano: 24)
                .foregroundStyle(Color.hueso)
                .frame(width: 56, height: 56)
                .background(Color.huesoOsc, in: Circle())
        }
        .buttonStyle(Apretable())
        .accessibilityLabel(etiqueta)
    }
}

/// Cierre: el +1 que entra con rebote y el resumen de lo respondido.
struct Listo: View {
    let perfil: Perfil
    @State private var entro = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image("mas-uno")
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .rotationEffect(.degrees(entro ? -6 : -30))
                .scaleEffect(entro ? 1 : 0.4)
                .opacity(entro ? 1 : 0)
                .shadow(color: Color.yema.opacity(0.35), radius: 24, y: 10)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
                .accessibilityHidden(true)
            Text(("¡Listo, \(perfil.primerNombre.isEmpty ? "ya está" : perfil.primerNombre)!").uppercased(with: Locale(identifier: "es_AR")))
                .tipo(.titulo(56))
                .foregroundStyle(Color.hueso)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 24)
            Text(perfil.lado == .profe ? "Ya podés cobrar, pasar lista y armar rutinas." : "Tu profe ya sabe por dónde arrancar.")
                .tipo(.texto(17, 400)).foregroundStyle(Color.berenjena300)
                .padding(.top, 8)
            VStack(spacing: 0) {
                ForEach(Array(resumen.enumerated()), id: \.offset) { i, r in
                    if i > 0 { Rectangle().fill(Color.hueso.opacity(0.08)).frame(height: 1) }
                    HStack(alignment: .firstTextBaseline) {
                        Text(r.0).tipo(.texto(15, 400)).foregroundStyle(Color.berenjena300)
                        Spacer(minLength: 12)
                        Text(r.1).tipo(.texto(15, 700)).foregroundStyle(Color.hueso).multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 12)
                }
            }
            .padding(.horizontal, 16)
            .background(Color.hueso.opacity(0.06), in: RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
            .padding(.top, 24)
        }
        .onAppear {
            Haptico.exito()
            withAnimation(.spring(duration: 0.7, bounce: 0.45).delay(0.1)) { entro = true }
        }
    }

    private var resumen: [(String, String)] {
        if perfil.lado == .profe {
            return [
                ("Das clases en", perfil.lugares.map(\.titulo).joined(separator: ", ")),
                ("Alumnos", "\(perfil.cantidadAlumnos)"),
                ("Te pagan con", perfil.cobros.map(\.rawValue).joined(separator: ", ")),
                ("Días", perfil.dias.joined(separator: ", ")),
                ("Franjas", perfil.franjas.map(\.titulo).joined(separator: ", ")),
            ]
        }
        return [
            ("Edad", "\(perfil.edad) años"),
            ("Peso y altura", "\(Formato.decimal(perfil.peso)) kg · \(perfil.altura) cm"),
            ("Objetivo", perfil.objetivo?.titulo ?? "—"),
            ("Experiencia", perfil.experiencia?.titulo ?? "—"),
            ("Por semana", "\(perfil.diasPorSemana) \(perfil.diasPorSemana == 1 ? "día" : "días")"),
            ("Molestias", perfil.lesiones.isEmpty ? "Ninguna" : perfil.lesiones.joined(separator: ", ")),
            ("Apple Salud", perfil.saludConectada ? "Conectada" : "Más adelante"),
        ]
    }
}
