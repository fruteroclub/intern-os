# TICK-INTEGRATION — tick.md como Capa de Gestión de Tareas

*internOS v0.3.0 | 2026-04-11*

tick.md es la capa de gestión de tareas por defecto para internOS. Este documento especifica cómo tick.md se integra con la jerarquía proyecto–workstream–tarea.

> tick.md es un protocolo y CLI para coordinar trabajo a través de archivos Markdown estructurados. Es markdown-native, git-native y requiere cero infraestructura. [Docs completos →](https://www.tick.md/docs)

---

## Resumen

- **Un TICK.md por proyecto.** El archivo vive en la raíz del proyecto: `projects/[nombre]/TICK.md`
- **Las tareas referencian workstreams via tags.** Una tarea con tag `feature-x` pertenece a `workstreams/feature-x/`
- **Un workstream puede tener 1 o N tareas.** Workstreams simples son una tarea. Complejos tienen muchas.
- **tick.md es dueño del estado de tareas.** STATUS.md es dueño de la salud a nivel workstream.
- **tick.md es dueño de la coordinación.** Claim/release, asignación de agentes, historial.

---

## Mapeo de jerarquía

```
proyecto/                    ← tick init aquí
├── TICK.md                  ← todas las tareas del proyecto
├── .tick/config.yml         ← configuración de tick-md
└── workstreams/
    ├── feature-x/           ← workstream
    │   ├── BRIEF.md
    │   └── STATUS.md        ← salud del workstream
    └── bug-fix-y/
        ├── BRIEF.md
        └── STATUS.md
```

En TICK.md, las tareas se enlazan a workstreams a través de tags:

```yaml
id: TASK-001
status: in_progress
priority: high
tags: [feature-x]
claimed_by: @duki
```

```yaml
id: TASK-002
status: todo
priority: medium
tags: [feature-x]
```

```yaml
id: TASK-003
status: in_progress
priority: high
tags: [bug-fix-y]
```

Para ver todas las tareas de un workstream: `tick list --tag feature-x`

---

## Flujo de trabajo del agente

### Setup (una vez por proyecto)

```bash
cd projects/[nombre-proyecto]
tick init
tick agent register @agent-name --type bot --role engineer
```

### Trabajando una sesión

<!-- NOTE: These numbered steps are kept in English as they are the agent-facing protocol. -->

1. **Enter the workstream thread** (Discord or Slack)
2. **Load workstream context:** read BRIEF.md → STATUS.md → MEMORY.md
3. **Identify the task:** `tick list --tag [workstream-name] --status in_progress`
4. **Claim the task:**
   ```bash
   tick claim TASK-001 @agent-name
   ```
5. **Do the work**
6. **Add progress notes:**
   ```bash
   tick comment TASK-001 @agent-name --note "Implemented JWT middleware, refresh tokens next"
   ```
7. **Complete the task (if done):**
   ```bash
   tick done TASK-001 @agent-name
   ```
8. **Update STATUS.md** with:
   - What was done this session
   - Current workstream phase
   - Any blockers
9. **Release the task (if not done):**
   ```bash
   tick release TASK-001 @agent-name
   ```

### Crear una nueva tarea para un workstream existente

```bash
tick add "Implementar rotación de refresh tokens" --tag feature-x --priority medium
```

### Crear un nuevo workstream

1. Agregar la primera tarea: `tick add "Tarea inicial" --tag nuevo-nombre-workstream`
2. Abrir el thread de comunicación
3. Crear scaffold del directorio del workstream (ver PLAYBOOK.md)

---

## Protocolo de coordinación

tick.md implementa un ciclo de claim/release para que solo un agente trabaje en una tarea a la vez:

1. **Verificar disponibilidad:** `claimed_by` debe ser null, todas las dependencias deben estar completas
2. **Claim:** `tick claim TASK-X @agent-name` — establece `claimed_by`, registra entrada en historial
3. **Trabajo:** El agente ejecuta la tarea
4. **Release o complete:** `tick release` (si pausa) o `tick done` (si termina)

Si un agente se desconecta sin hacer release:
- El humano hace release manualmente: `tick release TASK-X @agent-name`
- O otro agente con nivel de confianza adecuado sobreescribe el claim

### Dependencias

Las tareas pueden depender de otras:

```yaml
id: TASK-005
depends_on: [TASK-003, TASK-004]
```

tick.md previene reclamar una tarea cuyas dependencias no están completas.

---

## Estados de tareas

Estados del workflow por defecto de tick.md, mapeados al uso en internOS:

| Estado | Significado | Transiciona a |
|--------|------------|---------------|
| `backlog` | Identificada pero no priorizada | `todo` |
| `todo` | Lista para trabajar | `in_progress`, `backlog` |
| `in_progress` | Se está trabajando activamente | `review`, `blocked` |
| `review` | Trabajo completo, necesita revisión | `done`, `in_progress` |
| `blocked` | No puede avanzar | `todo`, `in_progress` |
| `done` | Completa | `reopened` |

---

## STATUS.md vs TICK.md

Estos dos archivos tienen propósitos diferentes y no deben duplicar información:

| Aspecto | STATUS.md (workstream) | TICK.md (tareas) |
|---------|----------------------|-----------------|
| **Qué rastrea** | Fase del workstream, dirección, bloqueadores | Estado individual de tareas, prioridad, asignación |
| **Granularidad** | Nivel workstream | Nivel tarea |
| **Actualizado por** | Agente al final de sesión | CLI de tick.md en cada acción |
| **Formato** | Markdown libre | YAML estructurado + markdown |
| **Historial** | Se sobreescribe cada sesión | Log de auditoría append-only |

**Ejemplo de STATUS.md** para un workstream con 3 tareas:

```markdown
## Status

Phase: Implementation — 2 of 3 tasks complete
Last session: 2026-03-30

## Current state

TASK-001 (JWT middleware) and TASK-002 (session storage) are done.
TASK-003 (refresh token rotation) is in progress — halfway through,
endpoint works but needs error handling.

## Blockers

None.

## Next

Finish TASK-003 error handling, then this workstream is ready for review.
```

---

## Configuración de tick.md para internOS

El template de proyecto incluye un preset de `.tick/config.yml` ajustado para internOS:

```yaml
git:
  auto_commit: true
  commit_prefix: "[tick]"
  push_on_sync: false

locking:
  enabled: true
  timeout: 300

agents:
  default_trust: trusted
  require_registration: true
```

Configuraciones clave:
- **auto_commit: true** — cada acción de tick crea un commit en git, manteniendo historial
- **default_trust: trusted** — agentes registrados pueden crear tareas, reclamar y actualizar estado
- **require_registration: true** — los agentes deben registrarse antes de interactuar con TICK.md

---

## Usar otros sistemas de tareas

Si el equipo usa Notion, Linear, Trello u otro sistema en lugar de tick.md:

- El sistema de tareas reemplaza a TICK.md como capa de gestión
- Las tareas se enlazan en RESOURCES.md en lugar de rastrearse localmente
- El agente no puede usar comandos `tick` — la gestión de tareas ocurre en el sistema externo
- Las reglas del ciclo de vida del workstream siguen aplicando (sin tarea → sin thread → sin directorio)
- STATUS.md cobra más importancia ya que es el único registro local del estado de tareas

tick.md es recomendado porque es markdown-native, git-native y amigable para agentes. Los sistemas externos requieren integración adicional (acceso API, autenticación) y rompen el principio de cero infraestructura.

---

## Referencia de comandos

| Acción | Comando |
|--------|---------|
| Inicializar proyecto | `tick init` |
| Registrar agente | `tick agent register @name --type bot --role engineer` |
| Agregar tarea | `tick add "Título" --tag ws-name --priority high` |
| Listar todas las tareas | `tick list` |
| Listar tareas del workstream | `tick list --tag ws-name` |
| Ver estado del proyecto | `tick status` |
| Reclamar tarea | `tick claim TASK-X @name` |
| Liberar tarea | `tick release TASK-X @name` |
| Completar tarea | `tick done TASK-X @name` |
| Agregar comentario | `tick comment TASK-X @name --note "Nota de progreso"` |
| Ver dependencias | `tick graph` |
| Validar archivo | `tick validate` |
| Sincronizar con git | `tick sync` |

> Referencia completa del CLI: [tick.md/docs/cli](https://www.tick.md/docs/cli)
