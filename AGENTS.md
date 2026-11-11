# Stockroom, the audit logging demo

A public demo of Avo's audit logging: a warehouse app with Avo mounted on it, and a guided tour led by Avo the
avocado. The people who open it are developers deciding whether to buy.

## Many visitors, one database

Every rule here follows from this. Several visitors take the tour at the same moment, each signed in as an account
of their own (`User.visitor`), and all of them write to the same database.

- **"Yours" is looked up by who is signed in.** `config/tour.yml` reads `Avo::Current.user`, follows a link on the
  visitor's own screen (`follow:`), or filters the list by author. "The latest row" belongs to whoever acted last,
  so light a row by its record id, never by its place in the table.
- **A list may add the seed's team, and nobody else.** `User.team` is five accounts by address, with passwords
  nobody knows. To fill a table, filter to the visitor plus the team. Never "everyone but visitors": a sign-up makes
  an account that is neither.
- **The audit log shows everyone's entries.** Point the visitor at their own. A log that leaves changes out is the
  wrong demo: the quantity would move with no entry to explain it.
- **Records drift.** Every restock raises a quantity, so pick a record by query when the page renders (the product
  lowest on stock), and write lines that stay true whichever record that is.
- **Prove it with two visitors.** Two browsers, two names, both act, and each must see their own. One visitor
  passing proves nothing about this.

## The front door

- A name is all it asks. With no name it offers a random one to accept or replace. It has no email or password form:
  the seeded team are the people in the log, and nobody signs in as them.
- An arrival stays out of the audit log, because its entry would show a password hash.
- The endpoint makes an account for anyone who calls it, so it is rate limited and the name is cleaned.

## The tour

What each stop key means is in the header of `config/tour.yml`. Behaviour is in
`app/assets/javascripts/avo-overrides.js`, markup in `app/views/avo/partials/_tour.html.erb`.

- **A line is true of what is lit.** One or two short sentences, at most one link. After changing a stop, look at it:
  the words must match what the border is around at that moment.
- **The spoken line says the written one.** `voice:` carries the same words as `text:`, plus emotion tags that fit
  the sentence. A plain statement is not `[curious]`. A lone word with an exclamation mark is heard as an order
  ("Run!"), so write the sentence. A word with two stresses needs grammar that picks one ("the Record reordering
  add-on").
- **Recording costs credits.** After editing a `voice:` line run `bin/rails tour:voices` with `ELEVENLABS_API_KEY` in
  the environment for that one command. It records only lines that have no clip. The key stays out of every file,
  commit and log.
- **Check a recording twice.** Transcribe the new clips with ElevenLabs speech-to-text to confirm the words, then ask a
  person to listen. An agent cannot hear tone or stress, and must say so.
- **He acts once per arrival.** A `click:` selector matches only while the click is still needed, so a second visit to
  the stop does nothing.
- **On a phone he never focuses a field.** Focus opens the keyboard. He types through the field's value.
- **Layers.** He stands at the chat bar's level, under the panel's notifications. He goes over the top bar only on a
  stop that lights it, and over a modal only on a stop that lights one.
- **Naming.** The app is "Stockroom". The tour's own lines and the front page may say "Avo". Nothing else a visitor
  reads in the panel does.

## The chat

- The tour's two prompts are answered by `lib/fake_llm.rb` with the tool call a model would make. The stop needs no
  key and shows its answer within 3 seconds. Keep that bound: time it as a brand-new visitor after any change.
- That file works around two timing traps and explains both. avo-ai loses an answer sent before the page is on the
  chat's stream. SQLite fails one of two jobs that write at the same instant, and
  `default_transaction_mode: immediate` made that worse when tried.
- An answer can still be missed, most often on a server that has just started. A stop that names what it `expect`s,
  or the button it `wait`s for, closes and reopens the chat's window (`retry`) when that has not come, which loads
  what the chat holds.
- Any other question goes to the real model and needs `ANTHROPIC_API_KEY`.

## Data

- `db:seed` wipes the database and rebuilds the log through the app's real paths. On a demo people are using it signs
  every visitor out mid-tour, so ask the owner first.
- Seed production on a laptop, into a fresh SQLite file (`DATABASE_URL=sqlite3:/path/to/file`), and put that file in
  the server's place. Run on the server, the seed boots the app a second time beside the one that is serving.
- After changing a model or a resource, run the seed on a copy of the database and read the PROBLEMS it prints. A
  resource change can break a path only the seed takes: MCP, the API, the chat.

## Checking your work

- Walk the tour as a brand-new visitor, at desktop and at phone width.
- A test browser cannot play sound or press real keys. Report those as not checked.
- Close a test browser when its walk is done. A tour left open keeps animating, and a dozen of them slow a laptop
  until every timing check fails.
- A page load straight onto a stop skips what the stops before it set up: the chat stop is opened by the one before.
  Walk into it.

## Open items

Open decisions, and what the demo still waits on, are in `docs/before-going-live.md`. Read it before deploying or
reseeding, and delete each item there as it is settled.
