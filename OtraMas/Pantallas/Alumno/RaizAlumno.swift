import SwiftUI

enum PestanaAlumno: String, CaseIterable {
    case hoy, logros, plan

    var titulo: String {
        switch self { case .hoy: return "Hoy"; case .logros: return "Logros"; case .plan: return "Mi plan" }
    }
    var icono: Icono {
        switch self { case .hoy: return .pesa; case .logros: return .trofeo; case .plan: return .cal }
    }
}

/// La app del alumno: tres pestañas con la barra blanca propia (.tabs-app).
struct RaizAlumno: View {
    var arranque: Arranque?
    @State private var pestana: PestanaAlumno = .hoy

    var body: some View {
        TabView(selection: $pestana) {
            HoyToca().tag(PestanaAlumno.hoy).toolbar(.hidden, for: .tabBar)
            LogrosAlumno().tag(PestanaAlumno.logros).toolbar(.hidden, for: .tabBar)
            MiPlan().tag(PestanaAlumno.plan).toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BarraAlumno(pestana: $pestana)
        }
        .onAppear {
            switch arranque {
            case .logros: pestana = .logros
            case .miplan: pestana = .plan
            default: break
            }
        }
    }
}

/// .tabs-app: blanca, 84 con el indicador, ícono 24 y etiqueta 12.
struct BarraAlumno: View {
    @Binding var pestana: PestanaAlumno

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PestanaAlumno.allCases, id: \.self) { p in
                let on = p == pestana
                Button {
                    if !on { Haptico.seleccion() }
                    pestana = p
                } label: {
                    VStack(spacing: 4) {
                        IconoVista(p.icono, tamano: 24)
                        Text(p.titulo).tipo(.texto(12, on ? 700 : 600))
                    }
                    .foregroundStyle(on ? Color.berenjena800 : Color.arena600)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .contentShape(Rectangle())
                }
                .buttonStyle(Apretable())
                .accessibilityLabel(p.titulo)
                .accessibilityAddTraits(on ? [.isSelected, .isButton] : .isButton)
            }
        }
        .padding(.top, 8)
        .padding(.bottom, 2)
        .frame(maxWidth: .infinity)
        .background {
            Color.white
                .shadow(color: Color.berenjena800.opacity(0.06), radius: 12, y: -8)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

/// Cabecera del alumno: la foto de su profe, «Entrenás con Lucía» y «Hola, Nico».
struct CabeceraAlumno: View {
    let profe: String
    let alumno: String
    let foto: String

    var body: some View {
        HStack(spacing: 12) {
            FotoRedonda(nombre: foto, tamano: 40)
                .cambiaDeLado()
                .accessibilityLabel("Foto de \(profe). Tocala para ajustes; dejala apretada para cambiar de lado.")
                .accessibilityHidden(false)
            VStack(alignment: .leading, spacing: 0) {
                Text("Entrenás con \(profe)").tipo(.texto(16, 700)).foregroundStyle(Color.hueso)
                Text("Hola, \(alumno)").tipo(.texto(14, 400)).foregroundStyle(Color.berenjena300)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Espacio.margen)
        .padding(.top, 8)
    }
}

/// Esqueleto de una pantalla del alumno (banda + cuerpo, sin barra flotante).
struct PantallaAlumno<BandaC: View, Cuerpo: View>: View {
    @ViewBuilder var banda: () -> BandaC
    @ViewBuilder var cuerpo: () -> Cuerpo

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Banda { banda() }
                VStack(alignment: .leading, spacing: 0) { cuerpo() }
                    .padding(.horizontal, Espacio.margen)
                    .padding(.top, 24)
                    .padding(.bottom, 24)
            }
        }
        .scrollIndicators(.hidden)
        .background(Color.hueso.ignoresSafeArea())
    }
}
