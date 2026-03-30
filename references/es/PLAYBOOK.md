# PLAYBOOK — Sistema Operativo de Workstreams

*internOS v1.0 | 2026-03-24*

Este instructivo explica cómo usar el Sistema Operativo de Workstreams de internOS: cómo activar y operar un workstream día a día.

> **Capa de comunicación actual: Discord.** El mecanismo de contexto persistente descrito en este playbook (thread starter como ancla de contexto) aplica actualmente a Discord. Otros canales (Slack, Telegram, WhatsApp, etc.) no están definidos ni configurados para este sistema todavía.

---

> **Primera vez?** Antes de usar este playbook, configura la instancia siguiendo **SETUP.md**.

---

## Cómo activar un workstream

Cualquier persona del equipo puede activar un workstream desde cualquier canal de Discord, hablando con cualquier agente. El agente se encarga de crear lo que falte: tarea en el sistema de gestión, post en Discord, y directorio en filesystem.

**Formato de activación (libre):**

> Activa workstream: [nombre]
> Tarea: [nombre o link de la tarea] *(opcional si ya existe)*
> Discord: [foro o thread] *(opcional si ya existe)*

O simplemente describe lo que quieres hacer y el agente pregunta lo que necesita.

---

## Tres puntos de entrada

El workstream se puede iniciar desde cualquiera de estas situaciones:

### Entrada A: Desde cero

No existe nada todavía. El agente crea todo en orden:
1. Tarea en el sistema de gestión del equipo
2. Post en el foro de Discord correspondiente
3. Directorio en `workstreams/`
4. Solicita llenar el BRIEF con las 6 preguntas

### Entrada B: Tarea ya existe

El agente:
1. Pide el link o nombre de la tarea
2. Crea el post en el foro de Discord correspondiente
3. Crea el directorio en `workstreams/`
4. Enlaza todo en RESOURCES.md

### Entrada C: Post en Discord ya existe

El agente:
1. Pide el link o nombre del post de Discord
2. Crea o vincula la tarea en el sistema de gestión si no existe
3. Crea el directorio en `workstreams/`
4. Enlaza todo en RESOURCES.md

---

## Clasificación de foros en Discord

Los workstreams de Discord se crean **exclusivamente en foros**, clasificados por el área responsable del workstream. Convención de nombres: `[área]-workstreams`.

**Regla de clasificación:** el foro lo determina quién es responsable del workstream, no el tema.

**Regla de canal:** ningún workstream vive en canales de texto regular. Esos canales son para interacción directa con el agente, no para workstreams.

> Cada proyecto define sus propios foros según sus áreas activas. Ver SETUP.md para guía de creación.

---

## Lo que el agente crea en cada paso

### 1. Tarea en el sistema de gestión

Crear una tarea en el sistema que use el equipo.

Campos mínimos: **Nombre**, **Estado** (en curso), **Responsable**, **Descripción de una línea**

> tick.md es la opción recomendada para arranque rápido — Markdown + Git, sin infraestructura adicional. Ver [tick.md/docs](https://www.tick.md/docs)

### 2. Post en Discord

El agente crea el post en el foro correspondiente con este formato:

```
**[Nombre del workstream]**

Qué es: [una línea]
Responsable: [nombre]
Tarea: [URL o referencia en el sistema de gestión]
Directorio: workstreams/[nombre-kebab]/
Status: [fase actual — una línea]
```

> **Mecanismo de contexto persistente (Discord):** el post original del thread se inyecta en cada mensaje del canal, incluyendo durante compactación de contexto. Es la forma más confiable de que el agente siempre sepa en qué workstream está y dónde leer más. Este mecanismo aplica actualmente solo a Discord.

### 3. Directorio en filesystem

```bash
WS=nombre-workstream

mkdir -p ~/workspace/workstreams/$WS/docs
touch ~/workspace/workstreams/$WS/BRIEF.md
touch ~/workspace/workstreams/$WS/STATUS.md
touch ~/workspace/workstreams/$WS/MEMORY.md
touch ~/workspace/workstreams/$WS/DECISIONS.md
touch ~/workspace/workstreams/$WS/STAKEHOLDERS.md
touch ~/workspace/workstreams/$WS/RESOURCES.md
```

### 4. BRIEF.md — 6 preguntas

El agente las hace una por una o el humano las responde en bloque:

1. ¿Qué trabajo específico es este? *(verbo + objeto)*
2. ¿Qué problema o situación lo gatilla?
3. ¿Quién lo necesita y para qué?
4. ¿Qué entrega al terminar? *(outcome, no output)*
5. ¿Qué está dentro del scope? ¿Qué está fuera?
6. ¿Cuál es el apetito? *(tiempo o esfuerzo máximo)*

### 5. RESOURCES.md — links iniciales

```markdown
## Links

- **Tarea:** [URL o referencia en el sistema de gestión]
- **Discord:** [URL del post]
- **Directorio:** workstreams/[nombre]/
```

---

## Checklist de activación completa

- [ ] Tarea creada en el sistema de gestión y vinculada
- [ ] Post en el foro correcto de Discord creado
- [ ] Directorio en `workstreams/` con los 6 archivos
- [ ] BRIEF.md completado
- [ ] RESOURCES.md con links a tarea y Discord
- [ ] STATUS.md con estado inicial

✅ Workstream activo. El trabajo continúa en el post de Discord.
