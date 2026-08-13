#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 5 ]]; then
	printf 'usage: %s <workflow> <repository> <ref> <output-dir> <artifact>...\n' "$0" >&2
	exit 2
fi

workflow="$1"
repository="$2"
ref="$3"
output_dir="$4"
shift 4

started_at="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
if ! gh workflow run "$workflow" --repo "$repository" --ref "$ref"; then
	echo "Unable to dispatch $workflow in $repository. Set GODOT_SECURE_TOKEN with Actions write access." >&2
	exit 1
fi

run_id=""
for _ in $(seq 1 120); do
	run_json="$(gh run list \
		--repo "$repository" \
		--workflow "$workflow" \
		--branch "$ref" \
		--event workflow_dispatch \
		--limit 20 \
		--json databaseId,createdAt)"
	run_id="$(jq -r --arg started_at "$started_at" \
		'map(select(.createdAt >= $started_at)) | sort_by(.createdAt) | last | .databaseId // empty' \
		<<< "$run_json")"
	if [[ -n "$run_id" ]]; then
		break
	fi
	sleep 5
done

if [[ -z "$run_id" ]]; then
	echo "Unable to find the dispatched $workflow run in $repository." >&2
	exit 1
fi

gh run watch "$run_id" --repo "$repository" --compact --interval 30 --exit-status

for artifact in "$@"; do
	artifact_dir="$output_dir/$artifact"
	mkdir -p "$artifact_dir"
	gh run download "$run_id" --repo "$repository" --name "$artifact" --dir "$artifact_dir"
done
