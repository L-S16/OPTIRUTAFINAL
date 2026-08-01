# OPTIRUTA Web — Módulo de Reingeniería

Este directorio contiene la versión web del sistema **OPTIRUTA**, migrada desde la aplicación móvil original (desarrollada en Flutter). La web interactúa en tiempo real con la misma base de datos de Firebase Firestore y Authentication de la aplicación móvil.

---

## 🚀 Requisitos Previos

Para ejecutar la aplicación localmente en tu computadora, necesitas tener instalado al menos **uno** de los siguientes entornos:

*   **Node.js** (Recomendado): Descárgalo e instálalo desde [nodejs.org](https://nodejs.org/).
*   **Python 3**: Descárgalo e instálalo desde [python.org](https://www.python.org/).

*Nota: No necesitas instalar servidores complejos como Apache o Nginx. El sistema incluye scripts ligeros para levantar el entorno al instante.*

---

## 💻 Cómo Iniciar el Servidor

Los navegadores web bloquean la conexión a Firebase si intentas abrir los archivos `.html` haciendo doble clic directamente (protocolo `file://`). La aplicación debe servirse bajo el protocolo `http://`.

Dispones de dos métodos para iniciar la aplicación:

### Método 1: Ejecución Automática (Windows)
1. Ve a la carpeta `reingenieria-optiruta/`.
2. Haz doble clic sobre el archivo **`iniciar.bat`**.
3. El script detectará tu entorno, levantará el servidor web local en el puerto `3000` y mantendrá abierta la consola.

### Método 2: Ejecución Manual desde la Consola
Abre tu consola de comandos (Terminal, CMD o PowerShell), navega hasta la carpeta del proyecto y ejecuta uno de los siguientes comandos:

*   **Si usas Node.js (Recomendado):**
    ```bash
    npx serve . -p 3000
    ```
*   **Si usas Python:**
    ```bash
    python -m http.server 3000
    ```

---

## 🌐 Acceso a la Aplicación

Una vez que el servidor esté corriendo por cualquiera de los métodos anteriores:

1. Abre tu navegador web de preferencia (Chrome, Edge, Firefox).
2. Ingresa a la siguiente dirección:
   
   👉 **[http://localhost:3000](http://localhost:3000)**

3. Selecciona tu perfil (Administrador, Bodeguero o Conductor) para iniciar sesión con tus credenciales.

---

## 🔐 Notas de Configuración y Seguridad
*   **Bases de datos**: La configuración de Firebase está integrada en `js/firebase-config.js` y apunta al proyecto real `optiruta-7bf9f` de la app móvil.
*   **CORS / Dominios Autorizados**: Si configuras un dominio personalizado o puerto diferente, recuerda registrar el host en tu consola de Firebase en la sección de *Authentication -> Settings -> Authorized Domains*.
