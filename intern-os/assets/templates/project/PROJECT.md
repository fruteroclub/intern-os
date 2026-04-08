# Project: [name]

## Identity

name: [project name]
entity_type: [pod | internal-project | foundation | lab]
firm: [Frutero, LLC | Innvertir / Bulldog Capital | other]
owner: [primary human owner]
created: [YYYY-MM-DD]
thread_id: [platform:thread-id]

## Operational classification

client: [client name or N/A]
proposal_status: [closed | open | draft | N/A]
pod_type: [implementation | training | consulting | internal-product | experiment | N/A]

## Roles

delivery_manager: [name or TBD]
architect: [name or TBD]

## Purpose

objective: [main objective in one sentence]
problem: [what problem this project solves]
for_whom: [who this project exists for]

## Metrics and direction

kpis:
- [KPI 1]
- [KPI 2]
- [KPI 3]

cadence: [weekly | biweekly | monthly | other]
okr_horizon: [30 days | 90 days | project duration | other]

## Business context

lead_source: [lead source or N/A]
closed_date: [YYYY-MM-DD or N/A]
expected_revenue: [amount or N/A]

## Firm dependencies

firm_dependencies:
- [e.g. CMO for messaging]
- [e.g. CTO for infrastructure]
- [e.g. COO for operations]
- [e.g. CFO for pricing or financial control]

## Initial scope

scope_committed:
- [commercially committed scope]

scope_refined:
- [operationally or architecturally refined scope]

non_goals:
- [what is explicitly out of scope]

## Risks and assumptions

key_assumptions:
- [assumption 1]
- [assumption 2]

main_risks:
- [risk 1]
- [risk 2]

## Current state

status: [discovery | setup | active | blocked | closing | archived]
current_phase: [current phase]
next_milestone: [next milestone]
blockers:
- [blocker or none]

## Lifecycle

- [ ] Lead won
- [ ] Proposal closed
- [ ] Delivery Manager assigned
- [ ] Architect assigned
- [ ] Project created in internOS
- [ ] Commercial handoff -> delivery
- [ ] Real scope aligned
- [ ] Objective, KPIs, and cadence defined
- [ ] Firm dependencies defined
- [ ] Setup / access / tooling completed
- [ ] Kickoff
- [ ] Operation
- [ ] Delivery closed
- [ ] Project retro completed
- [ ] Learnings captured
- [ ] Administrative close completed
- [ ] Archived

## Rules by entity_type

### pod

Required:
- firm
- client
- proposal_status = closed
- delivery_manager
- architect
- objective
- kpis
- cadence
- pod_type

### internal-project

Required:
- firm
- objective
- cadence

Optional:
- delivery_manager
- architect
- kpis

### foundation

Required:
- firm
- objective

Normally N/A:
- client
- proposal_status
- pod_type

### lab

Required:
- firm
- objective

TBD is allowed for non-critical fields.

## Operational links

tick_file: [path or reference]
workstreams_dir: [path]
primary_thread: [Slack/Discord/other]
crm_record: [link or N/A]

## Active workstreams

<!-- Updated automatically when workstreams are activated -->

## Notes

- [note 1]
- [note 2]
