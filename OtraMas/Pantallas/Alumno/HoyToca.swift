import SwiftUI

/// 6 · Hoy toca, en modo foco: un ejercicio por vez, la serie, el descanso que cuenta, la carga con −/+ y ¡Listo!
struct HoyToca: View {
    @Environment(Estado.self) private var estado
    @Environment(\.dynamicTypeSize) private var dts
    @State private var terminar = false
    @State private var detalle: Ejercicio?

    var body: some View {
        let s = estado.alumno.sesion
        PantallaAlumno {
            barraFoco(s)
            if !estado.terminoSesion {
                video(estado.ejercicioActual)
            }
        } cuerpo: {
            if estado.terminoSesion {
                terminado
            } else {
                foco(estado.ejercicioActual, s)
            }
        }
        .task(id: s.descansoRestante > 0) {
            // El descanso cuenta solo: un tic por segundo mientras quede.
            while !Task.isCancelled && estado.alumno.sesion.descansoRestante > 0 {
                try? await Task.sleep(for: .seconds(1))
                if Task.isCancelled { break }
                estado.tickDescanso()
            }
        }
        .sheet(item: $detalle) { e in
            DetalleEjercicio(ejercicio: e, sexo: estado.sexoIlustracion, cerrable: true)
        }
        .confirmationDialog("¿Terminar por hoy?", isPresented: $terminar, titleVisibility: .visible) {
            Button("Empezar de nuevo", role: .destructive) { estado.reiniciarSesion() }
            Button("Seguir entrenando", role: .cancel) {}
        }
    }

    private func barraFoco(_ s: SesionHoy) -> some View {
        HStack(spacing: 16) {
            Redondo(icono: .cerrar, etiqueta: "Salir del entrenamiento") { terminar = true }
            HStack(spacing: 4) {
                ForEach(Array(s.ejercicios.enumerated()), id: \.offset) { i, _ in
                    Capsule()
                        .fill(i < s.actual ? Color.hueso : i == s.actual ? Color.yema : Color.hueso.opacity(0.18))
                        .frame(height: 4)
                }
            }
            .accessibilityElement()
            .accessibilityLabel("Ejercicio \(min(s.actual + 1, s.ejercicios.count)) de \(s.ejercicios.count)")
            HStack(spacing: 4) {
                IconoVista(.fuego, tamano: 20).foregroundStyle(Color.racha)
                Text("\(estado.alumno.logros.rachaSemanas)").tipo(.numero(20), alto: 20).foregroundStyle(Color.hueso)
            }
            .frame(height: 44)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Racha de \(estado.alumno.logros.rachaSemanas) semanas")
        }
        .padding(.horizontal, Espacio.margen)
        .frame(height: 52)
        .padding(.top, 4)
    }

