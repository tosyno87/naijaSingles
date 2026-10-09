# App Review — Houston Discover home

Reviewer screenshots must start on **Discover**, not the Connect swipe deck.

1. Houston home: **New in Houston? Meet your people.**
2. **This weekend** event rows (two Houston listings).
3. **Explore groups** text link.
4. **Connect after the event** (secondary).

Do not lead with a profile card or swipe pile.

## Event supply

The Flutter client never seeds events. Operators run:

```bash
cd functions
npx ts-node src/scripts/seedHoustonReviewEvents.ts --project naijasingles-staging
```

Idempotent stable ids. Production projects are refused unless `--i-am-sure`.
