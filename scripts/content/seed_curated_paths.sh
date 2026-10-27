#!/bin/bash
# Seeds the curated learning paths into a vocab_content.sqlite and verifies the result.
# Usage: scripts/content/seed_curated_paths.sh <path/to/vocab_content.sqlite>
set -euo pipefail

DB="${1:-}"
if [ -z "$DB" ] || [ ! -f "$DB" ]; then
    echo "Usage: $0 <path/to/vocab_content.sqlite>" >&2
    exit 1
fi

SQL="$(cd "$(dirname "$0")" && pwd)/seed_curated_paths.sql"

sqlite3 "$DB" < "$SQL"

# Every curated path must end up with its full deck list; a short count means a deck title no longer matches.
expected="daily-life-travel:26 business-career:10 academic-research:16"
status=0
for entry in $expected; do
    code="${entry%%:*}"
    want="${entry##*:}"
    got="$(sqlite3 "$DB" "SELECT COUNT(*) FROM path_decks pd JOIN learning_paths p ON p.id = pd.path_id WHERE p.code = '$code';")"
    if [ "$got" != "$want" ]; then
        echo "ERROR: $code has $got decks, expected $want (a deck title in the seed no longer matches)" >&2
        status=1
    else
        echo "OK: $code has $got decks"
    fi
done

fk_violations="$(sqlite3 "$DB" "PRAGMA foreign_key_check;" | wc -l | tr -d ' ')"
if [ "$fk_violations" != "0" ]; then
    echo "ERROR: $fk_violations foreign key violations after seeding" >&2
    status=1
fi

exit $status
