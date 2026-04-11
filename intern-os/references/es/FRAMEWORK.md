# internOS — Framework de Workstreams

*Versión: 0.3.0 | Fecha: 2026-04-11 | Estado: v0.3.0 — modelo Proyecto + Workstream, arquitectura de tres capas*

---

## El sistema en una línea

Cada workstream es una unidad acotada de ejecución que mapea a exactamente un thread de comunicación, mantiene estado activo en archivos estructurados, y puede reconstruirse independientemente a partir de esos archivos.

---

## Las tres capas

internOS opera a través de tres capas explícitas.

### 1. Capa de almacenamiento

Los archivos de workstream son el estado operacional autoritativo. No el transcript, no la memoria del agente.

| Componente | Qué almacena |
|------------|-------------|
| `PROJECT.md` | Identidad del proyecto: propósito, alcance, dirección |
| `AGENTS.md` | Contexto de agente a nivel proyecto: stack, convenciones, personas |
| `TICK.md` | Gestión de tareas: qué hay que hacer, quién lo hace |
| Archivos de workstream | Estado operacional: identidad, estado, memoria, decisiones, personas, recursos |

### 2. Capa de resolución

La resolución debe ser exacta, determinista y no heurística.

**Regla canónica:** Cada workstream declara su thread de comunicación vinculado en `BRIEF.md`:

```
thread_id: discord:1491150845675438110
```

**Reglas de resolución:**
1. Resolver por `thread_id` exacto
2. Si existe coincidencia exacta, cargar ese workstream
3. Si no existe coincidencia exacta, detenerse y preguntar — o vincular
4. Nunca resolver por coincidencia difusa, similitud de palabras clave, o proximidad de ruta

**Fuente de verdad:** `BRIEF.md` es la fuente de verdad para la vinculación thread-workstream. Puede existir un registro o índice derivado para rendimiento de búsqueda, pero `BRIEF.md` es canónico.

### 3. Capa de runtime

Cargar solo lo necesario para el turno actual.

**Política de carga por defecto (Tier 1):**
- `BRIEF.md`
- `STATUS.md`

**Bajo demanda (Tier 2) — cuando la tarea requiere contexto de relaciones o decisiones:**
- `DECISIONS.md`
- `STAKEHOLDERS.md`

**Bajo demanda (Tier 3) — cuando la tarea requiere contexto acumulado o detallado:**
- `MEMORY.md`
- `RESOURCES.md`
- `docs/*`

**Reglas de runtime:**
- No leer archivos de otros workstreams por defecto
- No escanear ampliamente `projects/`
- No hacer fallback heurístico si falta la vinculación
- Si la sesión se degrada, reconstruir desde archivos en lugar de depender de la continuidad del transcript

---

## Estructura de proyecto

Cada proyecto es un directorio auto-contenido:

```
projects/
├── project-alpha/
│   ├── PROJECT.md           ← Identidad del proyecto: propósito, alcance, dirección
│   ├── AGENTS.md            ← Contexto de agente a nivel proyecto (opcional)
│   ├── TICK.md              ← tick-md: todas las tareas del proyecto
│   ├── .tick/
│   │   └── config.yml       ← configuración de tick-md
│   ├── workstreams/
│   │   ├── feature-x/
│   │   │   ├── BRIEF.md
│   │   │   ├── STATUS.md
│   │   │   ├── MEMORY.md
│   │   │   ├── DECISIONS.md
│   │   │   ├── STAKEHOLDERS.md
│   │   │   ├── RESOURCES.md
│   │   │   └── docs/
│   │   └── bug-fix-y/
│   │       └── ...
│   └── docs/                ← artefactos del proyecto
└── project-beta/
    ├── PROJECT.md
    ├── AGENTS.md
    ├── TICK.md
    ├── .tick/
    └── workstreams/
```

Los proyectos no están vinculados a threads. Los workstreams están vinculados a threads.

### AGENTS.md — Contexto de agente a nivel proyecto

