import SwiftUI
import UIKit

/// Hoja de compartir del sistema para algo que se genera recién al tocar (un CSV, un JSON, un recibo).
struct ActividadCompartir: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ c: UIActivityViewController, context: Context) {}
}

private struct Paquete: Identifiable { let id = UUID(); let items: [Any] }

/// Botón que arma el archivo al tocarlo y abre «Compartir». Así no se generan archivos en cada dibujo.
struct CompartirBoton<Etiqueta: View>: View {
    let generar: () -> Any
    @ViewBuilder var etiqueta: () -> Etiqueta
    @State private var paquete: Paquete?

    var body: some View {
        Button { Haptico.seleccion(); paquete = Paquete(items: [generar()]) } label: { etiqueta() }
            .sheet(item: $paquete) { p in
                ActividadCompartir(items: p.items).presentationDetents([.medium, .large]).ignoresSafeArea()
            }
    }
}
