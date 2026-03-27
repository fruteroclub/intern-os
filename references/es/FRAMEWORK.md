# internOS — Framework del Sistema Operativo de Workstreams

*Versión: 1.0 | Fecha: 2026-03-24 | Estado: v1 — just ship*

---

## El sistema en una línea

Cada workstream del equipo existe en tres capas simultáneas. La coherencia entre capas elimina la fricción de coordinación.

---

## Las tres capas

| Capa | Herramienta | Rol |
|------|-------------|-----|
| **Gestión** | Sistema de tareas del equipo (tick.md, Notion, Trello, etc.) | Origen del workstream |
| **Comunicación** | Discord (threads en foros) | Superficie de trabajo del equipo — humanos y agentes |
| **Operación** | Filesystem (`active-workstreams/`) | Fuente de verdad para agentes — contexto persistente entre sesiones |

> **Capa de comunicación actual: Discord.** Otros canales (Slack, Telegram, WhatsApp, etc.) no están definidos para este sistema todavía.

**Sobre artefactos:** no existe un repositorio único. `docs/` dentro de cada workstream es uno de N posibles repositorios (Notion, Google Drive, S3, R2, etc.). `RESOURCES.md` es el índice que lleva la relación de todos los recursos y dónde viven.

---

## 1. Estructura de archivos

Cada workstream tiene un directorio espejo en el filesystem con 6 archivos estándar:

```
active-workstreams/
└── [nombre-workstream]/
    ├── BRIEF.md         ← Qué es, para quién, problema, apetito
    ├── STATUS.md        ← Fase, dónde estamos, próximo paso, bloqueadores
    ├── MEMORY.md        ← Contexto acumulado, insights, learnings
    ├── DECISIONS.md     ← Log de decisiones clave con fecha + razón
    ├── STAKEHOLDERS.md  ← Personas relevantes y su rol
    ├── RESOURCES.md     ← Inventario de artefactos y dónde viven
    └── docs/            ← Artefactos de trabajo
```

**Convención:** Todos los archivos markdown del sistema en MAYÚSCULAS.

---

## 2. Protocolo de escritura

**Quién escribe qué:**

| Actor | Escribe cuando... | Archivos |
|-------|-------------------|----------|
| **Agente** | Al final de una sesión de trabajo en el thread | STATUS.md, MEMORY.md, DECISIONS.md |
| **Humano** | Hay una decisión estratégica, cambio de dirección o info nueva | Cualquier archivo |
| **Ambos** | Al crear un workstream nuevo | BRIEF.md, STAKEHOLDERS.md, RESOURCES.md |

**Regla de oro:** Si el agente no puede responder "¿en qué está este workstream?" leyendo STATUS.md, el archivo está desactualizado.

**Checkpoints (v1):** El humano pide explícitamente "guarda el estado" y el agente actualiza STATUS.md + MEMORY.md. No requiere resetear contexto.

> **Roadmap:** Crear comando `/checkpoint` en OpenClaw que guarde el estado del workstream activo sin cerrar la sesión ni perder contexto del agente.

---

## 3. Ciclo de vida

Un workstream **nace** cuando:
1. Se crea una tarea en el sistema de gestión del equipo
2. Se abre un thread en el foro de Discord correspondiente
3. Se crea el directorio en `active-workstreams/` con los 6 archivos

**Sin tarea, no hay thread. Sin thread, no hay directorio.**

Un workstream **muere** cuando:
1. La tarea se marca como completada o archivada en el sistema de gestión
2. STATUS.md se actualiza con estado final y learnings
3. El thread de Discord se archiva
4. El directorio se mueve de `active-workstreams/` a `archived-workstreams/`

**Estados posibles:**

| Estado | Directorio | Thread Discord | Tarea |
|--------|-----------|----------------|-------|
| Activo | `active-workstreams/` | Abierto | En curso |
| Pausado | `active-workstreams/` | Abierto | Bloqueado |
| Archivado | `archived-workstreams/` | Archivado | Completado/Archivado |