`AGENTS.md` en la raíz del proyecto proporciona contexto que aplica a todos los workstreams del proyecto:

- Stack tecnológico y convenciones de código
- Personas clave y sus roles
- Reglas de comunicación específicas del proyecto
- Integraciones activas (APIs, plataformas)
- Restricciones o invariantes arquitectónicas

**Comportamiento de carga:** Cuando un agente entra en un thread de workstream, carga `AGENTS.md` del directorio padre del proyecto antes de cargar los archivos del workstream. Si el archivo no existe, el agente continúa normalmente.

**Orden de carga:**
1. `projects/[proyecto]/AGENTS.md` — contexto a nivel proyecto
2. `projects/[proyecto]/workstreams/[nombre]/BRIEF.md` — identidad del workstream
3. `projects/[proyecto]/workstreams/[nombre]/STATUS.md` — estado actual
4. Escalar a otros archivos solo cuando sea necesario

Esto separa el contexto del proyecto del contexto del workstream, evita repetir información del proyecto en cada BRIEF.md, y funciona en todas las plataformas (sin dependencia de `cwd`).

### Estructura de archivos por workstream

Cada workstream tiene un directorio con 6 archivos estándar:

```
workstreams/[nombre]/
├── BRIEF.md         ← Identidad del workstream + vinculación thread_id (obligatorio)
├── STATUS.md        ← Pulso operacional: fase, siguiente, bloqueadores
├── MEMORY.md        ← Contexto durable entre sesiones (≤80 líneas)
├── DECISIONS.md     ← Log de decisiones clave con fecha + razón
├── STAKEHOLDERS.md  ← Personas relevantes y su rol
├── RESOURCES.md     ← Inventario de artefactos y dónde viven
└── docs/            ← Artefactos de trabajo
```

**Convención:** Todos los archivos markdown del sistema en MAYÚSCULAS.

---

## Relación tarea–workstream

Las tareas viven en `TICK.md` en la raíz del proyecto. Los workstreams viven en `workstreams/`. Se conectan mediante tags:

- Cada tarea en TICK.md se etiqueta con el nombre del workstream (ej. `tags: [feature-x]`)
- Un workstream puede tener **1 o N tareas** — algunos workstreams son una sola tarea, otros tienen muchas
- `tick list --tag feature-x` muestra todas las tareas de ese workstream
- `tick status` muestra todas las tareas del proyecto

**STATUS.md es la salud a nivel workstream** — progreso agregado, dirección, bloqueadores. No rastrea el estado de tareas individuales. tick.md es dueño del estado de tareas.

**TICK.md es la fuente de verdad a nivel tarea** — estado, prioridad, asignación, claim/release, historial. No describe el propósito o contexto del workstream. Los archivos de workstream de intern-os son dueños de eso.

> tick.md es la capa de gestión de tareas por defecto. Otros sistemas (Notion, Linear, Trello, etc.) pueden usarse en su lugar — ver la sección de gestión de tareas en SETUP.md.

**Sobre artefactos:** no existe un repositorio único. `docs/` dentro de cada workstream es uno de N posibles repositorios (Notion, Google Drive, S3, R2, etc.). `RESOURCES.md` es el índice que lleva la relación de todos los recursos y dónde viven.

---

## Protocolo de escritura

**Quién escribe qué:**

| Actor | Escribe cuando... | Archivos |
|-------|-------------------|----------|
| **Agente** | Al final de una sesión de trabajo en el thread | STATUS.md, MEMORY.md, DECISIONS.md |
| **Humano** | Hay una decisión estratégica, cambio de dirección o info nueva | Cualquier archivo |
| **Ambos** | Al crear un workstream nuevo | BRIEF.md, STAKEHOLDERS.md, RESOURCES.md |

**Regla de oro:** Si el agente no puede responder "¿en qué está este workstream?" leyendo STATUS.md, el archivo está desactualizado.

**Restricciones de tamaño de archivos de workstream:**

