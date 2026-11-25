import SwiftUI

/// 4 · Armado de rutina (modal): días, ejercicios con steppers de series, repeticiones y kilos, y la pausa.
struct ArmadoRutina: View {
    @Environment(Estado.self) private var estado
    @Environment(NavProfe.self) private var nav
    @Environment(\.dismiss) private var dismiss
    @State private var rutina: Rutina
    @State private var renombrar = false
    @State private var nombreNuevo = ""

    init(rutina: Rutina = DatosDeMuestra.rutina) {
        _rutina = State(initialValue: rutina)
    }
    @State private var dia = 0
    @State private var abierto: String? = "e1"
    @State private var asignar = false
    @State private var biblioteca = false

    private let pausas = [60, 90, 120, 180]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Banda { banda }
                    VStack(spacing: 12) {
                        let ejercicios = rutina.dias[dia].ejercicios
                        ForEach(Array(ejercicios.enumerated()), id: \.element.id) { i, e in
                            tarjeta(indice: i, total: ejercicios.count, e)
                        }
                        Button {
                            biblioteca = true
                        } label: {
                            HStack(spacing: 8) {
                                IconoVista(.mas, tamano: 20)
                                Text("Sumar ejercicio").tipo(.texto(16, 700))
                            }
                            .foregroundStyle(Color.berenjena800)
                            .frame(maxWidth: .infinity).frame(height: 56)
                            .overlay(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous)
                                .strokeBorder(Color.arena300, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                        }
                        .buttonStyle(Apretable())
                    }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 24)
                    .padding(.bottom, 130)
                }
            }
            .scrollIndicators(.hidden)
            .background(Color.hueso.ignoresSafeArea())

            // .barra-inf: Guardar + Asignar a varios, sobre un velo hueso.
            GeometryReader { g in
                let w = g.size.width - 12
                HStack(spacing: 12) {
                    Boton(titulo: "Guardar", variante: .suave, alto: .alto, ancho: true) {
                        estado.guardar(rutina: rutina)
                        dismiss()
                    }
                    .frame(width: w / 2.6)
                    Boton(titulo: "Asignar a varios", icono: .gente, variante: .prim, alto: .alto, ancho: true) {
                        asignar = true
                    }
                    .frame(width: w * 1.6 / 2.6)
                }
            }
            .frame(height: 56)
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 24)
            .padding(.bottom, 0)
            .background(alignment: .top) {
                LinearGradient(stops: [.init(color: .hueso.opacity(0), location: 0), .init(color: .hueso, location: 0.22)],
                               startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
            }
        }
        .sheet(isPresented: $biblioteca) {
            NavigationStack { Biblioteca(elegir: { agregarEjercicio($0) }, volver: "Cerrar") }
        }
        .onChange(of: asignar) { _, abrir in
            guard abrir else { return }
            // Se guarda y se asigna desde la hoja de asignar, ya fuera del armado.
            estado.guardar(rutina: rutina, avisando: false)
            let id = rutina.id
            dismiss()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { nav.hoja = .asignarRutina(id, []) }
        }
        .alert("Nombre de la rutina", isPresented: $renombrar) {
            TextField("Piernas y zona media", text: $nombreNuevo)
            Button("Listo") {
                let n = nombreNuevo.trimmingCharacters(in: .whitespaces)
                if !n.isEmpty { rutina.nombre = n }
            }
            Button("Cancelar", role: .cancel) {}
        }
    }

    private var banda: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Button("Cancelar") { dismiss() }
                    .font(Estilo.texto(16, 600).font())
                    .foregroundStyle(Color.hueso)
                    .padding(.horizontal, 8)
                    .frame(height: 44)
                Spacer()
                Redondo(icono: .camara, etiqueta: "Cargar desde una foto") {
                    estado.avisar("Sacale una foto a la rutina en papel y la pasamos.")
                }
            }
            .padding(.leading, 12)
            .padding(.trailing, 20)
            .frame(height: 44)
            VStack(alignment: .leading, spacing: 8) {
                Etiqueta(rutina.plan, color: .berenjena300)
                Button {
                    nombreNuevo = rutina.nombre == "Rutina nueva" ? "" : rutina.nombre
                    renombrar = true
                } label: {
                    Titulo(rutina.nombre, tamano: 40, color: .hueso)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Cambiar el nombre")
            }
            .padding(.horizontal, Espacio.margen)
            .padding(.top, 8)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(Array(rutina.dias.enumerated()), id: \.element.id) { i, d in
                        Chip(titulo: d.nombre, elegido: dia == i, sobreBanda: true) {
                            Haptico.seleccion()
                            withAnimation(.snappy(duration: 0.25)) { dia = i; abierto = rutina.dias[i].ejercicios.first?.id }
                        }
                    }
                    Button {
                        agregarDia()
                    } label: {
                        IconoVista(.mas, tamano: 20).foregroundStyle(Color.hueso)
                            .frame(width: 44, height: 44)
                            .background(Color.huesoOsc, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    }
                    .buttonStyle(Apretable())
                    .accessibilityLabel("Sumar un día")
                }
                .padding(.horizontal, Espacio.margen)
            }
            .scrollIndicators(.hidden)
            .padding(.top, 16)
        }
    }

    @ViewBuilder
    private func tarjeta(indice i: Int, total: Int, _ e: EjercicioDeRutina) -> some View {
        let expandido = abierto == e.id
        Tarjeta {
            Button {
                Haptico.seleccion()
                withAnimation(.snappy(duration: 0.3)) { abierto = expandido ? nil : e.id }
            } label: {
                HStack(spacing: 12) {
                    Group {
                        if let ej = estado.ejercicio(e.ejercicioId) {
                            IlustracionEjercicio(ejercicio: ej, sexo: estado.sexoIlustracion)
                        } else {
                            FotoRecortada(nombre: e.foto, foco: UnitPoint(x: e.focoX, y: e.focoY))
                        }
                    }
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
                    VStack(alignment: .leading, spacing: 4) {
                        Etiqueta("\(i + 1) de \(total)", color: .yema700)
                        Text(e.nombre).tipo(.texto(expandido ? 20 : 16, 700)).foregroundStyle(Color.tinta).lineLimit(1)
                        if !expandido {
                            Text(resumen(e)).tipo(.texto(14, 400)).foregroundStyle(Color.texto2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    IconoVista(.agarre, tamano: 20).foregroundStyle(Color.arena300)
                        .frame(width: 44, height: 44)
                        .padding(.trailing, -12)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(i + 1) de \(total), \(e.nombre), \(resumen(e))")
            .accessibilityHint(expandido ? "Cerrar" : "Editar")
            if expandido {
                Divisor()
                Paso(etiqueta: "Series", valor: enlace(e.id, \.series), rango: 1...10)
                Divisor()
                Paso(etiqueta: "Repeticiones", valor: enlace(e.id, \.reps), rango: 1...60)
                Divisor()
                Paso(etiqueta: "Kilos", valor: enlace(e.id, \.kilos), paso: 2.5, rango: 0...300, formato: Formato.decimal)
                Divisor()
                Etiqueta("Pausa").padding(.horizontal, 16).padding(.top, 12)
                HStack(spacing: 8) {
                    ForEach(pausas, id: \.self) { p in
                        Chip(titulo: Formato.pausa(p), elegido: e.pausa == p, elegidoOscuro: true, ancho: true) {
                            Haptico.seleccion()
                            if let j = indiceEjercicio(e.id) { rutina.dias[dia].ejercicios[j].pausa = p }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                Divisor()
                Button(role: .destructive) { quitar(e) } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash").font(.system(size: 15, weight: .semibold))
                        Text("Quitar de la rutina").tipo(.texto(15, 700))
                    }
                    .foregroundStyle(Color.error)
                    .frame(maxWidth: .infinity).frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Quitar \(e.nombre) de la rutina")
            }
        }
        .contextMenu {
            Button(role: .destructive) { quitar(e) } label: { Label("Quitar de la rutina", systemImage: "trash") }
        }
    }

    private func quitar(_ e: EjercicioDeRutina) {
        guard let j = indiceEjercicio(e.id) else { return }
        Haptico.seleccion()
        withAnimation(.snappy(duration: 0.3)) {
            rutina.dias[dia].ejercicios.remove(at: j)
            if abierto == e.id { abierto = nil }
        }
        estado.avisar("Quitamos \(e.nombre).")
    }

    private func resumen(_ e: EjercicioDeRutina) -> String {
        let base = "\(Int(e.series)) × \(Int(e.reps))"
        return e.kilos > 0 ? "\(base) · \(Formato.decimal(e.kilos)) kg" : base
    }

    private func indiceEjercicio(_ id: String) -> Int? { rutina.dias[dia].ejercicios.firstIndex { $0.id == id } }

    private func enlace(_ id: String, _ k: WritableKeyPath<EjercicioDeRutina, Double>) -> Binding<Double> {
        Binding(get: { indiceEjercicio(id).map { rutina.dias[dia].ejercicios[$0][keyPath: k] } ?? 0 },
                set: { v in if let j = indiceEjercicio(id) { rutina.dias[dia].ejercicios[j][keyPath: k] = v } })
    }

    private func agregarDia() {
        let letra = String(UnicodeScalar(UInt8(65 + rutina.dias.count)))
        Haptico.seleccion()
        withAnimation(.snappy) {
            rutina.dias.append(DiaRutina(id: UUID().uuidString, nombre: "Día \(letra)", ejercicios: []))
            dia = rutina.dias.count - 1
        }
    }

    private func agregarEjercicio(_ base: Ejercicio) {
        let e = EjercicioDeRutina(id: UUID().uuidString, ejercicioId: base.id, nombre: base.nombre,
                                  foto: "foto-detalle", focoX: 0.5, focoY: 0.5,
                                  series: 3, reps: 10, kilos: 0, pausa: 60)
        Haptico.seleccion()
        withAnimation(.snappy) {
            rutina.dias[dia].ejercicios.append(e)
            abierto = e.id
        }
    }
}
