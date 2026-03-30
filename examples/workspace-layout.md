# Example: Fully Populated v2 Workspace

This shows what a workspace looks like with two projects, multiple workstreams, and tick.md initialized.

---

## Directory structure

```
workspace/
├── WORKSTREAMS.md                          ← agent runtime guide (copied from assets/)
│
├── projects/
│   ├── bulldog-capital-website/
│   │   ├── TICK.md                         ← 5 tasks across 2 workstreams
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
# Brief

thread_id: slack:C07ABC123/1711792800.123456

## What specific work is this?

Redesign the landing page for Bulldog Capital's investor-facing website.

## What problem or situation triggers it?

Current landing page has a 68% bounce rate and doesn't reflect the updated brand.

## Who needs it and for what purpose?

Marketing team needs it to improve conversion from organic traffic.

## What does it deliver when done?

A responsive landing page with updated brand, CMS integration, and <45% bounce rate.

## What is in scope? What is out of scope?

**In scope:** Hero section, value props, testimonials, CTA, CMS integration, mobile responsive.

**Out of scope:** Blog, pricing page, authentication, backend API changes.

## What is the appetite?

2 weeks maximum.
```

---

## Example STATUS.md (landing-page-redesign)

```markdown
# Status

## Current phase

Implementation — 2 of 3 tasks complete

## Last session

2026-03-30 — Connected CMS API, hero section now pulls dynamic content.
Testimonials section still using static data.

## Blockers

None.

## Next

Wire up testimonials to CMS. Then TASK-003 is done and workstream moves to review.
```
