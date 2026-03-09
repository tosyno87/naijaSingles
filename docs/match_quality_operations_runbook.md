# Match Quality Operations Runbook

Goal: validate instrumentation ingestion, establish baseline KPIs, run first
controlled experiment, and make a promotion/rollback decision with clear
guardrails.

## Ownership

| Role | Responsibility |
|------|----------------|
| Product Owner | Hypothesis, KPI targets, final promote/rollback decision |
| Data/Analytics Owner | Baseline + experiment report generation and interpretation |
| Engineering Owner | Deploys config, monitors pipeline health, executes rollback |

## Operating Cadence

| Milestone | When |
|-----------|------|
| Production deploy | Day 0 |
| Ingestion validation | Day 1-2 |
| Baseline collection | Week 1-2 |
| First experiment run | Week 3-6 |
| Automated report review | Weekly (Monday, via CI) |
| Decision meeting | Within 48h of experiment end |

---

## Phase A -- Deploy and Validate Instrumentation

### Day 0 Release Checklist

1. Confirm branch is green:

```bash
flutter test --no-pub
flutter analyze --no-fatal-infos --no-fatal-warnings
```

2. Seed the runtime config document (first deploy only):

```bash
cd functions && npx ts-node src/scripts/seedMatchTuningConfig.ts
```

Use `--force` to overwrite an existing document. Requires
`GOOGLE_APPLICATION_CREDENTIALS` or default GCP credentials.

This writes `runtimeConfig/matchTuning` with default weights and
`experiment.active: false`.

3. Deploy Firestore rules and indexes:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

4. Deploy Cloud Functions:

```bash
cd functions && npm run build && firebase deploy --only functions
```

5. Release mobile build to production.
6. Record release metadata: app version, commit SHA, release timestamp,
   config version.

### 48-Hour Ingestion Validation

Run the validation Cloud Function:

```bash
curl -X POST https://<region>-<project>.cloudfunctions.net/validateIngestion \
  -H "Content-Type: application/json" \
  -d '{"hoursBack": 48}'
```

The response is a JSON report:

```json
{
  "status": "pass",
  "hoursBack": 48,
  "windowStart": "...",
  "windowEnd": "...",
  "eventCounts": {
    "impression": 1234,
    "action": 567,
    "match": 89,
    "conversationStart": 45,
    "conversationQuality": 30
  },
  "missingTypes": [],
  "schemaViolations": []
}
```

**Acceptance gate:**

- `status` is `"pass"`.
- Event volume is non-zero for all five required types.
- No schema violations in sampled documents.

**Failure handling:**

- If ingestion fails: stop experiment planning, fix pipeline, redeploy,
  restart 48-hour validation.
- If schema is malformed: hotfix reporter, redeploy, reset baseline window
  start date.

---

## Phase B -- Baseline KPI Window (2 weeks)

### Baseline KPI Definitions

| KPI | Formula |
|-----|---------|
| `connectToMatchRate` | matches / connects |
| `matchToFirstMessageRate` | first messages / matches |
| `conversationRetention7dRate` | conversations with depth >= 4 / total conversations |
| `responseRate` | avg response rate from conversation quality events |
| `medianReplyDelayMs` | median reply delay from conversation quality events |
| `conversationDepth` | avg conversation depth from conversation quality events |

Guardrail metrics (monitored but not KPI targets):

- p95 action latency (connect/super-like)
- Error rate on connect/super-like paths

### Baseline Report Generation

At end of baseline window, pull metrics via the aggregation function:

```bash
curl -X POST https://<region>-<project>.cloudfunctions.net/aggregateMetrics \
  -H "Content-Type: application/json" \
  -d '{
    "startDate": "2026-03-15T00:00:00Z",
    "endDate": "2026-03-29T00:00:00Z"
  }'
```

Copy the `metrics` object from the response into
`reports/match/baseline_<yyyy-mm-dd>_<appVersion>.json`, using the template
at `reports/match/baseline_template.json`. Set both `baseline` and `variant`
to the same values (this confirms the pipeline works end-to-end; the
evaluator will output `hold` since there is no lift).

Run the report CLI to validate:

```bash
dart run tool/match_experiment_report.dart \
  --input reports/match/baseline_<yyyy-mm-dd>_<appVersion>.json \
  --output reports/match/baseline_report_<yyyy-mm-dd>.json
```

Expected decision: `hold` (no lift between identical metrics).

### Baseline Acceptance Gate

- Minimum sample size threshold met (default: 200 unique users).
- If sample size is too low, extend baseline by 1 additional week.

---

## Phase C -- First Experiment Cycle (2-4 weeks)

### Experiment Design

Rules:

