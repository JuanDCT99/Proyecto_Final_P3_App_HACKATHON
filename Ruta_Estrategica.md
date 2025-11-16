### **Ruta Estratégica: Aplicación para Hackathon en Elixir**

**Objetivo:** Entregar un producto funcional y robusto que cumpla con todos los entregables solicitados.
**Equipo:** 3 Personas (P1, P2, P3).

---

### **Fase 1: Fundamentos y Configuración del Entorno (15% del Proyecto)**

**Objetivo:** Establecer las bases técnicas y de organización del proyecto. Todos los miembros deben estar en la misma página antes de escribir la lógica de negocio.

*   **Tareas Principales:**
    1.  **Configuración del Entorno (Todo el equipo):**
        *   Instalar Elixir, Erlang, Phoenix (si se usa para una API/interfaz web) y PostgreSQL (o la base de datos elegida).
        *   Asegurar que todos tengan un entorno de desarrollo idéntico y funcional.
    2.  **Estructura del Proyecto (P1):**
        *   Crear el proyecto base en Elixir (`mix new ...`).
        *   Definir la estructura de directorios y la arquitectura inicial (aplicaciones OTP, supervisores principales).
    3.  **Gestión de Versiones (P2):**
        *   Inicializar el repositorio en Git.
        *   Definir la estrategia de ramas (ej. `main`, `develop`, `feature/...`).
        *   Configurar el `.gitignore` para Elixir.
    4.  **Definición de Esquemas (P3):**
        *   Diseñar los esquemas de Ecto (o el ORM/DBAL que se elija) para `Participantes`, `Equipos`, y `Proyectos`.
        *   Crear los archivos de migración iniciales.

*   **Entregable de la Fase:** Un repositorio de Git con un proyecto Elixir base, estructura definida y migraciones listas para ser ejecutadas. Todos los miembros del equipo han realizado su primer commit.

---

### **Fase 2: Módulos Centrales y MVP (40% del Proyecto)**

**Objetivo:** Desarrollar la funcionalidad principal de la aplicación para tener un Producto Mínimo Viable (MVP) sobre el cual iterar.

*   **Tareas Principales:**
    1.  **Módulo de Gestión de Equipos (P1):**
        *   Implementar la lógica para registrar participantes.
        *   Crear funciones para formar equipos, asignar participantes y listar equipos activos.
        *   Implementar el comando `/teams` y `/join equipo`.
    2.  **Módulo de Gestión de Proyectos (P2):**
        *   Implementar la lógica para registrar una idea de proyecto con su descripción.
        *   Desarrollar la funcionalidad para actualizar avances en tiempo real (la base, sin el componente de comunicación aún).
        *   Implementar el comando `/project nombre_equipo`.
    3.  **Persistencia y Lógica de Negocio (P3):**
        *   Conectar los módulos de Equipos y Proyectos con la base de datos.
        *   Asegurar que toda la información se almacene y recupere correctamente.
        *   Crear los contextos de Elixir que separen la lógica de negocio del acceso a datos.

*   **Entregable de la Fase:** Una versión de la aplicación (ejecutable vía `mix`) que permite crear usuarios, equipos y proyectos, y consultar su estado mediante los comandos definidos.

---

### **Fase 3: Funcionalidades Avanzadas y Comunicación (25% del Proyecto)**

**Objetivo:** Implementar las características de colaboración en tiempo real y el módulo de mentoría, que son el núcleo de la naturaleza distribuida de la app.

*   **Tareas Principales:**
    1.  **Módulo de Chat Distribuido (P2 y P3):**
        *   Utilizar `GenServer` y `Phoenix Channels` (o similar) para la comunicación en tiempo real.
        *   (P2) Desarrollar la mensajería por equipo y el canal general de anuncios.
        *   (P3) Implementar la lógica para crear salas temáticas y el comando `/chat equipo`.
    2.  **Módulo de Mentoría (P1):**
        *   Añadir el esquema y lógica para registrar mentores.
        *   Crear el canal de consulta para que los equipos contacten a los mentores.
        *   Implementar el almacenamiento de la retroalimentación en el historial del proyecto.
    3.  **Integración y Tolerancia a Fallos (Todo el equipo):**
        *   Revisar la estructura de supervisores para asegurar que los procesos (chats, gestión de equipos) se reinicien ante fallos.
        *   Integrar los nuevos módulos con los ya existentes de forma cohesiva.

*   **Entregable de la Fase:** La aplicación ahora soporta chat en tiempo real entre equipos, comunicación con mentores y es resiliente a fallos básicos de procesos.

---

### **Fase 4: Pruebas, Despliegue y Seguridad (15% del Proyecto)**

**Objetivo:** Asegurar la calidad, rendimiento y seguridad de la aplicación, preparando el terreno para la entrega final.

*   **Tareas Principales:**
    1.  **Pruebas Unitarias y de Integración (P1 y P3):**
        *   (P1) Escribir pruebas para el módulo de Equipos y Mentoría.
        *   (P3) Escribir pruebas para el módulo de Proyectos y Chat.
        *   Asegurar una cobertura de código aceptable.
    2.  **Pruebas de Carga y Rendimiento (P2):**
        *   Simular la conexión de múltiples equipos y participantes.
        *   Medir el rendimiento de las actualizaciones en tiempo real y la comunicación.
        *   Generar los datos para el **informe de rendimiento y escalabilidad**.
    3.  **Seguridad (P1 o P3):**
        *   Implementar la autenticación de participantes.
        *   Asegurar que los mensajes y datos sensibles estén protegidos (cifrado si es necesario).

*   **Entregable de la Fase:** Un conjunto de pruebas automatizadas, datos concretos sobre el rendimiento y la seguridad implementada.

---

### **Fase 5: Finalización y Documentación (5% del Proyecto)**

**Objetivo:** Pulir el producto final y crear toda la documentación requerida para la entrega.

*   **Tareas Principales:**
    1.  **Documentación Técnica (P1):**
        *   Documentar la arquitectura del sistema, las decisiones de diseño y cómo compilar y ejecutar el proyecto.
    2.  **Manual de Usuario (P2):**
        *   Crear una guía clara sobre cómo usar la aplicación, detallando todos los comandos (`/help`, `/teams`, etc.).
    3.  **Informe de Pruebas y Empaquetado (P3):**
        *   Redactar el **informe final de rendimiento y escalabilidad** con los datos de la Fase 4.
        *   Preparar la **versión funcional lista para la Hackathon**.
    4.  **Revisión Final (Todo el equipo):**
        *   Revisar que todos los entregables estén completos y cumplan con los requisitos.
        *   Verificar que se cumple el requisito de **mínimo 15 commits por integrante**.

*   **Entregable Final:** Un paquete completo con el código fuente, toda la documentación, el informe y la aplicación funcional.

### **Consideraciones Adicionales**

*   **Comunicación Constante:** Usen reuniones cortas y frecuentes (stand-ups) para sincronizarse y ayudarse mutuamente.
*   **Git es Clave:** Hagan commits pequeños y descriptivos. Esto no solo cumple el requisito, sino que facilita la colaboración y la revisión del historial.
*   **Flexibilidad:** Esta ruta es una guía. Si un miembro del equipo termina antes, puede adelantar tareas de la siguiente fase o ayudar a un compañero. El objetivo es avanzar como equipo.
