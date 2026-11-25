import SwiftUI

/// La foto propia: tocarla abre Ajustes; dejarla apretada ofrece cambiar de lado o rehacer el inicio.
struct CambiarLado: ViewModifier {
    @Environment(Estado.self) private var estado
    @AppStorage("lado") private var lado = ""
    @State private var preguntar = false
    @State private var ajustes = false

    func body(content: Content) -> some View {
        content
            .contentShape(Circle())
            .onTapGesture { Haptico.seleccion(); ajustes = true }
            .onLongPressGesture(minimumDuration: 0.5) {
                Haptico.suave()
                preguntar = true
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityAction(named: "Ajustes") { ajustes = true }
            .accessibilityAction(named: "Cambiar de lado") { preguntar = true }
            .confirmationDialog("¿Cambiar de lado?", isPresented: $preguntar, titleVisibility: .visible) {
                Button(lado == Lado.profe.rawValue ? "Ver la app del alumno" : "Ver la app del profe") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        lado = lado == Lado.profe.rawValue ? Lado.alumno.rawValue : Lado.profe.rawValue
                    }
                }
                Button("Rehacer el inicio") { withAnimation { estado.borrarPerfil(); lado = "" } }
                Button("Cancelar", role: .cancel) {}
            }
            .sheet(isPresented: $ajustes) { Ajustes() }
    }
}

extension View {
    func cambiaDeLado() -> some View { modifier(CambiarLado()) }
}