Estos límites aplican a archivos dentro de `projects/[proyecto]/workstreams/[nombre]/` — los archivos de workstream de intern-os. NO aplican a los archivos de memoria o configuración propios del framework del agente.

| Archivo de workstream | Regla de lectura | Tamaño objetivo |
|-----------------------|-----------------|-----------------|
| BRIEF.md | Leer completo | Sin límite (típicamente 1-3 KB) |
| STATUS.md | Leer completo | ≤10 líneas — fase, siguiente, propietario, bloqueadores, actualizado |
| MEMORY.md | **Últimas 80 líneas solamente** | Mantener bajo 80 líneas — resumen curado, no log |
| DECISIONS.md | Leer completo | Log de append-only, crece lentamente |
| STAKEHOLDERS.md | Leer completo | Rara vez cambia |
| RESOURCES.md | Leer completo | Índice de append-only |

**Higiene de MEMORY.md de workstream:** Cuando el MEMORY.md de un workstream excede 80 líneas, el agente debe consolidarlo — promover insights clave al inicio, archivar o eliminar entradas obsoletas. Los logs detallados de sesión van en el directorio `docs/` del workstream, no en MEMORY.md. Esto previene crecimiento ilimitado de contexto que degrada el tiempo de startup del agente en plataformas con timeout de respuesta.

**Protocolo de timeout de plataforma:** En plataformas con timeout de respuesta corto (Discord ~2min, Slack ACK ~3s), el agente debe emitir un acknowledgment breve antes de cargar archivos de contexto. La lectura de archivos nunca debe bloquear el primer token de respuesta.

**Claiming de tareas:** Antes de empezar a trabajar en una tarea, el agente la reclama en tick.md:

```bash
tick claim TASK-001 @agent-name
```

Al completar una tarea:

```bash
tick done TASK-001 @agent-name
```

Ver TICK-INTEGRATION.md para el protocolo completo de coordinación.

**Checkpoints (heredado de v1):** El humano pide explícitamente "guarda el estado" y el agente actualiza STATUS.md + MEMORY.md. No requiere resetear contexto.

---

## Ciclo de vida

### Ciclo de vida del proyecto

Un proyecto se **descubre** cuando un miembro del equipo ejecuta:

> Discover project: [nombre]

El agente:
1. Crea `projects/[nombre]/PROJECT.md` usando el template de proyecto
2. Crea `projects/[nombre]/AGENTS.md` usando el template de agentes del proyecto
3. Ejecuta `tick init` dentro del directorio del proyecto
4. Registra al agente: `tick agent register @agent-name`
5. Abre un thread de comunicación para el proyecto
6. Hace las preguntas de descubrimiento (propietario, objetivo, criterios de éxito, condición de archivo)

Un proyecto se **archiva** cuando todos sus workstreams están archivados y se cumple la condición de archivo definida en PROJECT.md. El directorio se mueve a `projects/archived/`.

### Ciclo de vida del workstream

Un workstream **nace** cuando:
1. Un proyecto existe (o se crea)
2. Se agrega una tarea a TICK.md: `tick add "Nombre de tarea" --tag nombre-workstream`
3. Se abre un thread de comunicación (post en foro Discord o thread de Slack)
4. Se crea el directorio del workstream en `projects/[proyecto]/workstreams/` con los 6 archivos

**Sin tarea, no hay thread. Sin thread, no hay directorio.**

Un workstream **muere** cuando:
1. Todas las tareas del workstream se marcan como completadas en TICK.md
2. STATUS.md se actualiza con el estado final y learnings
3. El thread de comunicación se archiva
4. El directorio se mueve de `workstreams/` a `workstreams/archived/`

**Estados posibles:**

| Estado | Directorio | Thread de comunicación | Tareas |
|--------|-----------|----------------------|--------|
| Activo | `workstreams/` | Abierto | En curso |
| Pausado | `workstreams/` | Abierto | Bloqueado |
| Archivado | `workstreams/archived/` | Archivado | Completadas/Archivadas |

---