- **Single lever only.** Change one tuning parameter per experiment cycle.
- Recommended first experiment: `locationWeight` +10% in variant, or
  `ageWeight` -10% in variant.
- All other weights unchanged.
- 50/50 user split.
- Minimum 14 days; extend to 28 days if significance not reached.

### Experiment Config Deployment

Write experiment config to `runtimeConfig/matchTuning` (Firestore):

```json
{
  "payload": {
    "version": "1.1.0",
    "rollbackKey": "v1_0_0_defaults",
    "experiment": {
      "active": true,
      "id": "exp_location_weight_v1",
      "startTimestamp": "2026-04-01T00:00:00Z",
      "plannedEndTimestamp": "2026-04-15T00:00:00Z",
      "variants": [
        {
          "id": "control",
          "weight": 50
        },
        {
          "id": "location_boost_10pct",
          "weight": 50,
          "tuning": {
            "datingWeights.location": 0.275
          }
        }
      ]
    }
  }
}
```

After deploying, confirm assignment is stable:

- Check `matchQualityEvents` documents for `experimentId` and `variantId`
  fields populated on new events.
- Verify approximately 50/50 distribution across variants.

### Weekly Monitoring

Run the aggregation function for each variant:

```bash
# Control
curl -X POST .../aggregateMetrics \
  -d '{"startDate":"...","endDate":"...","experimentId":"exp_location_weight_v1","variantId":"control"}'

# Variant
curl -X POST .../aggregateMetrics \
  -d '{"startDate":"...","endDate":"...","experimentId":"exp_location_weight_v1","variantId":"location_boost_10pct"}'
```

Build the experiment input JSON from both responses and run the report CLI:

```bash
dart run tool/match_experiment_report.dart \
  --input reports/match/exp_location_weight_v1_week1.json \
  --output reports/match/exp_location_weight_v1_week1_report.json
```

The weekly CI workflow (`match-experiment-evaluation.yml`) runs automatically
on Mondays. Check its output in GitHub Actions.

Weekly guardrail checks:

- Retention must not drop past threshold.
- Error rate must not exceed threshold.
- p95 latency must stay within budget.

---

## Promotion/Rollback Decision Policy

### Promote variant only if ALL are true

- `matchToFirstMessageRate` improves versus control.
- `matchRate` and/or `connectRate` do not regress materially.
- No guardrail breach on retention, error rate, or p95 latency.
- Improvement is stable across at least two consecutive weekly reads.

### Rollback immediately if ANY are true

- Guardrail breach sustained for 24 hours.
- Data integrity issue invalidates assignment or event attribution.
- Operational incident affects ranking correctness.

### Rollback procedure

1. Set `experiment.active: false` in `runtimeConfig/matchTuning`.
2. All users immediately revert to control config (config provider falls
   back to base when experiment is inactive).
3. No app redeploy required.

### Decision Artifact

Create final decision report:

```bash
dart run tool/match_experiment_report.dart \
  --input reports/match/exp_<id>_final.json \
  --output reports/match/decision_<id>_<yyyy-mm-dd>.json
```

The output includes:

- KPI deltas
- Guardrail outcomes
- Decision (`promote`, `hold`, or `rollback`)
- Reason codes

Archive in `reports/match/` and commit to the repository.

---

## Firestore Paths Reference

| Purpose | Path |
|---------|------|
| Match quality events | `matchQualityEvents/{eventId}` |
| Runtime tuning config | `runtimeConfig/matchTuning` |
| Config payload field | `.payload` (nested) |
| Experiment config | `.payload.experiment` |

---

## Assumptions and Defaults

- Baseline window default: 14 days.
- Experiment window default: 14-28 days.
- Single-variable experiment rule: one tuning parameter changed per cycle.
- If significance is inconclusive at day 14, extend to day 28 before deciding.
- If traffic is insufficient for stable readouts, prioritize retention of
  control config and continue data collection.
- `conversationRetention7dRate`: approximated as conversations with
  depth >= 4 divided by total conversations. Full D7 session-return
  tracking is not yet instrumented; use matching values for baseline and
  variant to disable this guardrail until proper tracking is added.

---

## Cloud Function Endpoints

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `validateIngestion` | POST | 48-hour ingestion health check |
| `aggregateMetrics` | POST | Compute KPI rates from raw events |
| `healthCheck` | GET | Generic service health |

---

## Report Archive Convention

```
reports/match/
  baseline_<yyyy-mm-dd>_<appVersion>.json
  baseline_report_<yyyy-mm-dd>.json
  exp_<id>_week<N>.json
  exp_<id>_week<N>_report.json
  decision_<id>_<yyyy-mm-dd>.json
```
