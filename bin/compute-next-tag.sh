#!/usr/bin/env bash
# SPDX-FileCopyrightText: 2026 Slavi Pantaleev
#
# SPDX-License-Identifier: AGPL-3.0-or-later

# Prints the tag that the currently checked out commit should be released as,
# or nothing at all if it does not warrant a release.
#
# Usage: bin/compute-next-tag.sh
#
# Tags look like `v<I hate money version>-<release>`, which is what this
# repository has published since v6.1.5-0 (v7.0.1-0 ... v7.2.1-0):
#
# - if defaults/main.yml points at an I hate money version that has never been
#   released, the release counter restarts at 0 (`v7.3.0-0`)
# - otherwise the counter is incremented (`v7.2.1-1`), but only if something
#   that actually affects the role has changed since the last release
#
# Determining the version from defaults/main.yml, rather than from the commit
# message of the pull request that got merged, makes the result independent of
# the order in which pull requests get merged, and lets any change to the role
# (bugfix, feature, dependency bump) release itself without a human tagging.
# The commit-message approach this replaced only ever fired for commits authored
# by renovate[bot] whose subject happened to contain "docker tag to", within the
# last 20 commits: a Renovate bump that landed behind a handful of other merges
# was silently never released, and a hand-written version bump never was either.

set -euo pipefail

repository_path="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd -- "$repository_path"

defaults_path='defaults/main.yml'

# Paths that shape the behavior of the role for its consumers. A commit
# touching only other paths (a README fix, CI configuration, Molecule tests)
# does not change what a playbook run does, and releasing it would only create
# churn in the repositories that consume this role.
role_defining_paths=(
	'defaults'
	'meta'
	'tasks'
	'templates'
)

# Anchored on `ihatemoney_version:` so that neither a commented-out example nor
# `ihatemoney_container_image_tag`, which is derived from it, can be mistaken
# for it. This is also the exact line the `# renovate:` annotation above it
# tells Renovate to edit, so the two can never drift apart.
version="$(sed -nE 's|^ihatemoney_version:[[:space:]]*"?([^"[:space:]]+)"?.*$|\1|p' "$defaults_path" | head -n1)"

if [ -z "$version" ]; then
	echo >&2 "Could not determine the I hate money version from $defaults_path"
	exit 1
fi

# I hate money's own version is carried without a leading `v` (upstream's
# container tags have no `v` either), while this repository's tags do have one.
# Tolerate a leading `v` in the value so that a future change of convention
# does not produce a doubled prefix.
tag_prefix="v${version#v}-"

# Of all releases of this version, the highest release number. Sorted
# numerically, so that -10 is recognized as newer than -9.
last_release="$(git tag --list "${tag_prefix}*" | sed -e "s|^${tag_prefix}||" | grep -E '^[0-9]+$' | sort -n | tail -n1 || true)"

if [ -z "$last_release" ]; then
	echo >&2 "Version $version has never been released"
	echo "${tag_prefix}0"
	exit 0
fi

previous_tag="${tag_prefix}${last_release}"

if git diff --quiet "$previous_tag" HEAD -- "${role_defining_paths[@]}"; then
	echo >&2 "Nothing affecting the role has changed since $previous_tag"
	exit 0
fi

echo >&2 "The role has changed since $previous_tag"
echo "${tag_prefix}$((last_release + 1))"
