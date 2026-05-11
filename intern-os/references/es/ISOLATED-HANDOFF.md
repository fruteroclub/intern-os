# Handoff de Sesión Aislada

Doctrina de handoff de internOS para operación multi-agente. Úsalo cuando un coordinador delega trabajo a un especialista aislado (subagente) que no hereda el transcript del padre ni el binding del workstream.

Spec: [`docs/specs/v0.4.0-isolated-handoff.md`](../../../docs/specs/v0.4.0-isolated-handoff.md)
Schema: [`intern-os/schemas/handoff-v1.yaml`](../../schemas/handoff-v1.yaml)
Verificador: [`intern-os/scripts/verify-handoff.sh`](../../scripts/verify-handoff.sh)

---

## Qué problema resuelve

internOS funciona bien para un agente coordinador único operando dentro de un thread: el agente resuelve el workstream por `thread_id` exacto desde `BRIEF.md`, carga contexto mínimo, y reconstruye desde archivos cuando las sesiones se degradan.

Falla cuando el coordinador delega a un **especialista aislado** — una sesión nueva de subagente (Hermes `delegate_task`, OpenClaw `sessions_spawn`, Claude Code `Agent` tool). El especialista tiene acceso al filesystem pero ningún binding heredado. Sin handoff explícito, el especialista puede:

- operar desde contexto genérico en lugar del workstream activo
- fallar al cargar los archivos correctos
- escanear amplio el workspace
- producir trabajo direccionalmente correcto pero operacionalmente desconectado

La capa de handoff lo arregla pasando al especialista un **manifest determinístico, respaldado por archivos** que nombra exactamente qué cargar, qué hacer, y dónde escribir de vuelta.

---

## Las cuatro invariantes

### 1. Resolución determinística

El especialista verifica el binding antes de actuar. La verificación es coincidencia exacta:

- `workstream_path` existe en disco
- `BRIEF.md` existe en `<workstream_path>/BRIEF.md`
- `thread_id` del `BRIEF.md` coincide con el `thread_id` del manifest tras quitar whitespace circundante de la línea en BRIEF.md (incl. CR final si BRIEF.md fue creado en Windows). Igualdad de strings en todo lo demás — sin case folding, sin normalización Unicode, sin matching difuso.
- Cada path en `load.required` existe

Cualquier fallo: detenerse, retornar `status: aborted-binding-mismatch` con el nombre del check fallido. Sin fallback, sin matching difuso, sin "proyecto más cercano."

### 2. Aislamiento explícito

El especialista lee solo archivos en `load.required` (y opcionalmente `load.optional` si la tarea lo amerita). No lee workstreams hermanos, no escanea amplio el workspace, no infiere archivos relacionados por proximidad de nombres.

El aislamiento del filesystem es **doctrinal, no impuesto por SO.** Cada adaptador de harness documenta el sandboxing adicional que puede proveer.

### 3. Los archivos son la fuente de verdad

El manifest **apunta a** archivos; no incrusta su contenido. Los especialistas leen `BRIEF.md` y `STATUS.md` desde disco después de verificar el binding, nunca desde el manifest.

La salida del especialista también es un archivo: el **artefacto de retorno** en `<workstream_path>/handoffs/<handoff_id>.md`. El retorno de texto libre al coordinador es un resumen de una línea más la ruta del artefacto.

### 4. Separación de roles

Los especialistas están confinados a estas rutas de escritura:

- `<workstream_path>/handoffs/<handoff_id>.md` (artefacto de retorno — requerido)
- `<workstream_path>/handoffs/<handoff_id>/*` (sub-artefactos opcionales)
- `<workstream_path>/MEMORY.md` (append-only, acotado por `write_back.also_append`)

Los especialistas **no** deben escribir a `BRIEF.md`, `STATUS.md`, `DECISIONS.md`, ni ningún archivo fuera del workstream. La reconciliación de vuelta a `STATUS.md` / `DECISIONS.md` es trabajo del **coordinador** después de leer el artefacto de retorno.

