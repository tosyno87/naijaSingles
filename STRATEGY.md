---
name: AfroPeep
last_updated: 2026-05-28
launch_city: Houston, TX
---

# AfroPeep Strategy

> **The come-up:** Win one city at a time by being the place diaspora Africans actually meet — at events and in community first, on Connect second — with trust strong enough that word-of-mouth replaces paid ads.

## Target problem

Africans in the diaspora want dating and community that feels culturally legible — not generic, not fetishized, not scam-ridden — but the pool is **fragmented by city**, **skewed by gender**, and **dominated by general apps** (Hinge, Bumble, Instagram) that already have density and habit. A niche app without local liquidity and trust reads as an empty room or a risk, no matter how good the swipe UX is.

## Our approach

**City-first liquidity, trust before monetization, community as the wedge.**

We do not out-Tinder Tinder. We become the verified diaspora graph in each metro: people you might meet at Afrobeats night, in a professional group, or at a cultural event — then Connect is where mutual interest turns into a match. We gate paid visibility (boost, Likes You) behind **felt value and safety signals**, not sign-up. **Year one starts in Houston** — saturate one metro until metrics are green, then replicate the playbook. Never broadcast marketing into a cold market.

## Who it's for

**Primary:** *The intentional dater* — diaspora African (25–40) in **Greater Houston**, wants a serious relationship with someone who gets culture, immigration context, and community without explaining themselves every swipe.

**Secondary:** *The community builder* — Houston-based, attends or hosts diaspora events (Afrobeats, professional mixers, church/social circles), joins cultural groups, open to connection but needs a **safe, familiar room** before dating feels natural.

## Key metrics

- **Profiles within 25 mi of Houston** — active, complete profiles in the launch metro; measured weekly in Firestore/analytics
- **Median time to first match (7-day cohort)** — new user → first mutual match within 7 days; primary liquidity signal
- **D7 retention (by gender)** — split male/female; catches empty-room and safety-driven churn early
- **Report rate per 1k DAU** — trust health; spikes precede brand death in diaspora WhatsApp networks
- **Event RSVP → profile view → match** — proves the differentiated wedge (community → dating), not swipe alone

## Tracks

### City launch & liquidity

Seed and saturate **Houston** before any other metro. Large West African diaspora, strong event culture, and enough professional density to support serious intent — but still small enough that we can **manually fill the room**. Recruit 100+ beta users across Houston proper and suburbs (Katy, Sugar Land, Pearland, The Woodlands) with gender balance; partner on 2–3 anchor events (Afrobeats, professional African orgs, cultural festivals). Do not scale paid acquisition outside Houston until median time-to-first-match and D7 retention hit thresholds.

_Why it serves the approach:_ Niche dating dies globally and lives locally; Houston is our first proof that density is the product.

### Trust & safety

Photo verification before boost/super-like visibility; server-validated IAP for boost grants; enforce reports with human review; block off-platform scam patterns (new account + mass likes + contact info in bio). Public safety narrative — how we handle romance scams and fake profiles.

_Why it serves the approach:_ Diaspora word-of-mouth is binary: “safe and real” or “another scam app.”

### Events & communities → Connect

Events (Eventbrite + RSVPs), group posts, deep links, and public profiles are the **top of funnel**. Connect, chat, Likes You, and undo are the **payoff**. Product and marketing should tell one story: *meet here, match here.*

_Why it serves the approach:_ Hinge cannot copy our local event graph and verified diaspora context quickly.

### Monetization with discipline

Boost and premium after value is demonstrated — geo-gated packages, iOS IAP live, Android purchase hidden until Play exists, Firestore `Packages.status` as a real feature flag. Measure boost as **lift in views/likes**, not just a timer.

_Why it serves the approach:_ Paywalls before matches produce 1★ reviews and churn; revenue follows liquidity.

## Milestones

- **2026-Q2** — Merge product excellence stack to `main`; TestFlight smoke (login, swipe, match, chat, boost sandbox)
- **2026-Q2** — Houston beta recruitment: 100+ users (balanced gender, Nigerian/Ghanaian/Ethiopian and broader African heritages)
- **2026-Q3** — Houston beta live: liquidity + trust metrics green for 4 consecutive weeks
- **2026-Q3** — Server-side boost activation (Cloud Function + receipt validation)
- **2026-Q4** — Replicate Houston playbook in city #2 OR App Store scale marketing (only if Houston metrics hold)

## Not working on

- National or “global diaspora” launch before one city works
- Competing on swipe UX alone against Hinge/Bumble
- Broad paid acquisition into thin markets
- Android boost/IAP before Google Play product setup
- Ad monetization before D7 retention and trust metrics are healthy
- Pan-African positioning on day one without honest year-one focus (clarity beats pretending to serve everyone)

## Marketing

**One-liner:** AfroPeep is where Houston's diaspora Africans meet — online and at the events you already go to.

**Key message:** We're not another empty dating app. We're the verified community for Africans in Houston: discover people at cultural events and in groups, match when the vibe is mutual, and stay in a space built for trust — not for visa jokes or random DMs. **Houston first.** Bring your people.

---

## 90-day scorecard (operating rhythm)

Review weekly. **Pause paid spend** if row 1–2 are red in Houston.

| Signal | Green | Red |
|--------|-------|-----|
| Profiles within 25 mi | Growing week-over-week | Flat or declining |
| Median time to first match (7d) | ≤ 72 hours | > 7 days or N/A |
| D7 retention (female) | ≥ 35% | < 25% |
| D7 retention (male) | ≥ 25% | < 15% |
| Report rate / 1k DAU | Stable or falling | Rising 2+ weeks |
| Female share of new signups | 40–55% | < 35% |
| Boost → measurable lift | Views/likes up vs baseline | Timer only, no lift |

---

## Strategic risks (premortem → guardrails)

| Risk | Guardrail |
|------|-----------|
| Empty room | Houston-only seeding, event-led recruitment, liquidity metrics before scale |
| Scam / trust collapse | Verify before visibility; server-side boost; report enforcement |
| “Not for us” positioning | Honest year-one focus; inclusive product, narrow launch narrative |
| Hinge wins by density | Wedge = events + groups + verified diaspora context |
| Monetization kills growth | Geo-gate pay; prove value free first |
| Women churn silently | Gender-split metrics; rate limits; safety UX in chat |
| Technical credibility | Release smoke script; feature flags; dark ship → city toggle |
| Community backlash | Advisory review of copy/partnerships before campaigns |

---

## Relationship to other docs

- **Build & architecture:** [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md)
- **Launch checklist (tactical):** [`docs/features/LAUNCH_CHECKLIST.md`](docs/features/LAUNCH_CHECKLIST.md)
- **Deployment:** [`docs/deployment/DEPLOYMENT_AND_BRANCHES.md`](docs/deployment/DEPLOYMENT_AND_BRANCHES.md)
