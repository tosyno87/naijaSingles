# Migration Scripts

These scripts support the Afropeep Firebase migration cutover.

## Scripts
- `export_auth_users.sh`: Export Auth users from source project.
- `import_auth_users.sh`: Import Auth users into destination project.
- `verify_auth_uid_parity.sh`: Compare UID parity across source/destination Auth.
- `cutover_preflight_check.sh`: Validate branch/config/build guardrails before cutover.
- `build_next_production_ios_simulator.sh`: Compile iOS against migrated Firebase config.

## Example flow

```bash
scripts/migration/cutover_preflight_check.sh
scripts/migration/export_auth_users.sh naijasingles-74a75 ./tmp/auth-export.json
scripts/migration/import_auth_users.sh afropeep-xxxx ./tmp/auth-export.json
scripts/migration/verify_auth_uid_parity.sh naijasingles-74a75 afropeep-xxxx
AUTH_MIGRATION_CUTOVER_EPOCH=202603221530 scripts/migration/build_next_production_ios_simulator.sh
```