## Bootstrap de agentes

**Principio:** El agente carga solo el workstream del thread donde está operando — no todos.

**Mecanismo de resolución:**
- Cada thread de comunicación (Discord o Slack) mapea a exactamente un directorio de workstream
- El campo `thread_id` en BRIEF.md es la vinculación canónica
- La resolución es por coincidencia exacta únicamente — nunca por inferencia, similitud o heurística

**Orden de carga:**

1. Resolver workstream por `thread_id` exacto
2. Leer `projects/[proyecto]/AGENTS.md` (contexto a nivel proyecto, si existe)
3. Leer `BRIEF.md` (identidad del workstream)
4. Leer `STATUS.md` (estado actual)
5. Escalar a otros archivos solo cuando la tarea lo requiera

**Mapeo thread ↔ directorio:** El campo `thread_id` en BRIEF.md usa el formato `[plataforma]:[id]`:

```
thread_id: discord:123456789
```
```
thread_id: slack:C07ABC123/1234567890.123456
```

El agente escribe este campo al crear el directorio del workstream, usando el ID del thread de los metadatos de la plataforma. `thread_id` es obligatorio en cada BRIEF.md.

**Instrucciones del agente:** Cada framework de agente tiene su propio mecanismo para cargar instrucciones. Ver `adapters/` para la configuración específica de cada framework:

- **OpenClaw:** SKILL.md + bloque AGENTS.md → `adapters/openclaw/`
- **Hermes Agent:** Definición de skill → `adapters/hermes/`
- **Claude Code:** Instrucciones de proyecto CLAUDE.md → `adapters/claude-code/`
- **Otros agentes:** Setup manual → `adapters/generic/`

El contrato de instrucciones es el mismo sin importar el framework:

<!-- NOTE: This instruction block is kept in English because it is consumed by LLMs trained primarily on English text. -->

1. Read `WORKSTREAMS.md` at the start of any session in a workstream thread
2. Resolve the workstream by exact `thread_id`
3. Load project-level `AGENTS.md` (if it exists)
4. Read BRIEF.md → STATUS.md before doing any work
5. Escalate to other files only when the task requires it
6. Claim the task in tick.md before starting work
7. Update STATUS.md at the end of every working session

---

## Doctrina de recuperación

Si una sesión está degradada, inflada, reseteada o en mal estado:
- Reconstruir desde los archivos de workstream
- No confiar en la continuidad del transcript como fuente de verdad
- `BRIEF.md` y `STATUS.md` deben ser suficientes para reiniciar el workstream de manera segura
- Si se necesita más contexto, escalar a `MEMORY.md` y `DECISIONS.md`

---

## Doctrina de aislamiento

Por defecto:
- No leer archivos de otro workstream
- No buscar ampliamente entre proyectos
- No inferir a partir de nombres similares

La síntesis entre workstreams debe ser explícita y solicitada por el humano.

---

## Plataformas de comunicación

Los workstreams usan threads de comunicación como superficie de colaboración. El framework soporta múltiples plataformas — ver COMMUNICATION.md para la especificación completa.

**Resumen:**

| Plataforma | Contenedor | Superficie del workstream | Formato thread ID |
|------------|-----------|--------------------------|-------------------|
| Discord | Foro (`[área]-workstreams`) | Post en foro (thread) | `discord:[thread_id]` |
| Slack | Canal (`[área]-workstreams`) | Thread en canal | `slack:[channel_id]/[thread_ts]` |

