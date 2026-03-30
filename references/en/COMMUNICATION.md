# COMMUNICATION — Multi-Platform Specification

*internOS v2.0 | 2026-03-30*

Every workstream has a communication thread. The thread is the collaboration surface where humans and agents discuss, decide, and coordinate work. The framework is platform-agnostic — this spec defines the protocol and its implementations for Discord and Slack.

---

## Principles

1. **One workstream, one thread.** A workstream lives on one communication platform at a time.
2. **Thread-only interaction.** Agents respond inside the workstream thread, never in the channel/forum root.
3. **Thread starter as context anchor.** The first message in the thread contains workstream metadata and survives context compaction — it is the most reliable way for the agent to know which workstream it's operating in.
4. **Platform-agnostic mapping.** The `thread_id` field in BRIEF.md uses the format `[platform]:[id]` to link the thread to its workstream directory.

---

## Thread starter format

The first message in every workstream thread follows this format, regardless of platform:

```
**[Workstream name]**

What: [one line]
Owner: [name]
Task: [tick-md task ID or external URL]
Directory: projects/[project]/workstreams/[name]/
Status: [current phase — one line]
```

> Keep this message updated. It is injected into agent context on every interaction and is the primary context persistence mechanism.

---

## Thread ID in BRIEF.md

Every workstream's BRIEF.md contains a `thread_id` field that maps the communication thread to the filesystem directory:

```yaml
thread_id: discord:123456789
```

```yaml
thread_id: slack:C07ABC123/1234567890.123456
```

This is the canonical mapping. Without it, the link between thread and directory is implicit and fragile.

---

## Channel naming convention

Both Discord forums and Slack channels use the same naming convention:

```
[area]-workstreams
```

Examples: `ceo-workstreams`, `tech-workstreams`, `ops-workstreams`, `mkt-workstreams`.

**Classification rule:** the channel/forum is determined by who owns the workstream, not the topic. A frontend bug owned by the tech lead goes in `tech-workstreams`, not a hypothetical `bugs` channel.

Each project defines its own channels based on its active areas.

---

## Discord specification

### Container: Forums

Workstreams live exclusively in Discord **forums** (not regular text channels). Each forum is named `[area]-workstreams`.

### Workstream surface: Forum posts

Each workstream is a forum post (which creates a thread). The post's original message follows the thread starter format above.

### Thread ID

Discord thread IDs are the numeric `topic_id` from Discord metadata. Format in BRIEF.md:

```yaml
thread_id: discord:1234567890123456789
```

### Persistent context mechanism

Discord injects the forum post's original message into every thread message, including during context compaction. This means the agent always sees the workstream metadata without explicitly loading it.

### Rules

- Workstreams live exclusively in forums, never in regular text channels
- Regular text channels are for direct agent interaction, not workstreams
- One forum post = one workstream
- The agent responds inside the thread, not as a new forum post

---

## Slack specification

### Container: Channels

Workstreams live in Slack **channels** named `[area]-workstreams`. These are regular channels (not Slack Connect or shared channels).

### Workstream surface: Threads

Each workstream is a **thread** within the channel. The thread's root message follows the thread starter format above.

### Thread ID

Slack thread IDs combine the channel ID and the thread timestamp. Format in BRIEF.md:

```yaml
thread_id: slack:C07ABC123/1234567890.123456
```

Where `C07ABC123` is the Slack channel ID and `1234567890.123456` is the `thread_ts` (timestamp of the root message).

### Persistent context mechanism

The thread root message in Slack is always visible when scrolling to the top of a thread. Agents should read it on thread entry to load workstream context. Unlike Discord, Slack does not automatically inject it — the agent must explicitly load it.

### Thread-only mode

- The agent responds **only inside threads**, never in the channel root
- New messages in the channel root are for creating new workstream threads
- The agent does not post standalone messages to the channel

### Slack-specific setup

The Slack bot needs:
- Permission to read and write messages in `-workstreams` channels
- Permission to read and reply to threads
- Configuration to operate in thread-only mode (agent framework-specific — see adapters/)

---

## Choosing a platform

The framework does not prescribe a platform. Teams choose based on what they already use:

| Factor | Discord | Slack |
|--------|---------|-------|
| Best for | Developer/community teams, open-source | Business teams, enterprises |
| Forum/thread model | Native forums with rich threading | Channels with threads |
| Context persistence | Automatic (topic injection) | Manual (agent reads root message) |
| Bot setup | Discord bot with forum permissions | Slack app with channel permissions |

A team can use one platform or both (for different projects). Each workstream lives on exactly one platform.

---

## Future platforms

The protocol is designed to extend to other platforms. To add a new platform:

1. Define the container type (equivalent to Discord forums or Slack channels)
2. Define the workstream surface (equivalent to forum post or thread)
3. Define the thread ID format: `[platform]:[id]`
4. Define the persistent context mechanism
5. Document any thread-only mode configuration
6. Add an entry to the platform table in FRAMEWORK.md

Candidates: Telegram (topics in groups), WhatsApp (groups), Microsoft Teams (channels + threads).
