# Fixture: contributor-single

**Purpose:** Single-author git repo fixture.

`make_fixture_repo` creates the git repo with only the default `fixture@example.com` seed commit — satisfies D-20 single-author heuristic: `git log --all --format='%ae' | sort -u | wc -l` == 1.

`bin/ingest.sh` contributor auto-detect MUST omit the `contributor::` field entirely on this fixture.

## Triggers

- COLAB-04 single-author case: when the repo has exactly one unique commit author email, auto-detect treats this as a solo-dev repo and writes no `contributor::` field to the ingest log entry.

## Contents

- (no seeded files beyond `.gitkeep`) — `make_fixture_repo` creates the single initial commit itself.
