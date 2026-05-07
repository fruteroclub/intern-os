# Slack Canary Launch Checklist

Use this before enabling a new Slack workstream channel or changing Slack routing.

## Canary tests

Run these four tests in a test `*-workstreams` channel before rollout:

1. **Thread root visibility**
   - Create a new workstream thread.
   - Confirm the bot can read the thread root message.
   - Confirm the bot uses the root message as the workstream anchor.

2. **Mentioned response**
   - Mention the bot in the thread.
   - Confirm it responds in the same thread.
   - Confirm it does **not** post to the channel root.

3. **Unmentioned response**
   - Post a normal message in the thread without mentioning the bot.
   - Confirm the bot still responds if the channel is configured for free-response behavior.
   - Confirm the reply stays in-thread.

4. **Root-message fetch**
   - Scroll or fetch the thread from a fresh session.
   - Confirm the bot can still recover the thread root message.
   - Confirm the bot does not rely on channel-root context.

## Required Slack bot scopes

Grant the bot the minimum scopes needed for workstream threads:

- `chat:write`
- `channels:read`
- `channels:history`
- `groups:read`
- `groups:history`

If you use public channels only, `channels:*` may be sufficient.  
If you use private workstreams, `groups:*` is required.

## Operational note

If the bot cannot read the thread root message, **stop and ask**.  
Do not guess the workstream context or continue with partial Slack state.

## Routing verification

Verify the Slack gateway is configured with:

```yaml
reply_to_mode: "first"
```

Then confirm in a live thread:

- replies land in the **same thread**
- no messages are posted to the channel root
- the bot consistently anchors to the thread root message

## Go / no-go

Proceed only if all of the following are true:

- thread root is readable
- mention response stays in-thread
- unmentioned response behaves as expected
- root-message fetch works from a fresh session
- required Slack scopes are granted
- reply_to_mode: "first" behaves correctly in live use
