# PLAYBOOK — Operar Workstreams Día a Día

*internOS v2.1 | 2026-03-31*

Este instructivo explica cómo usar el sistema de Workstreams de internOS: cómo crear proyectos, activar workstreams, trabajar sesiones y gestionar el ciclo de vida.

---

> **Primera vez?** Antes de usar este playbook, configura la instancia siguiendo **SETUP.md**.

---

## Cómo activar un workstream

Cualquier persona del equipo puede activar un workstream desde cualquier thread de comunicación, hablando con cualquier agente. El agente se encarga de crear lo que falte: tarea en tick.md, thread de comunicación y directorio en el filesystem.

**Formato de activación (flexible):**

> Activate workstream: [nombre] in project: [proyecto]
> Task: [nombre o link de tarea] *(opcional si ya existe)*
> Thread: [canal/foro o thread] *(opcional si ya existe)*

O simplemente describe lo que quieres hacer y el agente pregunta lo que necesita.

---

## Puntos de entrada

El workstream se puede iniciar desde cualquiera de estas situaciones:

### Entrada A: Desde cero

No existe nada todavía. El agente crea todo en orden:
1. Tarea en tick.md: `tick add "Descripción" --tag nombre-workstream`
2. Thread de comunicación en el canal/foro `[área]-workstreams` correspondiente
3. Directorio en `projects/[proyecto]/workstreams/`
4. Solicita llenar el BRIEF con las 6 preguntas

### Entrada B: Tarea ya existe en tick.md

El agente:
1. Identifica la tarea existente
2. Crea el thread de comunicación
3. Crea el directorio del workstream
4. Enlaza todo en RESOURCES.md

### Entrada C: Thread de comunicación ya existe

El agente:
1. Lee el contexto del thread
2. Crea o enlaza la tarea en tick.md
3. Crea el directorio del workstream
4. Enlaza todo en RESOURCES.md

### Entrada D: Proyecto existe, agregando nuevo workstream

El agente:
1. Agrega tarea en el TICK.md del proyecto existente
2. Crea el thread de comunicación
3. Hace scaffold del directorio del workstream
4. Enlaza todo

### Entrada E: Proyecto nuevo (no existe ningún proyecto todavía)

El agente:
1. Crea `projects/[nombre]/PROJECT.md` usando el template de proyecto
2. Ejecuta `tick init` y registra al agente
3. Abre un thread de comunicación para el proyecto
4. Hace las 4 preguntas de descubrimiento (dominio, exclusiones, propietario, condición de archivo)
5. Una vez lleno el PROJECT.md, el proyecto está listo para workstreams

**Formato de activación:**

> Discover project: [nombre]

---

## Lo que el agente crea en cada paso

### 1. Tarea en tick.md

```bash
cd projects/[proyecto]
tick add "Descripción del workstream" --tag nombre-workstream --priority high
```

### 2. Thread de comunicación

El agente crea el thread en el canal/foro `[área]-workstreams` correspondiente con este formato:

<!-- NOTE: This template is kept in English as it is the agent-facing format consumed by LLMs. -->

```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: TASK-001 (or external URL)
Directory: projects/[project]/workstreams/[name]/
Status: [current phase — one line]
```

> **Contexto persistente:** este mensaje es el ancla de contexto para el agente. Mantenlo actualizado a medida que el workstream progresa. Ver COMMUNICATION.md para detalles específicos de cada plataforma.

### 3. Directorio del workstream

```bash
PROJECT=nombre-proyecto
WS=nombre-workstream

# Usando templates (recomendado)
cp -r [ruta-skill]/assets/templates/workstream/ projects/$PROJECT/workstreams/$WS/
mkdir -p projects/$PROJECT/workstreams/$WS/docs

# O manualmente
mkdir -p projects/$PROJECT/workstreams/$WS/docs
touch projects/$PROJECT/workstreams/$WS/{BRIEF.md,STATUS.md,MEMORY.md,DECISIONS.md,STAKEHOLDERS.md,RESOURCES.md}
```

### 4. BRIEF.md — 6 preguntas

El agente las hace una por una o el humano las responde en bloque:

1. ¿Qué trabajo específico es este? *(verbo + objeto)*
2. ¿Qué problema o situación lo gatilla?
3. ¿Quién lo necesita y para qué?
4. ¿Qué entrega al terminar? *(outcome, no output)*
5. ¿Qué está dentro del scope? ¿Qué está fuera?
6. ¿Cuál es el apetito? *(tiempo o esfuerzo máximo)*

