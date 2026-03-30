# SETUP — Configurar internOS en una instancia de OpenClaw

*internOS v1.0 | 2026-03-26*

Guía para el administrador o humano que configura una nueva instancia de OpenClaw para usar el Sistema Operativo de Workstreams.

> **Capa de comunicación actual: Discord.** Este setup asume Discord como superficie de comunicación. Otros canales (Slack, Telegram, WhatsApp, etc.) no están definidos para este sistema todavía.

---

## Prerequisitos

- OpenClaw instalado y corriendo en la instancia
- Acceso al workspace del agente (`~/.openclaw/workspace/` por defecto)
- Bot de Discord configurado en el servidor del proyecto
- Un sistema de gestión de tareas (ver opciones abajo)

---

## Paso 1: Agregar el bloque internOS a `AGENTS.md`

Abrir `~/workspace/AGENTS.md` y agregar esta sección:

```markdown
## internOS — Workstreams

If `WORKSTREAMS.md` exists in the workspace root, read it at the start
of any session in a Discord thread that has a workstream context.

Only load the workstream directory matching the active thread.
Do not load all workstreams — keep context clean.

Workstream directories live in: `workstreams/[workstream-name]/`
Read: BRIEF.md, STATUS.md, MEMORY.md before doing any work.

Before ending any working session, update STATUS.md with:
1. What was done this session
2. Next concrete step
3. Any blockers

This is required even if nothing changed. A blank STATUS.md means
the workstream is invisible to the next agent or session.
```

---

## Paso 2: Copiar `WORKSTREAMS.md` al workspace

El skill incluye el archivo listo para usar. Copiarlo al workspace root:

```bash
# Desde el directorio del skill instalado:
cp ~/.openclaw/skills/intern-os/assets/WORKSTREAMS.md ~/workspace/WORKSTREAMS.md
```

> Si el agente ya instaló el skill vía `openclaw skills install`, el archivo está en `~/.openclaw/skills/intern-os/assets/WORKSTREAMS.md`.

---

## Paso 3: Crear el directorio `workstreams/`

```bash
mkdir -p ~/workspace/workstreams/
```

---

## Paso 4: Crear los foros en Discord

Crear foros en el servidor de Discord del proyecto. Convención de nombres: `[área]-workstreams`.

Foros mínimos recomendados según el tamaño del equipo:

| Foro | Cuándo crearlo |
|------|---------------|
| `ops-workstreams` | Siempre — para sistemas internos y setup |
| `ceo-workstreams` | Si hay un CEO/fundador operando workstreams |
| `tech-workstreams` | Si hay desarrollo de producto |
| `[área]-workstreams` | Según las áreas activas del proyecto |

**Regla:** los workstreams viven exclusivamente en foros, nunca en canales de texto regular.

---

## Paso 5: Reiniciar la sesión del agente

Los cambios en `AGENTS.md` se aplican en la siguiente sesión. Reiniciar el agente o esperar a la próxima sesión para que tome efecto.

---

## Verificación

El setup está completo cuando:

- [ ] `AGENTS.md` tiene el bloque internOS
- [ ] `WORKSTREAMS.md` existe en el workspace root
- [ ] `workstreams/` existe en el workspace
- [ ] Al menos un foro `[área]-workstreams` existe en Discord
- [ ] El agente fue reiniciado

---

---

## Sistema de gestión de tareas

Cada workstream nace de una tarea. Elige el sistema que mejor se adapte al proyecto:

| Opción | Cuándo usarla |
|--------|--------------|
| **tick.md** ⭐ *recomendado* | Arranque rápido, equipos pequeños, agentes-first. Markdown + Git, zero infraestructura. [Docs](https://www.tick.md/docs) |
| **Notion** | Si el equipo ya usa Notion con un kanban de proyectos y tareas validado |
| **Trello / Asana / Linear** | Si el equipo ya tiene un kanban establecido |
| **To-do list simple** | Todoist u otro — funciona si el equipo es pequeño y los workstreams son pocos |

**Lo importante:** cualquier sistema funciona mientras permita crear una tarea con nombre, estado y responsable. El workstream no puede existir sin una tarea asociada.

---

## Siguiente paso

Con el setup completo, activar el primer workstream siguiendo el **PLAYBOOK.md**.