---

## Schema del manifest v1

El schema vive en [`intern-os/schemas/handoff-v1.yaml`](../../schemas/handoff-v1.yaml). Template en [`intern-os/assets/templates/handoff/manifest.yml`](../../assets/templates/handoff/manifest.yml).

Campos requeridos:

| Campo | Propósito |
|---|---|
| `internos_handoff` | versión literal del schema (`v1`) |
| `handoff_id` | único dentro del workstream; convención fechada |
| `project`, `workstream`, `workstream_path`, `thread_id` | identidad — el especialista verifica las cuatro |
| `load.required` | archivos que el especialista debe leer (mínimo: `BRIEF.md`, `STATUS.md`) |
| `task.objective`, `task.success_condition`, `task.stop_condition` | qué / cuándo-listo / cuándo-abortar |
| `binding_checks` | lista ordenada de checks nombrados (v1: 4 abajo) |
| `write_back.artifact_path` | ruta bajo `handoffs/`; el especialista escribe aquí |
| `write_back.artifact_schema` | secciones requeridas en el artefacto de retorno |

Campos opcionales:

| Campo | Propósito |
|---|---|
| `role` | descriptivo (ej. `market-research-specialist`) |
| `load.optional` | archivos que el especialista puede leer si la tarea lo amerita |
| `write_back.also_append` | appends acotados; v1 permite solo `MEMORY.md` como target |
| `isolation` | recordatorios inline redundantes para el especialista |
| `hermes:`, `openclaw:`, `claude_code:` | extensiones específicas del harness |

---

## Protocolo de verificación

Los cuatro binding checks nombrados de v1:

| Check | Predicado |
|---|---|
| `workstream_path_exists` | `workstream_path` resuelve a un directorio |
| `brief_md_exists` | `BRIEF.md` es legible en `<workstream_path>/BRIEF.md` |
| `thread_id_matches` | `thread_id` del `BRIEF.md` coincide exactamente con el del manifest |
| `load_required_paths_exist` | cada ruta en `load.required` resuelve |

El orden importa — `workstream_path_exists` primero; los checks siguientes fallan con menos información sin él.

Implementación de referencia: [`intern-os/scripts/verify-handoff.sh`](../../scripts/verify-handoff.sh). Bash POSIX, sin dependencias.

```bash
bash intern-os/scripts/verify-handoff.sh <ruta-del-manifest>
# Exit 0 — todos los checks pasaron
# Exit 3 — un check nombrado falló (nombre del check al stderr)
# Exit 2 — uso / manifest faltante / error de parseo
```

Los adaptadores pueden reimplementar en su lenguaje host; la semántica debe coincidir.

---

## Comportamiento del coordinador

1. **Construir el manifest.** Elegir un `handoff_id` fechado. Llenar campos requeridos. Mantener `load.required` mínimo — Tier 1 (`BRIEF.md` + `STATUS.md`) por defecto.
2. **Escribir el manifest** a `<workstream_path>/handoffs/<handoff_id>.yml`.
3. **Spawneear el especialista** vía la primitiva de delegación del harness. Pasar la ruta o el contenido del manifest como el harness lo permita.
4. **Esperar la finalización.** El especialista retorna `{artifact_path, status, summary}`.
5. **Leer el artefacto de retorno** en `<workstream_path>/<artifact_path>`.
6. **Reconciliar:**
   - `status: done` → actualizar `STATUS.md` (nueva fase / próximo / bloqueadores), append a `DECISIONS.md` si corresponde.
   - `status: blocked` → capturar bloqueador en `STATUS.md.blockers`, surfacear al humano.
   - `status: aborted-binding-mismatch` → inspeccionar el manifest por el nombre del check fallido. Esto es un bug real (thread_id incorrecto, archivo faltante, error de copy-paste). Arreglar y re-spawneear — no reintentar a ciegas.
7. Opcional: append una línea curada a `MEMORY.md` describiendo el resultado del handoff.

---

## Comportamiento del especialista

