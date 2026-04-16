# app_medica

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

app_time4med/ (Carpeta raíz del proyecto)
│
├── android/                   # 📱 Archivos nativos de Android (Configuración del sistema)
│   └── app/
│       └── google-services.json 🚨 (El archivo secreto de Firebase. ¡Pásalo a tu equipo!)
├── ios/                       # 🍏 Archivos nativos de iOS
├── web/                       # 🌐 Archivos para correr la app en navegadores (Edge/Chrome)
├── pubspec.yaml               # 📦 Archivo donde se instalan los paquetes (Firebase, iconos, etc.)
│
└── lib/                       # ✨ EL CORAZÓN DE LA APP (Donde programamos en Dart) ✨
    │
    ├── main.dart              # ▶️ Punto de entrada: Arranca la app e inicializa Firebase.
    │
    ├── config/                # ⚙️ Configuraciones globales
    │   └── routes.dart        # 🗺️ "El mapa": Controla hacia qué pantalla va cada URL (/login, /doctor)
    │
    ├── services/              # 🧠 El "Cerebro" (Conexiones con el Backend/Nube)
    │   ├── auth_service.dart      # Maneja el inicio de sesión y registro con Firebase Auth.
    │   └── firestore_service.dart # Lee y escribe en la base de datos (Ej. Buscar el rol del usuario).
    │
    └── screens/               # 🎨 Interfaz Gráfica (Las vistas que ve el usuario)
        │
        ├── auth/                  # 🔐 Pantallas públicas
        │   ├── login_screen.dart      # Vista de Inicio de Sesión (Correo y contraseña).
        │   └── register_screen.dart   # Vista de Registro (Crear cuenta y elegir si es Dr. o Paciente).
        │
        ├── admin/                 # 🛡️ Vistas del Administrador
        │   └── home_admin.dart        # Panel de control: Estadísticas, altas de doctores y alertas.
        │
        ├── doctor/                # 🩺 Vistas del Médico
        │   └── home_doctor.dart       # Panel médico: Resumen general y lista de sus pacientes.
        │
        └── paciente/              # 👤 Vistas del Paciente
            └── home_paciente.dart     # Panel principal: Progreso diario, próximas tomas y consejos.
