# audit-logging.avodemo.com

An Avo panel that shows what avo-audit_logging records: the audit log, each activity's changeset and Undo, and
every origin a change can come from (the panel, an MCP connection, an API token, an AI chat, a job, a rake task,
the console, the app's own pages).

## Run it

```bash
bin/rails db:prepare
bin/rails ruby_llm:load_models
AVO_ADMIN_PASSWORD=secret bin/rails db:seed   # starts from scratch every time
bin/dev
```

Sign in as `avo@cado.com` with `AVO_ADMIN_PASSWORD` (`secret` when unset).

`db/seeds/activity.rb` makes the audit log by driving the real app: signed-in requests to the panel, an OAuth
connection and tool calls to the MCP server, requests with API tokens, two AI chats, a job, a rake task, the
console and a sign-up. The chats are answered by a scripted stand-in for the LLM (`db/seeds/fake_llm.rb`), so
seeding needs no API key. `SKIP_ACTIVITY=1` seeds the records without the log.

## Environment

| Variable            | What for                                                          |
| ------------------- | ----------------------------------------------------------------- |
| `AVO_LICENSE_KEY`   | The add-ons' license.                                             |
| `ANTHROPIC_API_KEY` | The AI chat, for visitors' own questions.                         |
| `AVO_AI_MODEL`      | The chat's model, `claude-sonnet-5-5` by default.                 |
| `REDIS_URL`         | Action Cable in production, which streams the chat's replies.     |

## Unreleased add-ons

To run against a workspace checkout, create an uncommitted `Gemfile.local` and bundle with it, so `Gemfile.lock`
keeps resolving from packager.dev:

```ruby
ENV["AVO_GEMS_PATH"] ||= "/path/to/workspace/gems"
ENV["AVO_CORE_PATH"] ||= "/path/to/workspace/avo"
eval_gemfile File.expand_path("Gemfile", __dir__)
```

```bash
BUNDLE_GEMFILE=Gemfile.local bundle install
BUNDLE_GEMFILE=Gemfile.local bin/rails server
```
