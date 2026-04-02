# internOS — Framework del Sistema Operativo de Workstreams

*Versión: 2.1 | Fecha: 2026-03-31 | Estado: v2.1 — descubrimiento de proyectos, tick-md, multi-plataforma*

---

## El sistema en una línea

Cada proyecto organiza el trabajo en cuatro capas sincronizadas. La coherencia entre capas elimina la fricción de coordinación.

---

## Las cuatro capas

| Capa | Herramienta | Rol |
|------|-------------|-----|
| **Proyecto** | Filesystem (`projects/[nombre]/`) + `PROJECT.md` | Contenedor organizacional — dominio, propietario, límites, workstreams |
| **Gestión** | tick.md (`TICK.md` en la raíz del proyecto) | Origen de tareas — qué hay que hacer, quién lo hace |
| **Comunicación** | Foros Discord · Threads Slack | Superficie de trabajo del equipo — humanos y agentes |
| **Operación** | Filesystem (`projects/[nombre]/workstreams/`) | Fuente de verdad para agentes — contexto persistente entre sesiones |

> tick.md es la capa de gestión de tareas por defecto. Otros sistemas (Notion, Linear, Trello, etc.) pueden usarse en su lugar — ver la sección de gestión de tareas en SETUP.md.

**Sobre artefactos:** no existe un repositorio único. `docs/` dentro de cada workstream es uno de N posibles repositorios (Notion, Google Drive, S3, R2, etc.). `RESOURCES.md` es el índice que lleva la relación de todos los recursos y dónde viven.

---

## 1. Estructura de proyecto

Cada proyecto es un directorio auto-contenido con un `PROJECT.md` (brief del proyecto), un archivo de tareas tick.md y un directorio `workstreams/`:

```
projects/
├── project-alpha/
│   ├── PROJECT.md           ← Brief del proyecto: dominio, propietario, límites
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
    ├── TICK.md
    ├── .tick/
    └── workstreams/
```

### Estructura de archivos por workstream

Cada workstream tiene un directorio con 6 archivos estándar:

```
workstreams/[nombre]/
├── BRIEF.md         ← Qué es, para quién, problema, apetito
├── STATUS.md        ← Fase del workstream, dónde estamos, bloqueadores
├── MEMORY.md        ← Contexto acumulado, insights, learnings
├── DECISIONS.md     ← Log de decisiones clave con fecha + razón
├── STAKEHOLDERS.md  ← Personas relevantes y su rol
├── RESOURCES.md     ← Inventario de artefactos y dónde viven
└── docs/            ← Artefactos de trabajo
```

**Convención:** Todos los archivos markdown del sistema en MAYÚSCULAS.

---

## 2. Relación tarea–workstream

Las tareas viven en `TICK.md` en la raíz del proyecto. Los workstreams viven en `workstreams/`. Se conectan mediante tags:

- Cada tarea en TICK.md se etiqueta con el nombre del workstream (ej. `tags: [feature-x]`)
- Un workstream puede tener **1 o N tareas** — algunos son una sola tarea, otros tienen muchas
- `tick list --tag feature-x` muestra todas las tareas de ese workstream
- `tick status` muestra todas las tareas del proyecto

**STATUS.md es la salud a nivel workstream** — progreso agregado, dirección, bloqueadores. No rastrea el estado de tareas individuales. tick.md es dueño del estado de tareas.

**TICK.md es la fuente de verdad a nivel tarea** — estado, prioridad, asignación, claim/release, historial. No describe el propósito o contexto del workstream. Los archivos de workstream de intern-os son dueños de eso.

---

## 3. Protocolo de escritura

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
| STATUS.md | Leer completo | ≤10 líneas — fase, última sesión, bloqueadores, siguiente paso |
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

## 4. Ciclo de vida

### Ciclo de vida del proyecto

Un proyecto se **descubre** cuando un miembro del equipo ejecuta:

> Discover project: [nombre]