    private func video(_ e: EjercicioSesion) -> some View {
        let ilus = estado.ejercicio(e.ejercicioId)
        return ZStack(alignment: .bottomLeading) {
            if let ilus {
                // La ilustración del ejercicio (mujer u hombre según el perfil), sobre hueso.
                Color(hex: 0xFAF7F2)
                IlustracionEjercicio(ejercicio: ilus, sexo: estado.sexoIlustracion)
                    .frame(maxWidth: .infinity)
                    .id(ilus.id)
                    .transition(.opacity)
            } else {
                FotoRecortada(nombre: e.foto, foco: UnitPoint(x: 0.5, y: 0.58))
                LinearGradient(stops: [.init(color: Color.berenjena950.opacity(0.5), location: 0), .init(color: .clear, location: 0.55)],
                               startPoint: .bottom, endPoint: .top)
            }
            Button {
                if let ej = ilus ?? estado.ejercicios.first(where: { $0.nombre.localizedCaseInsensitiveCompare(e.nombre) == .orderedSame }) {
                    detalle = ej
                } else {
                    estado.avisar("El video de \(e.nombre.lowercased()) lo sube tu profe.")
                }
            } label: {
                HStack(spacing: 8) {
                    IconoVista(.play, tamano: 16)
                    Text("Ver cómo se hace").tipo(.texto(14, 700))
                }
                .foregroundStyle(ilus == nil ? Color.berenjena800 : Color.hueso)
                .padding(.leading, 12).padding(.trailing, 16)
                .frame(height: 44)
                .background(ilus == nil ? Color.hueso.opacity(0.95) : Color.berenjena800,
                            in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
            }
            .buttonStyle(Apretable())
            .padding(12)
        }
        .frame(height: ilus == nil ? 176 : 220)
        .clipShape(RoundedRectangle(cornerRadius: Radio.tarjeta, style: .continuous))
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
    }

    @ViewBuilder
    private func foco(_ e: EjercicioSesion, _ s: SesionHoy) -> some View {
        Titulo(e.nombre, tamano: 40)
            .id(e.id)
            .transition(.push(from: .trailing))
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 8) {
                Etiqueta("Serie \(min(s.hechas + 1, e.series)) de \(e.series)", color: .tinta)
                HStack(spacing: 8) {
                    ForEach(0..<e.series, id: \.self) { i in
                        ZStack {
                            Circle().fill(i < s.hechas ? Color.berenjena800 : i == s.hechas ? Color.yema : Color.arena100)
                            if i < s.hechas {
                                IconoVista(.tilde, tamano: 14, grosor: 2.6).foregroundStyle(Color.yema)
                            }
                        }
                        .frame(width: 24, height: 24)
                    }
                }
                .accessibilityHidden(true)
            }
            Spacer(minLength: 8)
            HStack(spacing: 12) {
                VStack(alignment: .trailing, spacing: 4) {
                    Etiqueta("Descanso")
                    Text("de \(Formato.pausa(e.descanso))").tipo(.texto(12, 400)).foregroundStyle(Color.texto2)
                }
                Anillo(tamano: 56, grosor: 6, total: Double(e.descanso),
                       segmentos: [.init(valor: Double(s.descansoRestante), color: .yema)],
                       pista: .arena100, redondo: true) {
                    Text(Formato.reloj(s.descansoRestante)).tipo(.numero(20), alto: 20).foregroundStyle(Color.berenjena800)
                        .monospacedDigit()
                        .contentTransition(.numericText(countsDown: true))
                }
                .animation(.linear(duration: 1), value: s.descansoRestante)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(s.descansoRestante > 0 ? "Descanso: quedan \(s.descansoRestante) segundos" : "Sin descanso en curso")
        }
        .padding(.top, 16)

        HStack(alignment: .top, spacing: 0) {
            carga(valor: Formato.decimal(e.kilos), unidad: "kg", etiqueta: "kilos",
                  menos: { estado.cambiarCarga(kilos: -2.5) }, mas: { estado.cambiarCarga(kilos: 2.5) }, puedeBajar: e.kilos > 0)
            Text("×").tipo(.titulo(28)).foregroundStyle(Color.arena300).padding(.horizontal, 4).padding(.top, 34)
                .accessibilityHidden(true)
            carga(valor: "\(e.reps)", unidad: "reps", etiqueta: "repeticiones",
                  menos: { estado.cambiarCarga(reps: -1) }, mas: { estado.cambiarCarga(reps: 1) }, puedeBajar: e.reps > 1)
        }
        .padding(.top, 16)

        Button { estado.listo() } label: {
            HStack(spacing: 12) {
                IconoVista(.tilde, tamano: 28, grosor: 2.6)
                Text("¡LISTO!").tipo(.titulo(40), alto: 40)
            }
            .foregroundStyle(Color.berenjena800)
            .frame(maxWidth: .infinity)
            .frame(height: 72)
            .background(Color.yema, in: RoundedRectangle(cornerRadius: Radio.control, style: .continuous))
        }
        .buttonStyle(Apretable())
        .padding(.top, 24)
        .accessibilityLabel("Listo, terminé la serie")

        let dif = e.kilos - e.anterior
        Group {
            if e.anterior > 0 {
                (Text("La vez pasada \(Formato.decimal(e.anterior)) kg")
                 + (dif != 0 ? Text(" · ") + Text("hoy \(dif > 0 ? "+" : "−")\(Formato.decimal(abs(dif)))")
                    .font(Estilo.texto(14, 700).font(dts)).foregroundColor(dif > 0 ? .ok : .texto2) : Text("")))
            } else {
                Text("Primera vez con este ejercicio")
            }
        }
        .tipo(.texto(14, 400))
        .foregroundStyle(Color.texto2)
        .frame(maxWidth: .infinity)
        .padding(.top, 12)

        // Durante el descanso, de vez en cuando, un tip.
        if s.descansoRestante > 0, let t = estado.tip(.alumno, salto: s.hechas) {
            TipVista(tip: t)
                .padding(.top, 24)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private func carga(valor: String, unidad: String, etiqueta: String, menos: @escaping () -> Void, mas: @escaping () -> Void,
                       puedeBajar: Bool) -> some View {
        VStack(spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(valor).tipo(.numero(88)).tracking(-88 * 0.02).foregroundStyle(Color.berenjena800)
                    .contentTransition(.numericText())
                    .lineLimit(1).minimumScaleFactor(0.6)
                Text(unidad).tipo(.texto(16, 700)).foregroundStyle(Color.texto2)
            }
            .frame(height: 88)
            HStack(spacing: 12) {
                BotonRedondo(icono: .menos, etiqueta: "Menos \(etiqueta)", habilitado: puedeBajar, accion: menos)
                BotonRedondo(icono: .mas, etiqueta: "Más \(etiqueta)", accion: mas)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(valor) \(etiqueta)")
    }

    private var terminado: some View {
        VStack(alignment: .leading, spacing: 12) {
            Titulo("¡Terminaste!", tamano: 64)
            Text("Hiciste los \(estado.alumno.sesion.ejercicios.count) ejercicios de hoy. Tu racha sigue: \(estado.alumno.logros.rachaSemanas) semanas.")
                .tipo(.texto(16, 400)).foregroundStyle(Color.texto2)
            Boton(titulo: "Volver a empezar", variante: .suave, alto: .alto, ancho: true) { estado.reiniciarSesion() }
                .padding(.top, 12)
        }
        .padding(.top, 24)
    }
}
