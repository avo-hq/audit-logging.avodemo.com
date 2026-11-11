# Open items

Written 2026-11-11, the day this version went live. Each item is open until someone deletes it. `AGENTS.md` holds
the rules that stay.

## Waiting on a release

| What                                                              | Until then                                              |
| ----------------------------------------------------------------- | ------------------------------------------------------- |
| Avo after 4.4.3: lists paginate in Romanian and Norwegian Nynorsk | `config/initializers/languages.rb` leaves the two out of the language switcher. They come back by themselves. |
| avo-nested after 4.4.0: a write to a resource that has a nested field | Creating a product through MCP or the AI chat fails. Product has nested stock movements. |
| avo-api after 4.4.0: its answer to a write on such a resource     | Creating a product through the REST API saves it and answers 500. |

The seed creates a product through all three. Run it against a build that has the avo-nested fix (`Gemfile.local`),
or it reports PROBLEMS and loses two entries, one of them the AI chat entry stop 26 shows. With the fix it reports one
problem, the REST API's 500, and loses nothing.

## Decisions nobody has made

1. **Visitor names are public.** Other visitors read them in the Users list, a record's History and the Author
   filter. The alternative is to show everyone else "Visitor 4f2a".
2. **Old visitors are never removed.** The Author filter lists every one of them. A rule is needed, for example
   deleting visitors and what they did after 24 hours.
3. **A model key for free questions.** Without `ANTHROPIC_API_KEY` the chat answers only the tour's two prompts. With
   one, every visitor's question costs money.
4. **The name.** "Stockroom" was a working choice.
5. **Impersonate.** The Users page lets a visitor act as a teammate, or as another visitor, and the log then names
   that account. It is the one way left to put a change under someone else's name. Removing the action closes it.

## How it runs in production

- One Puma process with its jobs inside it. The chat's answers arrive over Action Cable's in-process adapter, and
  `lib/fake_llm.rb` counts the pages on each chat stream in memory. A second process needs `REDIS_URL`, and then
  the chat's answer waits its full 2 seconds before going out.
- That process takes about 350 MB.
- The database is one SQLite file. A reseed is done on a laptop into a fresh file, which then replaces the server's:
  the seed boots the app a second time, and signs every visitor out.

## Not checked by a person yet

- How the recorded lines sound: stress and tone, on every stop changed on 2026-11-11.
- The tour on a real phone: the keyboard staying down, and the layout of the chat stops.

## Rough spots

- The repo's RuboCop version does not know Ruby 4.0, so it cannot run, and CI has been red since before this version.
- A filter pill with many values is wider than a phone. `avo-overrides.css` caps it here. The fix belongs in
  `avo-dynamic_filters`.
