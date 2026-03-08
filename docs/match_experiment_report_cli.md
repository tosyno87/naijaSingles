# Match Experiment Report CLI

Generate a machine-readable promote/hold/rollback recommendation from
baseline vs variant metrics.

## Run

```bash
dart run tool/match_experiment_report.dart --input reports/experiment_input.json
```

Optional:

```bash
dart run tool/match_experiment_report.dart \
  --input reports/experiment_input.json \
  --output reports/experiment_report.json \
  --fail-on rollback
```

`--fail-on` sets process exit code to `1` when the decision matches the value.
Useful for CI gates.

## Input JSON

```json
{
  "experimentId": "exp_match_1",
  "baselineVariantId": "control",
  "variantId": "distance_decay_v1",
  "baseline": {
    "connectToMatchRate": 0.20,
    "matchToFirstMessageRate": 0.40,
    "conversationRetention7dRate": 0.30,
    "responseRate": 0.50,
    "medianReplyDelayMs": 45000,
    "conversationDepth": 6.0,
    "sampleSize": 500
  },
  "variant": {
    "connectToMatchRate": 0.22,
    "matchToFirstMessageRate": 0.42,
    "conversationRetention7dRate": 0.30,
    "responseRate": 0.53,
    "medianReplyDelayMs": 43000,
    "conversationDepth": 6.4,
    "sampleSize": 520
  },
  "guardrails": {
    "minSampleSize": 200,
    "minConnectToMatchLift": 0.01,
    "minMatchToFirstMessageLift": 0.01,
    "maxRetentionDrop": 0.0,
    "minResponseRateLift": 0.01,
    "minConversationDepthLift": 0.1,
    "maxMedianReplyDelayIncreaseMs": 5000
  }
}
```

## Output JSON

Contains:
- `decision`: `promote` | `hold` | `rollback`
- `reasons`: machine-readable reason codes
- `deltas`: KPI deltas vs baseline
  - Includes optional conversation-quality deltas when provided:
    - `responseRate`
    - `medianReplyDelayMs`
    - `conversationDepth`
- experiment identifiers and timestamp

## GitHub Actions

Workflow: `.github/workflows/match-experiment-evaluation.yml`

- Manual trigger with configurable `input_path`, `output_path`, and `fail_on`
- Weekly scheduled run (Monday) using:
  - input: `reports/match_experiment_input.json`
  - output: `reports/match_experiment_report.json`
  - fail-on: `rollback`