El agente:
1. Crea `projects/[nombre]/PROJECT.md` usando el template de proyecto
2. Ejecuta `tick init` dentro del directorio del proyecto
3. Registra al agente: `tick agent register @agent-name`
4. Abre un thread de comunicación para el proyecto
5. Hace las 4 preguntas de descubrimiento (dominio, exclusiones, propietario, condición de archivo)

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

## 5. Bootstrap de agentes

**Principio:** El agente carga solo el workstream del thread donde está operando — no todos.

**Mecanismo:**
- Cada thread de comunicación (Discord o Slack) mapea a un directorio de workstream
- El campo `thread_id` en BRIEF.md es el mapeo canónico
- Al entrar a un thread de workstream, el agente lee **solo** el directorio de ese workstream

**Mapeo thread ↔ directorio:** El campo `thread_id` en BRIEF.md usa el formato `[plataforma]:[id]`:

```
thread_id: discord:123456789
```
```
thread_id: slack:C07ABC123/1234567890.123456
```

El agente escribe este campo al crear el directorio del workstream, usando el ID del thread de los metadatos de la plataforma.

**Instrucciones del agente:** Cada framework de agente tiene su propio mecanismo para cargar instrucciones. Ver `adapters/` para la configuración específica de cada framework:

- **OpenClaw:** SKILL.md + bloque AGENTS.md → `adapters/openclaw/`
- **Hermes Agent:** Definición de skill → `adapters/hermes/`
- **Claude Code:** Instrucciones de proyecto CLAUDE.md → `adapters/claude-code/`
- **Otros agentes:** Setup manual → `adapters/generic/`

El contrato de instrucciones es el mismo sin importar el framework:

<!-- NOTE: This instruction block is kept in English because it is consumed by LLMs trained primarily on English text. -->

1. Read `WORKSTREAMS.md` at the start of any session in a workstream thread
2. Load only the workstream directory matching the active thread
3. Read BRIEF.md → STATUS.md → MEMORY.md before doing any work
4. Claim the task in tick.md before starting work
5. Update STATUS.md at the end of every working session

---

## 6. Plataformas de comunicación

Los workstreams usan threads de comunicación como superficie de colaboración. El framework soporta múltiples plataformas — ver COMMUNICATION.md para la especificación completa.

**Resumen:**

| Plataforma | Contenedor | Superficie del workstream | Formato thread ID |
|------------|-----------|--------------------------|-------------------|
| Discord | Foro (`[área]-workstreams`) | Post en foro (thread) | `discord:[thread_id]` |
| Slack | Canal (`[área]-workstreams`) | Thread en canal | `slack:[channel_id]/[thread_ts]` |