Después de llenar, agregar el mapeo de thread:

```yaml
thread_id: [plataforma]:[id]
```

### 5. RESOURCES.md — links iniciales

```markdown
## Links

- **Task:** TASK-001 in TICK.md (or external URL)
- **Thread:** [platform]:[thread URL]
- **Directory:** projects/[project]/workstreams/[name]/
```

---

## Trabajar una sesión

Cuando un agente entra a un thread de workstream, sigue este protocolo:

### Protocolo de timeout de plataforma

En plataformas con timeout de respuesta corto (Discord ~2min, Slack ACK ~3s), el agente **debe emitir un acknowledgment breve ANTES de cargar archivos de contexto**. Una línea basta — "Cargando contexto..." o equivalente. Luego carga archivos y responde completo. La lectura de archivos nunca debe bloquear el primer token de respuesta.

### Inicio del trabajo

<!-- NOTE: These protocol steps are kept in English as they are consumed by LLMs. -->

1. Read `WORKSTREAMS.md` (agent runtime guide)
2. Identify the workstream from the thread context
3. Read the workstream files:
   - `BRIEF.md` — read in full
   - `STATUS.md` — read in full (must be ≤10 lines by design)
   - `MEMORY.md` — **last 80 lines only** (search on demand if more context needed)
4. Check current tasks: `tick list --tag [workstream-name]`
5. Claim the task to work on: `tick claim TASK-X @agent-name`

### Durante el trabajo

- Hacer el trabajo descrito en la tarea
- Agregar notas de progreso si es útil: `tick comment TASK-X @agent-name --note "Progreso"`

### Fin de sesión

1. **Completar la tarea** (si terminó): `tick done TASK-X @agent-name`
2. **O liberar** (si pausa): `tick release TASK-X @agent-name`
3. **Actualizar STATUS.md** con:
   - Qué se hizo esta sesión
   - Fase actual del workstream
   - Cualquier bloqueador
4. **Actualizar MEMORY.md** si hay nuevos insights o contexto que valga la pena preservar
5. **Si MEMORY.md excede 80 líneas**, consolidarlo — promover insights clave, archivar entradas obsoletas. MEMORY.md es un resumen curado, no un log de sesión. Los logs detallados van en `docs/`.

> Esto es obligatorio incluso si nada cambió. Un STATUS.md en blanco significa que el workstream es invisible para el siguiente agente o sesión.

---

## Clasificación de canales de comunicación

Los workstreams se crean en canales/foros dedicados, clasificados por el área responsable del workstream.

**Convención de nombres:** `[área]-workstreams` — aplica tanto a foros de Discord como a canales de Slack.

**Regla de clasificación:** el canal lo determina quién es responsable del workstream, no el tema.

**Regla de threads:** los workstreams viven en threads (posts de foro Discord o threads de Slack). Los mensajes regulares del canal son para interacción directa con el agente, no para workstreams.

> Cada proyecto define sus propios canales según sus áreas activas. Ver SETUP.md para guía de creación.

---

## Checklist de activación

- [ ] Tarea creada en tick.md y etiquetada con nombre del workstream
- [ ] Thread de comunicación creado en el canal/foro `[área]-workstreams` correcto
- [ ] Directorio en `projects/[proyecto]/workstreams/` con los 6 archivos
- [ ] BRIEF.md completado con 6 preguntas + thread_id
- [ ] RESOURCES.md con links a tarea y thread
- [ ] STATUS.md con estado inicial

✅ Workstream activo. El trabajo continúa en el thread de comunicación.

---

## Gestión del ciclo de vida

### Pausar un workstream

- Liberar cualquier tarea reclamada: `tick release TASK-X @agent-name`
- Actualizar STATUS.md con razón de pausa y bloqueador
- El thread de comunicación permanece abierto

### Reanudar un workstream

- Leer STATUS.md para contexto
- Verificar `tick list --tag [nombre-workstream]` para estado actual de tareas
- Reclamar la siguiente tarea y continuar

### Archivar un workstream

Cuando todas las tareas están completas:

1. Verificar que todas las tareas están done: `tick list --tag [nombre-workstream]` — todas deben estar en `done`
2. Actualizar STATUS.md con estado final y learnings
3. Archivar el thread de comunicación (Discord: archivar thread, Slack: dejar thread o anotar completado)
4. Mover el directorio:
   ```bash
   mv projects/[proyecto]/workstreams/[nombre] projects/[proyecto]/workstreams/archived/[nombre]
   ```
