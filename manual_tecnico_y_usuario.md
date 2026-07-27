# OPTIRUTA - Manual Técnico y de Usuario

Este documento compila el **Manual Técnico** y el **Manual de Usuario** del sistema inteligente de optimización y monitoreo de entregas **OPTIRUTA**. Ha sido completado en el marco del cierre de la tarea **OP-214 (T-3)** del Sprint 4.

---

## PARTE I: MANUAL TÉCNICO

### 1. Arquitectura y Estructura General
OPTIRUTA está desarrollada bajo el SDK de **Flutter** utilizando la arquitectura de separación de conceptos (Clean Concerns) y modularidad por roles, enlazada en tiempo real con **Firebase** (Auth, Firestore, FCM).

El punto de entrada es [main.dart](file:///c:/Users/Alumno/Documents/Proyecto/OPTIRUTAFINAL/lib/main.dart), el cual inicializa los servicios de Firebase y arranca la aplicación en la pantalla de enrutamiento principal: [welcome_screen.dart](file:///c:/Users/Alumno/Documents/Proyecto/OPTIRUTAFINAL/lib/screens/welcome_screen.dart).

### 2. Estructura de Directorios (`lib/`)
*   **`models/`**: Clases de datos estructuradas (ej. `pedido.dart` para mapear los pedidos).
*   **`providers/`**: Manejo de estados y configuraciones de accesibilidad (ej. `pedido_provider.dart` para regular factores de tamaño de letra y temas visuales).
*   **`services/`**: Lógica de fondo nativa (ej. `notification_service.dart` para registrar tokens y escuchar alertas FCM).
*   **`utils/`**: Clases de utilidades (ej. `geocoding_helper.dart` que integra geocodificación mediante la API de OpenStreetMap/Nominatim).
*   **`screens/`**: Carpeta modular que aísla las pantallas según el rol del usuario:
    *   **`admin/`**: Pantallas exclusivas de Super Administrador (gestión de conductores, monitoreo y exportador PDF).
    *   **`bodega/`**: Pantallas de Bodeguero (gestión de inventario de cajas, clasificación y asignación de rutas).
    *   **`conductor/`**: Pantallas de Conductor (mapas de navegación, historial de entregas y recolección de firmas/fotos).

### 3. Modelo de Datos de Base de Datos (Cloud Firestore)
La base de datos se estructura en cinco colecciones principales sincronizadas en tiempo real:

#### A. Colección `usuarios`
*   `correo` (String): Correo electrónico único de la cuenta.
*   `nombre` (String): Nombre completo del usuario.
*   `rol` (String): Asignación de permisos (`'Administrador'`, `'Bodeguero'`, `'Conductor'`).
*   `estado` (Boolean): Indica si la cuenta está activa o deshabilitada.
*   `fcmToken` (String): Token único de notificaciones del dispositivo.

#### B. Colección `conductores` (Exclusivo de Choferes)
*   `nombre` (String)
*   `apellido` (String)
*   `correo` (String)
*   `telefono` (String)
*   `tipoLicencia` (String)

#### C. Colección `pedidos`
*   `id` (String - Document ID)
*   `cliente` (String)
*   `direccion` (String)
*   `telefono` (String)
*   `detalle` (String)
*   `numeroCajas` (Integer)
*   `prioridad` (String: `'Alta'`, `'Media'`, `'Baja'`)
*   `estado` (String: `'Pendiente'`, `'Asignado'`, `'En Ruta'`, `'Entregado'`, `'No entregado'`)

#### D. Colección `rutas`
*   `conductorId` (String): UID del conductor asignado.
*   `nombreConductor` (String): Nombre completo del chofer.
*   `estado` (String: `'Activa'`, `'Completada'`, `'Cancelada'`)
*   `pedidos` (Array of Strings): Lista de IDs de los pedidos ordenados de esa ruta.

#### E. Colección `entregas` (Evidencias de Entrega)
*   `pedidoId` (String): ID del pedido completado.
*   `conductorId` (String): UID del conductor que realizó la entrega.
*   `estado` (String: `'Entregado'` / `'No entregado'`)
*   `observaciones` (String)
*   `firmaBase64` (String - NULL en 'No entregado'): Imagen en Base64 de la firma del cliente.
*   `fotoBase64` (String - NULL en 'No entregado'): Imagen en Base64 de la foto de la fachada/evidencia.
*   `cajasDevueltas` (Integer - mayor a 0 en 'No entregado').
*   `fechaActualizacion` (Timestamp): Fecha y hora exactas del despacho.

### 4. Dependencias Principales (`pubspec.yaml`)
*   `firebase_core` & `firebase_auth` & `cloud_firestore`: Base e inicio de sesión.
*   `firebase_messaging`: Notificaciones Push en tiempo real.
*   `flutter_map` & `latlong2`: Mapas interactivos libres basados en OpenStreetMap (sin costo por API).
*   `pdf` & `printing`: Generador e impresor nativo de documentos PDF.
*   `signature`: Panel táctil de captura de firma.

---

## PARTE II: MANUAL DE USUARIO

### 1. Pantalla Inicial y Selección de Rol
1.  Al abrir la aplicación, verás la pantalla de **Bienvenida**.
2.  Haz clic en una de las tres tarjetas del perfil correspondiente: **Super Administrador**, **Bodeguero** o **Conductor**.
3.  Presiona el botón **Siguiente**.

> [!TIP]
> Si olvidaste tu contraseña, en la pantalla de inicio de sesión de tu rol (Bodeguero o Conductor) haz clic en **"¿Olvidaste tu contraseña?"** para recibir un correo automático de restablecimiento.

---

### 2. Guía para el Super Administrador
El Administrador gestiona el sistema globalmente y monitorea las entregas.

*   **Dashboard**: Muestra métricas rápidas de pedidos totales, rutas activas, conductores y entregas completadas.
*   **Gestión de Conductores**: 
    1.  Ingresa a la sección "Conductores".
    2.  Puedes **Editar** los datos de un chofer (teléfono, tipo de licencia) o **Eliminar** su cuenta permanentemente.
    3.  Puedes **Desactivar** (o volver a **Activar**) a un conductor. Si lo desactivas, no podrá iniciar sesión en la app hasta que lo habilites nuevamente.
*   **Monitoreo en Vivo (Mapa)**: 
    *   Ingresa a la sección "Pedidos". En la pestaña "Monitoreo en Vivo" se muestra un mapa con marcadores de todos los despachos con colores según su estado (Verde: Entregado, Azul: En Ruta, Naranja: Asignado).
*   **Exportar a PDF (Reportes)**:
    *   *Reporte General*: En la pestaña "Reporte de Entregas", presiona el botón inferior **"Exportar Reporte"** para descargar un documento PDF estructurado de todos los envíos con sus KPIs globales.
    *   *Reporte Individual*: Haz clic en el ícono de **PDF** al lado de cualquier pedido para descargar el reporte detallado con la firma digital del cliente y la foto de evidencia capturada por el conductor.

---

### 3. Guía para el Bodeguero
El Bodeguero prepara y despacha la mercadería en la bodega.

*   **Registrar / Editar Pedido**:
    1.  Presiona **"Registrar Pedido"** e ingresa el cliente, dirección, cantidad de cajas y prioridad.
    2.  Puedes modificar los datos de cualquier pedido pendiente desde el dashboard.
*   **Clasificación por Zonas**: 
    *   Presiona **"Clasificar Pedidos"** para agrupar automáticamente los envíos según sus zonas geográficas y organizar la carga de manera óptima.
*   **Asignar Conductor y Ruta**:
    1.  Haz clic en un pedido pendiente.
    2.  Selecciona de la lista al conductor activo. Esto creará la ruta en tiempo real.
*   **Confirmar Carga**:
    *   Una vez que el conductor ha estibado las cajas en el camión, el bodeguero presiona **"Confirmar Carga"** para cambiar el estado de la ruta a "En Ruta", lo cual alerta al conductor.

---

### 4. Guía para el Conductor
El Conductor transporta y entrega los pedidos en destino usando la app móvil.

*   **Rutas Activas**: Al ingresar, el dashboard muestra las rutas que tiene asignadas. Si el bodeguero le asigna una nueva ruta mientras la app está abierta, recibirá una **notificación en tiempo real** en forma de banner deslizante.
*   **Navegación (Mapa)**: Toca la ruta activa para abrir el mapa interactivo que traza el camino desde la bodega principal hasta la dirección de entrega del cliente.
*   **Confirmación de Entrega**:
    1.  Al llegar con el cliente, haz clic en **"Confirmar Entrega"**.
    2.  Si la entrega fue exitosa: Selecciona **"Entregado"**, pídele al cliente que dibuje su firma en el panel táctil y toma una foto de la fachada como evidencia fotográfica.
    3.  Si la entrega falló: Selecciona **"No entregado"**, detalla el motivo del rechazo y la cantidad de cajas devueltas a la bodega.
    4.  Presiona **"Guardar"** para actualizar el estado instantáneamente.
*   **Historial de Entregas**:
    *   Haz clic en el ícono de **Historial** (reloj) en la parte superior derecha para ver el registro de tus entregas pasadas filtradas por fecha en un calendario.