**Convención de nombres:** `[área]-workstreams` — aplica tanto a foros de Discord como a canales de Slack. Ejemplos: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`.

**Mecanismo de contexto persistente:** El mensaje inicial del thread (post de foro en Discord o mensaje raíz de thread en Slack) es el ancla de contexto más confiable. Sobrevive la compactación de contexto y le dice al agente en qué workstream está operando. Mantenlo actualizado.

---

## Integración con tick.md

tick.md es la capa de gestión de tareas por defecto. TICK.md vive en la raíz del proyecto y contiene todas las tareas de ese proyecto. Ver TICK-INTEGRATION.md para la especificación completa.

**Referencia rápida:**

| Acción | Comando |
|--------|---------|
| Inicializar proyecto | `tick init` |
| Registrar agente | `tick agent register @agent-name` |
| Agregar tarea | `tick add "Nombre" --tag nombre-workstream --priority high` |
| Reclamar tarea | `tick claim TASK-001 @agent-name` |
| Completar tarea | `tick done TASK-001 @agent-name` |
| Ver estado del proyecto | `tick status` |
| Listar tareas del workstream | `tick list --tag nombre-workstream` |

---

## Cómo crear un nuevo proyecto

Usando el comando de descubrimiento:

> Discover project: [nombre]

O manualmente:

1. Crear el directorio del proyecto: `mkdir -p projects/[nombre-proyecto]`
2. Copiar el template de PROJECT.md: `cp [ruta-skill]/assets/templates/project/PROJECT.md projects/[nombre-proyecto]/`
3. Copiar el template de AGENTS.md: `cp [ruta-skill]/assets/templates/project/AGENTS.md projects/[nombre-proyecto]/`
4. Inicializar tick.md: `cd projects/[nombre-proyecto] && tick init`
5. Registrar el agente: `tick agent register @agent-name`
6. Llenar PROJECT.md con propietario, objetivo, alcance y condición de archivo
7. Llenar AGENTS.md con contexto a nivel proyecto (opcional — puede completarse incrementalmente)
8. El proyecto está listo para workstreams

## Cómo crear un nuevo workstream

1. Agregar una tarea en tick.md: `tick add "Descripción" --tag nombre-workstream`
2. Abrir un thread de comunicación (post en foro Discord o thread de Slack) en el canal `[área]-workstreams`
3. Crear el directorio del workstream con los 6 archivos:
   ```bash
   WS=nombre-workstream
   PROJECT=nombre-proyecto
   cp -r assets/templates/workstream/ projects/$PROJECT/workstreams/$WS/
   mkdir -p projects/$PROJECT/workstreams/$WS/docs
   ```
4. Llenar BRIEF.md con la identidad del workstream:
   - `thread_id` (obligatorio)
   - Nombres de `project` y `workstream`
   - Objetivo, problema, alcance, criterios de éxito, apetito
5. Enlazar el thread de comunicación y la tarea en RESOURCES.md

---

## Modelo de datos del workspace

El workspace de internOS contiene dos tipos de datos: **archivos del framework** (reemplazables, incluidos con el skill) y **datos del usuario** (irreemplazables, creados por humanos y agentes durante la operación).

### Archivos del framework (propiedad de internOS)

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `WORKSTREAMS.md` | Raíz del workspace | Guía de runtime para agentes — copiada de `assets/WORKSTREAMS.md` durante la instalación. Se reemplaza al actualizar. |

Estos archivos se pueden eliminar y recrear desde el repositorio de intern-os en cualquier momento.

### Datos del usuario (propiedad tuya)

| Archivo/Directorio | Ubicación | Descripción |
|---------------------|-----------|-------------|
| `projects/` | Raíz del workspace | Todos los directorios de proyectos |
| `PROJECT.md` | `projects/[nombre]/` | Identidad del proyecto — propósito, alcance, dirección |
| `AGENTS.md` | `projects/[nombre]/` | Contexto de agente a nivel proyecto |
| `TICK.md` + `.tick/` | `projects/[nombre]/` | Historial de tareas, asignaciones, registros de agentes |
| `workstreams/` | `projects/[nombre]/workstreams/` | Todos los directorios de workstreams |
| Archivos de workstream | `workstreams/[nombre]/` | BRIEF.md, STATUS.md, MEMORY.md, DECISIONS.md, STAKEHOLDERS.md, RESOURCES.md, docs/ |

**Estos datos son irreemplazables.** Contienen el contexto de tus proyectos, decisiones acumuladas, historial de tareas y memoria de workstreams. NO se almacenan en el repositorio o skill de intern-os — viven solo en tu workspace.

### Qué sobrevive una desinstalación

| Acción | ¿Sobrevive? |
|--------|-------------|
| Eliminar el skill de intern-os | Sí — todos los datos de proyectos permanecen |
| Eliminar WORKSTREAMS.md | Sí — se recrea desde el skill al reinstalar |
| Eliminar `projects/` | **No** — todos los datos de proyectos se pierden permanentemente |

### Respaldo

Para respaldar todos los datos de usuario de internOS:

```bash
tar -czf internos-backup-$(date +%Y%m%d).tar.gz -C [workspace] projects/
```

Para restaurar:

```bash
tar -xzf internos-backup-YYYYMMDD.tar.gz -C [workspace]
```

---

## Desinstalar internOS

Desinstalar remueve las instrucciones del framework de tu agente pero **preserva todos los datos de proyectos** por defecto.

### Paso 1: Eliminar el skill

Consulta el SETUP.md de tu adaptador para el comando específico:

| Framework | Comando |
|-----------|---------|
| Hermes Agent | `hermes skills uninstall intern-os` o `rm -rf ~/.hermes/skills/intern-os/` |
| OpenClaw | `openclaw skills uninstall intern-os` + eliminar bloque internOS de AGENTS.md |
| Claude Code | Eliminar la sección internOS de CLAUDE.md |
| Otro | Eliminar las instrucciones internOS del system prompt del agente |

### Paso 2: Eliminar la guía de runtime

```bash
rm [workspace]/WORKSTREAMS.md
```

### Paso 3: Reiniciar el agente (si es necesario)

La mayoría de los agentes leen skills desde disco por sesión — no necesitan reinicio. Solo reinicia si tu framework de agentes cachea skills en memoria o configuraste intern-os como skill precargado.

### Paso 4: (Opcional) Eliminar datos de proyectos

Solo haz esto si quieres eliminar permanentemente todos los datos de proyectos:

```bash
rm -rf [workspace]/projects/
```

> **Advertencia:** Esto elimina todos los directorios de proyectos, archivos de workstreams, historial de tareas y contexto acumulado. No se puede deshacer. Respalda primero si no estás seguro.

### Después de desinstalar

- El agente ya no seguirá los protocolos de internOS (carga de workstreams, actualizaciones de STATUS.md, claiming de tareas)
- Los threads de comunicación existentes (Slack, Discord) permanecen pero pierden su contexto de workstream
- Los archivos de tareas tick.md siguen siendo legibles con `tick status` / `tick list` incluso sin internOS

---

## Lo que este framework no es

- No reemplaza a tick.md ni ningún sistema de gestión de tareas — los complementa
- No es un sistema de tickets o sprints
- No requiere infraestructura más allá de un filesystem y Git

---

## Qué es validado por herramientas vs. qué es doctrina

internOS distingue entre reglas que son **validadas por herramientas incluidas** y reglas que son **doctrina para que los agentes sigan**. Ambas importan, pero tienen mecanismos de enforcement diferentes.

### Validado por `sync-check.sh`

Estos checks son ejecutados por el script de salud del workspace y producen advertencias:

| Check | Severidad |
|-------|-----------|
| `PROJECT.md` existe por proyecto | WARN |
| `TICK.md` existe por proyecto | WARN |
| Los 6 archivos de workstream están presentes | WARN |
| `thread_id` existe en BRIEF.md | WARN |
| Formato de `thread_id` es válido (`plataforma:id`) | WARN |
| `thread_id` de Slack incluye canal + thread_ts | WARN |
| No hay `thread_id` duplicados entre workstreams | WARN |
| Workstream tiene tag de tarea correspondiente en TICK.md | WARN |
| Tamaño de `STATUS.md` dentro del objetivo (≤10 líneas de contenido) | WARN |
| Tamaño de `MEMORY.md` dentro del límite (≤80 líneas) | WARN |

Estos se reportan como informativos (INFO), no como errores:

| Check | Severidad |
|-------|-----------|
| `AGENTS.md` existe por proyecto | INFO |
| BRIEF.md tiene campos `project`, `workstream`, `owner`, `created` | INFO |
| `MEMORY.md` acercándose al límite (>50 líneas) | INFO |

### Validado por `checkpoint-reminder.sh`

| Check | Severidad |
|-------|-----------|
| `STATUS.md` modificado dentro del umbral (por defecto 3 días) | STALE |

### Validado por `tick.md`

| Check | Mecanismo |
|-------|-----------|
| Coordinación de claim/release de tareas | Modelo de datos de tick.md — campo `claimed_by` |
| Registro de agentes | Registro de agentes de tick.md |
| Transiciones de estado de tareas | Reglas de workflow de tick.md |

### Doctrina (expectativas de comportamiento del agente)

Estas reglas están documentadas para que los agentes las sigan pero **no son mecánicamente impuestas** por herramientas. Dependen de que los agentes lean y respeten las instrucciones del framework:

- **Resolución exacta por `thread_id`** — los agentes deben resolver por match exacto, nunca por matching difuso o inferencia
- **Carga por tiers** — los agentes deben cargar BRIEF.md + STATUS.md por defecto y escalar bajo demanda
- **ACK-first en plataformas** — los agentes deben emitir acknowledgment antes de leer archivos en Discord/Slack
- **Curación de MEMORY.md** — los agentes deben consolidar cuando excede el umbral, manteniendo como resumen no log
- **Actualización de STATUS.md al fin de sesión** — los agentes deben actualizar STATUS.md después de cada sesión
- **Recuperación desde archivos** — los agentes deben reconstruir desde archivos de workstream cuando las sesiones se degradan
- **Aislamiento de workstreams** — los agentes no deben leer archivos de otros workstreams a menos que se solicite explícitamente
- **Carga de AGENTS.md** — los agentes deben cargar AGENTS.md a nivel proyecto antes de los archivos de workstream

Estas expectativas de comportamiento son el enfoque correcto para v0.3.0. Versiones futuras pueden agregar hooks, herramientas MCP o wrappers de runtime para imponer algunas de estas programáticamente — ver Roadmap.

---

## Roadmap

> v0.3.0 incluye el modelo simplificado de Proyecto + Workstream con arquitectura de tres capas. El trabajo futuro se enfoca en enforcement de runtime.

### v0.3.x — Enforcement de runtime

**Registro derivado de thread_id** — para búsqueda rápida sin escanear todos los archivos BRIEF.md.

**Hooks de mutación en bootstrap** — hooks compatibles con OpenClaw para carga automática de workstreams al entrar a un thread.

### v0.4.0 — Automatizaciones

**Scaffold automático al crear thread**
Webhook de plataforma detecta nuevo thread en un canal/foro `-workstreams` → crea automáticamente el directorio + 6 archivos y agrega la tarea en tick.md.

**Workflow de archivo**
Detecta todas las tareas de un workstream marcadas como done en tick.md → mueve el directorio a `workstreams/archived/` → archiva el thread de comunicación.

**Dashboard cross-project**
Agregador que lee todos los archivos `projects/*/TICK.md` y produce una vista unificada entre proyectos.

---

*Se itera a partir de los aprendizajes de cada workstream.*

---

## Referencias

- Guía de runtime para agentes: `WORKSTREAMS.md` (se copia a la raíz del workspace)
- Templates de workstream: `assets/templates/workstream/`
- Templates de proyecto: `assets/templates/project/` (incluye PROJECT.md y AGENTS.md)
- Adaptadores de agentes: `adapters/`
- Spec de comunicación: `references/en/COMMUNICATION.md`
- Integración tick.md: `references/en/TICK-INTEGRATION.md`
- Setup para nuevas instancias: `references/en/SETUP.md`
- Instructivo operacional: `references/en/PLAYBOOK.md`
