# COMMUNICATION — Especificación Multi-Plataforma

*internOS v2.0 | 2026-03-30*

Cada workstream tiene un thread de comunicación. El thread es la superficie de colaboración donde humanos y agentes discuten, deciden y coordinan trabajo. El framework es agnóstico de plataforma — esta spec define el protocolo y sus implementaciones para Discord y Slack.

---

## Principios

1. **Un workstream, un thread.** Un workstream vive en una plataforma de comunicación a la vez.
2. **Interacción solo en threads.** Los agentes responden dentro del thread del workstream, nunca en la raíz del canal/foro.
3. **Mensaje inicial como ancla de contexto.** El primer mensaje del thread contiene metadatos del workstream y sobrevive la compactación de contexto — es la forma más confiable de que el agente sepa en qué workstream está operando.
4. **Mapeo agnóstico de plataforma.** El campo `thread_id` en BRIEF.md usa el formato `[plataforma]:[id]` para enlazar el thread con su directorio de workstream.

---

## Formato del mensaje inicial del thread

El primer mensaje en cada thread de workstream sigue este formato, sin importar la plataforma:

<!-- NOTE: This template is kept in English as it is the agent-facing format consumed by LLMs. -->

```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: [tick-md task ID or external URL]
Directory: projects/[project]/workstreams/[name]/
Status: [current phase — one line]
```

> Mantén este mensaje actualizado. Se inyecta en el contexto del agente en cada interacción y es el mecanismo principal de persistencia de contexto.

---

## Thread ID en BRIEF.md

Cada BRIEF.md de workstream contiene un campo `thread_id` que mapea el thread de comunicación al directorio del filesystem:

```yaml
thread_id: discord:123456789
```

```yaml
thread_id: slack:C07ABC123/1234567890.123456
```

Este es el mapeo canónico. Sin él, el enlace entre thread y directorio es implícito y frágil.

---

## Convención de nombres de canales

Tanto los foros de Discord como los canales de Slack usan la misma convención:

```
[área]-workstreams
```

Ejemplos: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`, `mkt-workstreams`.

**Regla de clasificación:** el canal/foro lo determina quién es responsable del workstream, no el tema. Un bug de frontend cuyo responsable es el tech lead va en `tech-workstreams`, no en un hipotético canal `bugs`.

Cada proyecto define sus propios canales según sus áreas activas.

---

## Especificación Discord

### Contenedor: Foros

Los workstreams viven exclusivamente en **foros** de Discord (no en canales de texto regulares). Cada foro se nombra `[área]-workstreams`.

### Superficie del workstream: Posts en foro

Cada workstream es un post en el foro (que crea un thread). El mensaje original del post sigue el formato del mensaje inicial descrito arriba.

### Thread ID

Los thread IDs de Discord son el `topic_id` numérico de los metadatos de Discord. Formato en BRIEF.md:

```yaml
thread_id: discord:1234567890123456789
```

### Mecanismo de contexto persistente

Discord inyecta el mensaje original del post en el foro en cada mensaje del thread, incluyendo durante la compactación de contexto. Esto significa que el agente siempre ve los metadatos del workstream sin necesidad de cargarlos explícitamente.

### Reglas

- Los workstreams viven exclusivamente en foros, nunca en canales de texto regulares
- Los canales de texto regulares son para interacción directa con el agente, no para workstreams
- Un post en foro = un workstream
- El agente responde dentro del thread, no como un nuevo post en el foro

---

## Especificación Slack

### Contenedor: Canales

Los workstreams viven en **canales** de Slack nombrados `[área]-workstreams`. Son canales regulares (no Slack Connect ni canales compartidos).

### Superficie del workstream: Threads

Cada workstream es un **thread** dentro del canal. El mensaje raíz del thread sigue el formato del mensaje inicial descrito arriba.

### Thread ID

Los thread IDs de Slack combinan el ID del canal y el timestamp del thread. Formato en BRIEF.md:

```yaml
thread_id: slack:C07ABC123/1234567890.123456
```

Donde `C07ABC123` es el ID del canal de Slack y `1234567890.123456` es el `thread_ts` (timestamp del mensaje raíz).

### Mecanismo de contexto persistente

El mensaje raíz del thread en Slack siempre es visible al hacer scroll hasta arriba del thread. Los agentes deben leerlo al entrar al thread para cargar el contexto del workstream. A diferencia de Discord, Slack no lo inyecta automáticamente — el agente debe cargarlo explícitamente.

### Modo thread-only

- El agente responde **solo dentro de threads**, nunca en la raíz del canal
- Los mensajes nuevos en la raíz del canal son para crear nuevos threads de workstream
- El agente no publica mensajes independientes en el canal

### Setup específico de Slack

El bot de Slack necesita:
- Permiso para leer y escribir mensajes en canales `-workstreams`
- Permiso para leer y responder en threads
- Configuración para operar en modo thread-only (específico del framework del agente — ver adapters/)

---

## Elegir plataforma

El framework no prescribe una plataforma. Los equipos eligen según lo que ya usan:

| Factor | Discord | Slack |
|--------|---------|-------|
| Mejor para | Equipos de desarrollo/comunidad, open-source | Equipos de negocio, empresas |
| Modelo foro/thread | Foros nativos con threading rico | Canales con threads |
| Persistencia de contexto | Automática (inyección de topic) | Manual (agente lee mensaje raíz) |
| Setup del bot | Bot de Discord con permisos de foro | App de Slack con permisos de canal |

Un equipo puede usar una plataforma o ambas (para diferentes proyectos). Cada workstream vive en exactamente una plataforma.

---

## Plataformas futuras

El protocolo está diseñado para extenderse a otras plataformas. Para agregar una nueva:

1. Definir el tipo de contenedor (equivalente a foros Discord o canales Slack)
2. Definir la superficie del workstream (equivalente a post en foro o thread)
3. Definir el formato de thread ID: `[plataforma]:[id]`
4. Definir el mecanismo de contexto persistente
5. Documentar cualquier configuración de modo thread-only
6. Agregar una entrada a la tabla de plataformas en FRAMEWORK.md

Candidatos: Telegram (topics en grupos), WhatsApp (grupos), Microsoft Teams (canales + threads).
