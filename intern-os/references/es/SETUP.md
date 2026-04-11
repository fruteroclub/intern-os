# SETUP — Configurar internOS en una Instancia de Agente

*internOS v0.3.0 | 2026-04-11*

Guía para el administrador o humano que configura una instancia de agente para usar el framework internOS Workstreams.

---

## Prerequisitos

- Un framework de agente AI instalado y corriendo (OpenClaw, Hermes Agent, Claude Code u otro)
- Acceso al directorio workspace del agente
- Una plataforma de comunicación configurada (Discord o Slack — ver COMMUNICATION.md)
- Node.js instalado (para el CLI de tick.md)

---

## Paso 1: Instalar tick.md

```bash
npm install -g tick-md
tick --version
```

O usar sin instalación global:

```bash
npx tick-md --version
```

---

## Paso 2: Configurar el framework de agente

Cada framework de agente tiene su propio mecanismo de setup. Sigue la guía de tu framework:

| Framework | Adaptador | Guía de setup |
|-----------|-----------|---------------|
| OpenClaw | `adapters/openclaw/` | `adapters/openclaw/SETUP.md` |
| Hermes Agent | `adapters/hermes/` | `adapters/hermes/SETUP.md` |
| Claude Code | `adapters/claude-code/` | `adapters/claude-code/SETUP.md` |
| Otro | `adapters/generic/` | `adapters/generic/SETUP.md` |

Este paso configura al agente para leer `WORKSTREAMS.md` y seguir el protocolo de internOS.

---

## Paso 3: Copiar `WORKSTREAMS.md` al workspace

Copiar la guía operacional del agente a la raíz del workspace:

```bash
cp [ruta-skill]/assets/WORKSTREAMS.md [workspace]/WORKSTREAMS.md
```

Las rutas exactas dependen de tu framework de agente — ver la guía de setup del adaptador.

---

## Paso 4: Crear el directorio `projects/`

```bash
mkdir -p [workspace]/projects/
```

---

## Paso 5: Crear tu primer proyecto

```bash
PROJECT=mi-proyecto
mkdir -p [workspace]/projects/$PROJECT
cd [workspace]/projects/$PROJECT

# Inicializar tick.md
tick init

# Registrar el agente
tick agent register @agent-name --type bot --role engineer
```

O usar el template de proyecto (incluye TICK.md y .tick/config.yml pre-configurados):

```bash
PROJECT=mi-proyecto
cp -r [ruta-skill]/assets/templates/project/ [workspace]/projects/$PROJECT
cd [workspace]/projects/$PROJECT
tick agent register @agent-name --type bot --role engineer
```

---

## Paso 6: Configurar canales de comunicación

Crear canales o foros para las áreas de workstream. Ver COMMUNICATION.md para la especificación completa.

### Discord

Crear foros en el servidor de Discord del proyecto. Convención de nombres: `[área]-workstreams`.

| Foro | Cuándo crearlo |
|------|---------------|
| `ops-workstreams` | Siempre — para sistemas internos y setup |
| `ceo-workstreams` | Si hay un CEO/fundador operando workstreams |
| `tech-workstreams` | Si hay desarrollo de producto |
| `[área]-workstreams` | Según las áreas activas del proyecto |

**Regla:** los workstreams viven exclusivamente en foros, nunca en canales de texto regulares.

### Slack

Crear canales en el workspace de Slack del proyecto. Misma convención: `[área]-workstreams`.

| Canal | Cuándo crearlo |
|-------|---------------|
| `ops-workstreams` | Siempre — para sistemas internos y setup |
| `ceo-workstreams` | Si hay un CEO/fundador operando workstreams |
| `tech-workstreams` | Si hay desarrollo de producto |
| `[área]-workstreams` | Según las áreas activas del proyecto |

**Regla:** los workstreams usan threads dentro de estos canales. La raíz del canal es solo para crear nuevos threads de workstream.

---

## Paso 7: Reiniciar la sesión del agente

Los cambios en las instrucciones del agente toman efecto en la siguiente sesión. Reiniciar el agente o esperar a la próxima sesión.

---

## Verificación

El setup está completo cuando:

- [ ] CLI de tick.md instalado y funcionando
- [ ] Framework de agente configurado con instrucciones de internOS (via adaptador)
- [ ] `WORKSTREAMS.md` existe en la raíz del workspace
- [ ] Directorio `projects/` existe
- [ ] Al menos un proyecto inicializado con `tick init`
- [ ] Agente registrado en tick.md: `tick agent list`
- [ ] Al menos un canal/foro `[área]-workstreams` existe
- [ ] Agente reiniciado

---

## Sistema de gestión de tareas

tick.md es el sistema de tareas por defecto y recomendado para internOS. Está profundamente integrado en el framework — el template de proyecto, el flujo de trabajo del agente y el protocolo de coordinación están construidos alrededor de él.

| Opción | Cuándo usarla |
|--------|--------------|
| **tick.md** ⭐ *por defecto* | Agent-first, markdown + Git, zero infraestructura. [Docs](https://www.tick.md/docs) |
| **Notion** | Si el equipo ya usa Notion con un kanban de proyectos y tareas validado |
| **Trello / Asana / Linear** | Si el equipo ya tiene un kanban establecido |
| **To-do list simple** | Todoist u otro — funciona si el equipo es pequeño y los workstreams son pocos |

Si se usa un sistema diferente a tick.md, el sistema de tareas provee la capa de gestión pero el agente no puede usar comandos `tick`. Ver TICK-INTEGRATION.md para detalles de lo que cambia.

---

## Siguiente paso

Con el setup completo, activar el primer workstream siguiendo **PLAYBOOK.md**.
