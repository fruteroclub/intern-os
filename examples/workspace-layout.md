# Example: Fully Populated Workspace

This shows what a workspace looks like with two projects, multiple workstreams, and tick.md initialized.

---

## Directory structure

```
workspace/
├── WORKSTREAMS.md                          ← agent runtime guide (copied from assets/)
│
├── projects/
│   ├── bulldog-capital-website/
│   │   ├── PROJECT.md                     ← project identity: purpose, scope, direction
│   │   ├── AGENTS.md                      ← project-level agent context
│   │   ├── TICK.md                        ← 5 tasks across 2 workstreams
│   │   ├── .tick/
│   │   │   └── config.yml
│   │   ├── workstreams/
│   │   │   ├── landing-page-redesign/
│   │   │   │   ├── BRIEF.md
│   │   │   │   ├── STATUS.md
│   │   │   │   ├── MEMORY.md
│   │   │   │   ├── DECISIONS.md
│   │   │   │   ├── STAKEHOLDERS.md
│   │   │   │   ├── RESOURCES.md
│   │   │   │   └── docs/
│   │   │   │       └── mockup-v2.png
│   │   │   └── seo-optimization/
│   │   │       ├── BRIEF.md
│   │   │       ├── STATUS.md
│   │   │       └── ...
│   │   └── docs/
│   │       └── brand-guidelines.pdf
│   │
│   └── intern-os-integration/
│       ├── PROJECT.md
│       ├── AGENTS.md
│       ├── TICK.md                         ← 3 tasks across 2 workstreams
│       ├── .tick/
│       │   └── config.yml
│       ├── workstreams/
│       │   ├── hermes-adapter/
│       │   │   ├── BRIEF.md
│       │   │   ├── STATUS.md
│       │   │   └── ...
│       │   └── slack-thread-support/
│       │       ├── BRIEF.md
│       │       ├── STATUS.md
│       │       └── ...
│       └── docs/
```

---

## Example PROJECT.md (bulldog-capital-website)

```markdown
# Project: bulldog-capital-website

## Identity

name: bulldog-capital-website
owner: Mel
created: 2026-03-15

## Purpose

objective: Redesign and optimize the Bulldog Capital investor-facing website
problem: Current site has high bounce rate and outdated branding
for_whom: Marketing team and potential investors

## Scope

includes: Landing page, SEO, CMS integration
excludes: Authentication, backend API, pricing page

## Direction

cadence: weekly
success_criteria: Bounce rate below 45%, mobile-first responsive design
archive_condition: All pages redesigned and SEO audit passing

## Current state

status: active
current_phase: Implementation
next_milestone: Landing page CMS integration complete
blockers:

## Operational links

tick_file: TICK.md
workstreams_dir: workstreams/
primary_thread: slack:C07ABC123/1711792700.000001

## Active workstreams

- landing-page-redesign (Implementation — 2/3 tasks done)
- seo-optimization (Backlog)

## Notes
```

---

## Example AGENTS.md (bulldog-capital-website)

```markdown
# AGENTS — bulldog-capital-website

## Stack and conventions

- Next.js 14 with App Router
- Tailwind CSS for styling
- Sanity CMS for content management
- Deploy target: Vercel

## Key people

| Name | Role | Responsibility | Contact |
|------|------|----------------|---------|
| Mel | Owner | Final approval on design decisions | Slack DM |
| Ana | Designer | Brand assets and mockups | Figma comments |

## Communication rules

- Design feedback via Figma comments, not Slack
- Deploy previews shared in the workstream thread

## Active integrations

- Sanity CMS (content API)
- Vercel (hosting + preview deploys)
- Google Analytics (tracking)

## Architectural constraints

- All pages must score 90+ on Lighthouse performance
- CMS content must be fully typed with Sanity schemas
```

---

## Example TICK.md (bulldog-capital-website)

```yaml
---
project: bulldog-capital-website
title: Bulldog Capital Website
schema_version: "1.0"
created: 2026-03-15T10:00:00.000Z
updated: 2026-03-30T14:30:00.000Z
default_workflow: [backlog, todo, in_progress, review, done]
id_prefix: TASK
next_id: 6
---
```

```
## Agents

| Agent | Type | Role | Status | Working On | Last Active | Trust Level |
|-------|------|------|--------|------------|-------------|-------------|
| @mel  | human | owner | idle | - | 2026-03-30T12:00:00Z | owner |
| @duki | bot | engineer | working | TASK-003 | 2026-03-30T14:30:00Z | trusted |

## Tasks

### TASK-001
status: done
priority: high
tags: [landing-page-redesign]
claimed_by: null
> Design new hero section with updated brand assets

### TASK-002
status: done
priority: medium
tags: [landing-page-redesign]
claimed_by: null
> Implement responsive layout for mobile

### TASK-003
status: in_progress
priority: high
tags: [landing-page-redesign]
claimed_by: @duki
> Integrate CMS for dynamic content

### TASK-004
status: todo
priority: medium
tags: [seo-optimization]
claimed_by: null
> Audit current meta tags and structured data

### TASK-005
status: backlog
priority: low
tags: [seo-optimization]
claimed_by: null
> Set up automated lighthouse CI checks
```

---

## Example BRIEF.md (landing-page-redesign)

```markdown
# BRIEF — landing-page-redesign

thread_id: slack:C07ABC123/1711792800.123456
project: bulldog-capital-website
workstream: landing-page-redesign
owner: Mel
created: 2026-03-15
last_updated: 2026-03-30

## Objective

Redesign the landing page for Bulldog Capital's investor-facing website.

## Problem

Current landing page has a 68% bounce rate and doesn't reflect the updated brand.

## Scope

### Includes

Hero section, value props, testimonials, CTA, CMS integration, mobile responsive.

### Excludes

Blog, pricing page, authentication, backend API changes.

## Success criteria

A responsive landing page with updated brand, CMS integration, and <45% bounce rate.

## Appetite

2 weeks maximum.

## Related stakeholders

Mel (owner), Ana (designer)

## Related resources

See RESOURCES.md for full artifact index.
```

---

## Example STATUS.md (landing-page-redesign)

```markdown
# STATUS — landing-page-redesign

Phase: Implementation — 2 of 3 tasks complete
Next: Wire up testimonials to CMS, then workstream moves to review
Owner: @duki
Blockers: None
Updated: 2026-03-30
```
