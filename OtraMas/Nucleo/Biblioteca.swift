import Foundation
import UIKit

enum GrupoEjercicio: String, Codable, CaseIterable, Hashable {
    case piernas, empuje, tiron, core, pilates
    var titulo: String {
        switch self {
        case .piernas: return "Piernas"
        case .empuje: return "Empuje"
        case .tiron: return "Tirón"
        case .core: return "Core y funcional"
        case .pilates: return "Pilates"
        }
    }
}

/// Un ejercicio de la biblioteca, con su ilustración en versión mujer y hombre.
/// Las ilustraciones van en Recursos/Ejercicios como `ej-<sexo>-<id>.jpg`, 400×400 (ver importar-ejercicios.sh).
struct Ejercicio: Codable, Hashable, Identifiable {
    var id: String
    var nombre: String
    var grupo: GrupoEjercicio

    /// Nombre de la imagen para ese sexo. «Prefiero no decir» usa la versión mujer.
    func ilustracion(para sexo: Sexo) -> String {
        "ej-\(sexo == .hombre ? "hombre" : "mujer")-\(id)"
    }

    /// La imagen que hay: la del sexo pedido, si no la otra (hay ejercicios sólo en versión mujer), si no ninguna.
    func imagen(para sexo: Sexo) -> UIImage? {
        Ejercicio.cargar(ilustracion(para: sexo)) ?? Ejercicio.cargar(ilustracion(para: sexo == .hombre ? .mujer : .hombre))
    }

    static func cargar(_ nombre: String) -> UIImage? {
        UIImage(named: nombre + ".jpg") ?? UIImage(named: nombre)
    }
}

struct Tip: Codable, Hashable, Identifiable {
    enum Tema: String, Codable { case entrenamiento, descanso, hidratacion, tecnica, cobros, retencion, organizacion }
    var id: Int
    var texto: String
    var tema: Tema
}

extension DatosDeMuestra {
    // El catálogo (`ejercicios`) está en Catalogo.swift, generado desde ejercicios/catalogo.json.

    static let tipsAlumno: [Tip] = [
        "Tomá agua antes de tener sed: un vaso al llegar y otro al irte.",
        "Si la última repetición sale fea, esa no cuenta. Bajá el peso.",
        "Dormir bien también es entrenar. Apuntá a siete u ocho horas.",
        "Respirá: soltá el aire en el esfuerzo, tomalo al volver.",
        "Más vale constante que heroico. Tres días por semana alcanzan.",
        "El descanso entre series es parte de la rutina. No lo saltees.",
        "Calentá cinco minutos antes de cargar. Tus rodillas te lo agradecen.",
        "Anotá lo que levantaste: la próxima vez sabés de dónde partir.",
        "Si algo duele distinto a cansancio, frená y avisale a tu profe.",
        "Una fruta y un yogur una hora antes te dan energía sin pesarte.",
        "Mirá un punto fijo adelante en la sentadilla: la espalda va derecha.",
        "Subí de a poco: dos kilos y medio más ya es progreso.",
        "Los días sin entrenar caminá. Suma más de lo que parece.",
        "Hidratate más si hace calor o entrenás al sol en la plaza.",
        "Apretá la panza en cada ejercicio: protege la espalda.",
        "Llegar es la mitad. Las ganas aparecen después de la primera serie.",
        "Estirá al final, no al principio: el cuerpo ya está caliente.",
        "Comé proteína en cada comida: huevo, carne, legumbres o lácteos.",
        "No te compares con otros. Compará con vos hace un mes.",
        "Si faltaste, no pasa nada. Lo importante es volver la próxima.",
    ].enumerated().map { Tip(id: $0.offset, texto: $0.element, tema: temasAlumno[$0.offset]) }

    private static let temasAlumno: [Tip.Tema] = [.hidratacion, .tecnica, .descanso, .tecnica, .entrenamiento, .descanso, .tecnica,
        .entrenamiento, .descanso, .entrenamiento, .tecnica, .entrenamiento, .entrenamiento, .hidratacion, .tecnica, .entrenamiento,
        .descanso, .entrenamiento, .entrenamiento, .entrenamiento]

    static let tipsProfe: [Tip] = [
        "Mandá el recordatorio de cuota el día 5, no el 15: pagan más rápido.",
        "Un mensaje cuando alguien falta dos veces evita que deje del todo.",
        "Festejá los récords en voz alta: el que mejora se queda.",
        "Pedí el comprobante por el link y te ahorrás perseguir capturas.",
        "Si llueve, avisá temprano y ofrecé recuperar: nadie se enoja.",
        "Subí la cuota con un mes de aviso y explicá por qué.",
        "Tené un alias fácil de dictar. Menos errores, menos vueltas.",
        "Una rutina nueva cada seis u ocho semanas mantiene las ganas.",
        "Preguntá cómo durmieron antes de exigir: cambia la clase.",
        "Los grupos chicos se quedan más tiempo. Cuidá el cupo.",
        "Agradecé a los que pagan a término. Se nota y se repite.",
        "Ofrecé una clase de prueba gratis a los amigos de tus alumnos.",
        "Separá la plata de las cuotas de la tuya: sabés cuánto ganás.",
        "Escribí corto y con nombre: «Hola Martina, ¿te veo el lunes?».",
        "Pasá lista siempre: la asistencia te avisa quién se está yendo.",
        "Cobrá el pack por adelantado y vencelo a fin de mes.",
        "Contá a tus alumnos cuánto mejoraron: los números motivan.",
        "Tomate un día libre por semana. El profe cansado no contagia.",
        "Pedí una reseña al alumno contento: es tu mejor publicidad.",
        "Si alguien no puede pagar este mes, hablalo antes de que falte.",
    ].enumerated().map { Tip(id: $0.offset, texto: $0.element, tema: temasProfe[$0.offset]) }

    private static let temasProfe: [Tip.Tema] = [.cobros, .retencion, .retencion, .cobros, .organizacion, .cobros, .cobros,
        .retencion, .retencion, .retencion, .cobros, .retencion, .cobros, .retencion, .retencion, .cobros, .retencion,
        .organizacion, .retencion, .cobros]

    static let perfilAlumno = Perfil(lado: .alumno, nombre: "Nico", sexo: .hombre, edad: 29, peso: 78, altura: 178,
                                     objetivo: .fuerza, experiencia: .algo, diasPorSemana: 3, lesiones: [], saludConectada: true)
    static let perfilProfe = Perfil(lado: .profe, nombre: "Lucía", sexo: .mujer, lugares: [.plaza, .domicilio], cantidadAlumnos: 30,
                                    cobros: [.transferencia, .efectivo, .mercadoPago], dias: ["Lun", "Mar", "Mié", "Jue", "Vie"],
                                    franjas: [.temprano, .tarde])
}
