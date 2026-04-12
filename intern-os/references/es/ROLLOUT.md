# ROLLOUT — Llevar un Workspace a Spec de internOS

*internOS v0.3.1 | 2026-04-12*

---

## Cuándo usar esto

Usa este protocolo cuando:
- Estés desplegando internOS en un workspace con proyectos existentes
- Estés actualizando un workspace a una nueva versión de internOS
- Estés auditando la salud del workspace antes de un hito
- Estés incorporando un equipo nuevo a un workspace existente

---

## Prerequisitos

- Skill de internOS instalado (ver SETUP.md para tu adaptador)
- `WORKSTREAMS.md` colocado en la raíz del workspace
- Acceso al sistema de archivos del workspace

---

## Fase 1: Evaluar estado actual

Genera el registro para ver qué existe:

```bash
bash intern-os/scripts/generate-registry.sh <workspace-path>
```

Revisa `projects/REGISTRY.md`. El registro incluye **todos los workstreams no archivados** — usa la columna Phase para distinguir entre workstreams activos, pausados y en backlog. La tabla de resumen muestra:
- Cuántos workstreams existen (no archivados)
- Cuántos son saludables, incompletos o sin vincular
- Cuáles necesitan atención

Ejecuta sync-check en modo rollout para una lista de acciones priorizada:

```bash
bash intern-os/scripts/sync-check.sh <workspace-path> --rollout
```

Esto produce un reporte enfocado: workstreams sin vincular, campos de identidad incompletos, y etiquetas faltantes en TICK.md — ordenados por severidad.

---

## Fase 2: Normalizar workstreams (activos primero)

El registro muestra todos los workstreams no archivados. Durante el rollout, **prioriza los activos primero** — aquellos con trabajo en curso, hilos de comunicación abiertos y tareas en progreso. Los pausados o en backlog pueden esperar.

### Orden de prioridad

1. **Vincular hilos activos** — Para cada workstream con un hilo de comunicación activo, agrega el `thread_id` correcto a BRIEF.md:
   ```
   thread_id: discord:1491150845675438110
   ```
   o:
   ```
   thread_id: slack:C07ABC123/1234567890.123456
   ```

2. **Completar campos de identidad** — Llenar `project`, `workstream`, `owner`, `created` en BRIEF.md.

3. **Actualizar STATUS.md** — Asegurar que Phase, Next, Owner, Blockers, Updated estén al día. Objetivo: ≤10 líneas.

4. **Etiquetar en TICK.md** — Asegurar que cada workstream activo tenga al menos una tarea etiquetada:
   ```bash
   tick add "Descripción" --tag workstream-name --priority high
   ```

5. **Crear archivos faltantes** — Si faltan archivos de los 6 del workstream, crearlos desde templates:
   ```bash
   cp intern-os/assets/templates/workstream/ARCHIVO_FALTANTE.md projects/[proyecto]/workstreams/[nombre]/
   ```

---

## Fase 3: Clasificar contenido legacy

Para directorios que no son workstreams activos:

| Situación | Acción |
|-----------|--------|
| El trabajo está terminado | Mover a `workstreams/archived/` |
| El trabajo está pausado pero puede retomarse | Mantener en su lugar, poner phase en STATUS.md como `Paused` |
| El directorio es huérfano/legacy | Mover a `workstreams/archived/` con una nota en STATUS.md |
| No estás seguro | Mantener en su lugar, marcar como `Paused` — revisitar después |

```bash
# Archivar un workstream completado
mv projects/[proyecto]/workstreams/[nombre] projects/[proyecto]/workstreams/archived/[nombre]
```

---

## Fase 4: Validar

Ejecuta ambas herramientas de nuevo para confirmar que el workspace está limpio:

```bash
# Chequeo de salud
bash intern-os/scripts/sync-check.sh <workspace-path>

# Regenerar registro
bash intern-os/scripts/generate-registry.sh <workspace-path>
```

Revisa `projects/REGISTRY.md` — los workstreams que normalizaste en la Fase 2 deberían aparecer como `healthy`.

---

## Fase 5: Mantenimiento continuo

- Re-ejecuta `generate-registry.sh` después de activar o archivar workstreams
- Ejecuta `sync-check.sh` periódicamente o después de cambios mayores
- Usa `checkpoint-reminder.sh` para detectar STATUS.md obsoletos:
  ```bash
  bash intern-os/scripts/checkpoint-reminder.sh <workspace-path> 3
  ```
- El registro es un snapshot — refleja el estado al momento de generación, no en tiempo real

---

## Checklist de rollout

- [ ] `generate-registry.sh` ejecutado — `projects/REGISTRY.md` generado
- [ ] `sync-check.sh --rollout` ejecutado y revisado
- [ ] Workstreams priorizados tienen `thread_id` en BRIEF.md
- [ ] Workstreams priorizados tienen campos de identidad en BRIEF.md
- [ ] Workstreams priorizados tienen STATUS.md actualizado
- [ ] Workstreams priorizados tienen etiquetas de tarea en TICK.md
- [ ] Directorios legacy clasificados (archivados o pausados)
- [ ] Registro regenerado — workstreams priorizados aparecen como `healthy`
- [ ] `sync-check.sh` (modo normal) pasa limpio

---

## Referencia de herramientas

| Herramienta | Propósito | Comando |
|-------------|-----------|---------|
| `generate-registry.sh` | Generar registro de workstreams | `bash generate-registry.sh <workspace-path>` |
| `sync-check.sh` | Validación de salud del workspace | `bash sync-check.sh <workspace-path>` |
| `sync-check.sh --rollout` | Validación enfocada en rollout | `bash sync-check.sh <workspace-path> --rollout` |
| `checkpoint-reminder.sh` | Detectar STATUS.md obsoletos | `bash checkpoint-reminder.sh <workspace-path> [days]` |