**Convención de nombres:** `[área]-workstreams` — aplica tanto a foros de Discord como a canales de Slack. Ejemplos: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`.

**Mecanismo de contexto persistente:** El mensaje inicial del thread (post de foro en Discord o mensaje raíz de thread en Slack) es el ancla de contexto más confiable. Sobrevive la compactación de contexto y le dice al agente en qué workstream está operando. Mantenlo actualizado.

---

## 7. Integración con tick.md

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
3. Inicializar tick.md: `cd projects/[nombre-proyecto] && tick init`
4. Registrar el agente: `tick agent register @agent-name`
5. Llenar PROJECT.md con dominio, propietario, límites y condición de archivo
6. El proyecto está listo para workstreams

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
4. Llenar BRIEF.md usando las 6 preguntas:
   - ¿Qué trabajo específico es este? *(verbo + objeto)*
   - ¿Qué problema o situación lo gatilla?
   - ¿Quién lo necesita y para qué?
   - ¿Qué entrega al terminar? *(outcome, no output)*
   - ¿Qué está dentro del scope? ¿Qué está fuera?
   - ¿Cuál es el apetito? *(tiempo o esfuerzo máximo)*
5. Agregar thread_id a BRIEF.md: `thread_id: [plataforma]:[id]`
6. Enlazar el thread de comunicación y la tarea en RESOURCES.md

---

## 8. Modelo de datos del workspace

El workspace de internOS contiene dos tipos de datos: **archivos del framework** (reemplazables, incluidos con el skill) y **datos del usuario** (irreemplazables, creados por humanos y agentes durante la operación).

### Archivos del framework (propiedad de internOS)

| Archivo | Ubicación | Descripción |
|---------|-----------|-------------|
| `WORKSTREAMS.md` | Raíz del workspace | Guía operacional para agentes — copiada de `assets/WORKSTREAMS.md` durante la instalación. Se reemplaza al actualizar. |

Estos archivos se pueden eliminar y recrear desde el repositorio de intern-os en cualquier momento.

### Datos del usuario (propiedad tuya)

| Archivo/Directorio | Ubicación | Descripción |
|---------------------|-----------|-------------|
| `projects/` | Raíz del workspace | Todos los directorios de proyectos |
| `PROJECT.md` | `projects/[nombre]/` | Identidad del proyecto — dominio, propietario, límites |
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

## 9. Desinstalar internOS

Desinstalar remueve las instrucciones del framework de tu agente pero **preserva todos los datos de proyectos** por defecto.

### Paso 1: Eliminar el skill

Consulta el SETUP.md de tu adaptador para el comando específico:

| Framework | Comando |
|-----------|---------|
| Hermes Agent | `hermes skills uninstall intern-os` o `rm -rf ~/.hermes/skills/intern-os/` |
| OpenClaw | `openclaw skills uninstall intern-os` + eliminar bloque internOS de AGENTS.md |
| Claude Code | Eliminar la sección internOS de CLAUDE.md |
| Otro | Eliminar las instrucciones internOS del system prompt del agente |

### Paso 2: Eliminar la guía operacional

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

## Roadmap

> v2 incluye proyectos, integración con tick.md y comunicación multi-plataforma. Las automatizaciones se implementarán a medida que el sistema esté probado en uso real.

### v2.1 — Automatizaciones de bajo esfuerzo

**Sync check** *(hecho — v2.1.0)*
`scripts/sync-check.sh` — escanea un workspace y reporta thread_ids faltantes, IDs de Slack incompletos, archivos faltantes y directorios huérfanos sin tareas en tick.md. Uso: `bash sync-check.sh <ruta-workspace>`

**Checkpoint reminder** *(hecho — v2.1.0)*
`scripts/checkpoint-reminder.sh` — detecta workstreams activos con STATUS.md desactualizado. Umbral configurable (por defecto 3 días). Uso: `bash checkpoint-reminder.sh <ruta-workspace> [días]`

### v2.2 — Automatizaciones de esfuerzo medio

**Scaffold automático al crear thread** *(~3h)*
Webhook de plataforma detecta nuevo thread en un canal `-workstreams` → crea automáticamente el directorio + 6 archivos y agrega la tarea en tick.md.

### v3.0 — Automatizaciones de alto esfuerzo

**Archive workflow** *(~6-8h)*
Detecta todas las tareas de un workstream marcadas como done en tick.md → mueve el directorio a `workstreams/archived/` → archiva el thread de comunicación.

**Dashboard cross-project** *(~4h)*
Agregador que lee todos los archivos `projects/*/TICK.md` y produce una vista unificada entre proyectos.

---

*Se itera a partir de los aprendizajes de cada workstream.*

---

## Referencias

- Guía operacional para agentes: `WORKSTREAMS.md` (se copia a la raíz del workspace)
- Templates de workstream: `assets/templates/workstream/`
- Template de proyecto: `assets/templates/project/`
- Adaptadores de agentes: `adapters/`
- Spec de comunicación: `references/en/COMMUNICATION.md`
- Integración tick.md: `references/en/TICK-INTEGRATION.md`
- Setup para nuevas instancias: `references/es/SETUP.md`
- Instructivo operacional: `references/es/PLAYBOOK.md`
