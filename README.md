# OPTIRUTA — Aplicación Móvil

OPTIRUTA es un sistema inteligente de gestión, seguimiento y optimización de rutas de entrega diseñado para conductores, bodegueros y administradores. Esta aplicación móvil está construida con **Flutter** y utiliza **Firebase** como backend en tiempo real.

---

## 📱 Características Principales

*   **Acceso Multiperfil (Roles):** Pantallas personalizadas e inicio de sesión seguro para Administradores, Bodegueros y Conductores.
*   **Gestión de Pedidos en Tiempo Real:** Creación, edición, clasificación por zonas geográficas y control volumétrico de cajas.
*   **Asignación de Rutas:** Creación de rutas y despacho inteligente de camiones.
*   **Navegación y Confirmación de Entregas:** Mapas interactivos de entrega con soporte para firmas digitales táctiles y captura de fotos como evidencia de entrega.
*   **Historial de Entregas:** Calendario interactivo integrado para que los conductores consulten su registro histórico de entregas.

---

## 🛠️ Requisitos Previos

Antes de ejecutar la aplicación, asegúrate de tener instalado:

1.  **Flutter SDK** (Versión estable reciente): Sigue la guía oficial de instalación en [flutter.dev](https://docs.flutter.dev/get-started/install).
2.  **Dart SDK** (Incluido con Flutter).
3.  **Entorno de desarrollo:**
    *   [Android Studio](https://developer.android.com/studio) (para Android) con emulador o dispositivo físico configurado.
    *   [Xcode](https://developer.apple.com/xcode/) (únicamente en macOS, para iOS/macOS) con simulador iOS configurado.
4.  **Habilitar Modo Desarrollador** en tu teléfono móvil físico si deseas depurar directamente en hardware real.

---

## ⚙️ Configuración del Proyecto

Las credenciales de conexión con Firebase están integradas en la app en el archivo `lib/firebase_options.dart`. Si deseas conectar el proyecto a un entorno Firebase diferente:

1.  Instala FlutterFire CLI:
    ```bash
    dart pub global activate flutterfire_cli
    ```
2.  Configura Firebase en tu proyecto:
    ```bash
    flutterfire configure
    ```

---

## 🚀 Instalación y Ejecución

Sigue estos pasos para compilar y ejecutar la aplicación en tu entorno local:

### 1. Obtener dependencias
Descarga todas las dependencias definidas en el archivo `pubspec.yaml`:
```bash
flutter pub get
```

### 2. Ejecutar la aplicación en desarrollo
Asegúrate de tener un emulador abierto o un dispositivo conectado y ejecuta:
```bash
flutter run
```

### 3. Compilar para Producción

*   **Para Android (Generar APK):**
    ```bash
    flutter build apk --release
    ```
    El archivo APK compilado se guardará en `build/app/outputs/flutter-apk/app-release.apk`.

*   **Para iOS (Generar bundle de instalación):**
    ```bash
    flutter build ipa
    ```
