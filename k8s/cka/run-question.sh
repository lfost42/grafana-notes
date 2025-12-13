#!/bin/bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: scripts/run-question.sh \"Question-XX Topic\"" >&2
  echo "       scripts/run-question.sh Question-XX" >&2
  exit 1
fi

# Search for directory matching the pattern
QUESTION_PATTERN="$1*"
QUESTION_DIR=$(find . -maxdepth 1 -type d -name "$QUESTION_PATTERN" | head -n 1)

if [[ -z "$QUESTION_DIR" ]]; then
  echo "No question directory found matching '$1'" >&2
  exit 1
fi

# Remove leading ./ if present
QUESTION_DIR="${QUESTION_DIR#./}"

# Check if we found multiple matches (though we only take the first)
MATCH_COUNT=$(find . -maxdepth 1 -type d -name "$QUESTION_PATTERN" | wc -l)
if [[ "$MATCH_COUNT" -gt 1 ]]; then
  echo "Warning: Found $MATCH_COUNT directories matching '$1', using '$QUESTION_DIR'" >&2
fi

SETUP="$QUESTION_DIR/LabSetUp.bash"
QUESTION_TEXT="$QUESTION_DIR/Questions.bash"
SOLUTION="$QUESTION_DIR/SolutionNotes.bash"

[[ -f "$SETUP" ]] || { echo "Missing $SETUP" >&2; exit 1; }
[[ -f "$QUESTION_TEXT" ]] || { echo "Missing $QUESTION_TEXT" >&2; exit 1; }

chmod +x "$SETUP"

echo "==> Running lab setup for $QUESTION_DIR"
"$SETUP"

echo
echo "==> Question"
cat "$QUESTION_TEXT"

echo
if [[ -f "$SOLUTION" ]]; then
  echo "Hints: see $SOLUTION"
fi