Incrustado en el prompt o instrucciones del especialista:

```
1. Leer el manifest en <manifest_path>.
2. Correr binding_checks en orden. Si alguno falla, escribir el artefacto
   de retorno con status=aborted-binding-mismatch y el nombre del check
   fallido, luego retornar.
3. Leer archivos de load.required. Opcionalmente leer load.optional si
   se necesita.
4. Ejecutar task.objective hasta que:
   - success_condition sea observablemente verdadero, o
   - una stop_condition dispare.
5. Escribir el artefacto de retorno en write_back.artifact_path usando
   el schema en write_back.artifact_schema. Setear status apropiadamente.
6. Si write_back.also_append está seteado, append (no sobrescribir) a
   los target(s) listados, respetando max_lines.
7. Retornar al coordinador: {artifact_path, status, resumen de una línea}.

No:
- leer workstreams hermanos
- modificar BRIEF.md, STATUS.md, DECISIONS.md
- escribir fuera de <workstream_path>
- escanear amplio el workspace
```

---

## Layout de almacenamiento

```
<workstream_path>/
├── BRIEF.md
├── STATUS.md
├── MEMORY.md
├── DECISIONS.md
├── STAKEHOLDERS.md
├── RESOURCES.md
├── handoffs/                         ← agregado en v0.4.0
│   ├── <handoff_id>.yml              ← manifest (registro durable)
│   ├── <handoff_id>.md               ← artefacto de retorno (salida del especialista)
│   └── <handoff_id>/                 ← opcional, salidas multi-archivo
│       ├── intermediate-1.md
│       └── intermediate-2.md
└── docs/
```

El directorio `handoffs/` acumula el audit trail — cada delegación, qué se preguntó, qué se retornó. Los manifests son append-only; los especialistas no deben sobrescribir o borrar.

---

## Ejemplo end-to-end

Ver [`examples/isolated-session-handoff.md`](../../../examples/isolated-session-handoff.md) para un walkthrough concreto: el coordinador construye un manifest, spawnea un especialista, el especialista verifica + ejecuta + escribe el artefacto, el coordinador reconcilia.

---

## Notas por harness

Cada `SETUP.md` de adaptador tiene una sección "Isolated-session handoff" que documenta el mecanismo nativo de delegación del harness y cualquier extensión específica del manifest:

- [`adapters/hermes/SETUP.md`](../../../adapters/hermes/SETUP.md) — `delegate_task`, extensiones opcionales `hermes.acp_command` / `hermes.toolsets`
- [`adapters/openclaw/SETUP.md`](../../../adapters/openclaw/SETUP.md) — `sessions_spawn` con runtime aislado, attachments opcionales
- [`adapters/claude-code/SETUP.md`](../../../adapters/claude-code/SETUP.md) — `Agent` tool con manifest embebido en el prompt del subagente; hook `SubagentStop` para post-validación

---

## Preguntas abiertas (diferidas)

Preocupaciones reales parqueadas para post-v0.4.0:

- **Especialistas concurrentes.** Múltiples especialistas para el mismo workstream en paralelo — race en appends a `MEMORY.md`? Semántica de locking?
- **Firma del manifest.** Firmas desprendidas opcionales para deployments sensibles a confianza.
- **Evolución del schema.** Ruta de v2 cuando los campos de v1 demuestren ser insuficientes. Especialistas rechazan versiones desconocidas.
- **Handoff cross-workstream.** Tareas que genuinamente abarcan dos workstreams. Respuesta actual: spawneear dos especialistas. Si se vuelve doloroso, formalizar.
- **Auto-reconcile vía hooks.** Podría el hook `SessionEnd` de Claude Code auto-reconciliar artefactos? Diferir hasta que emerjan patrones de uso.
- **Especificidad del flujo de reconciliación.** Este doc dice "el coordinador actualiza STATUS.md después de leer el artefacto" sin plantillar el cómo. Discreción del coordinador en v0.4.0.

Archivar nuevos issues contra el repo si alguno de estos bloquea uso operacional.