---

## 4. Bootstrap de agentes

**Principio:** El agente carga solo el workstream del thread donde está operando — no todos.

**Mecanismo:**
- Cada thread de Discord tiene un ID único
- Ese ID mapea a un directorio específico en `active-workstreams/`
- Al entrar a un thread de workstream, el agente lee **solo** ese subdirectorio

**Lo que va en `AGENTS.md`:**
```
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a Discord thread that has a workstream context.

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Workstream directories live in: `active-workstreams/[workstream-name]/`
Read: BRIEF.md, STATUS.md, MEMORY.md before doing any work.

Before ending any working session, update STATUS.md with:
1. What was done this session
2. Next concrete step
3. Any blockers

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

**Mapeo thread ↔ directorio:** El campo `discord_thread_id` en BRIEF.md es el registro canónico. El agente lo escribe al crear el directorio usando el `topic_id` de los metadatos de Discord.

---

## 5. Foros de Discord por tipo de workstream

Los workstreams viven exclusivamente en foros, clasificados por el área responsable. Convención de nombres: `[área]-workstreams`.

Ejemplos: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`, `mkt-workstreams`.

Cada proyecto define sus propios foros según sus áreas activas.

---

## Cómo crear un workstream nuevo

1. Crear tarea en el sistema de gestión del equipo
2. Abrir thread en el foro de Discord correspondiente al área
3. Crear directorio en `active-workstreams/[nombre]/` con los 6 archivos
4. Llenar BRIEF.md usando las 6 preguntas:
   - ¿Qué trabajo específico es este? *(verbo + objeto)*
   - ¿Qué problema o situación lo gatilla?
   - ¿Quién lo necesita y para qué?
   - ¿Qué entrega al terminar? *(outcome, no output)*
   - ¿Qué está dentro y fuera del scope?
   - ¿Cuál es el apetito? *(tiempo o esfuerzo máximo)*
5. Enlazar el thread de Discord en RESOURCES.md
6. Enlazar la tarea del sistema de gestión en RESOURCES.md

---

## Lo que este framework no es

- No reemplaza el sistema de gestión de tareas del equipo
- No es un sistema de tickets o sprints
- No requiere herramientas adicionales para funcionar

---

## Roadmap

> Este framework está en desarrollo activo. v1 es completamente manual — las automatizaciones se implementarán a medida que el sistema esté probado en uso real.

### v1.1 — Automatizaciones de bajo esfuerzo

**Sync check** *(~1h)*
Script que compara threads activos en foros `-workstreams` de Discord vs directorios en `active-workstreams/`. Detecta desincronías: thread sin directorio, directorio sin thread.

**Checkpoint reminder** *(~1h)*
Cron job que verifica si `STATUS.md` fue actualizado durante una sesión de trabajo activa. Si no, el agente recibe un recordatorio. Evita que los workstreams queden desactualizados.

### v1.2 — Automatizaciones de esfuerzo medio

**Scaffold automático al crear thread** *(~3h)*
Webhook de Discord detecta nuevo post en un foro `-workstreams` → crea automáticamente el directorio + 6 archivos en `active-workstreams/`. Elimina el paso más repetitivo de la activación.

### v2.0 — Automatizaciones de alto esfuerzo

**Archive workflow** *(~6-8h)*
Detecta cambio de estado en el sistema de gestión de tareas → mueve el directorio a `archived-workstreams/` → archiva el thread de Discord. Requiere coordinación entre tres sistemas.

---

*Se itera a partir de los aprendizajes de cada workstream.*

---

## Referencias

- Guía operacional para agentes: `workspace/WORKSTREAMS.md`
- Directorio de workstreams: `workspace/active-workstreams/`
- Setup para nuevas instancias: `references/SETUP.md`
- Instructivo operacional: `references/PLAYBOOK.md`
