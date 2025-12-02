#!/usr/bin/env bash
###############################################################################
# macOS Defaults Preview Generator
###############################################################################
# Extracts and generates markdown preview of active macOS defaults from macos.sh
# Usage: ./macos-preview.sh [path-to-macos.sh] [output-file]
#
# Arguments:
#   path-to-macos.sh  Path to macos.sh (default: ./macos.sh)
#   output-file       Output markdown file (default: auto-generated temp file)
#
# Output:
#   Prints the path to the generated markdown file to stdout
###############################################################################

set -e

# Color helper functions
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MACOS_SCRIPT="${1:-$SCRIPT_DIR/macos.sh}"
OUTPUT_FILE="${2:-$(mktemp /tmp/macos-defaults-preview.XXXXXX.md)}"

# Validate macos.sh exists
if [[ ! -f "$MACOS_SCRIPT" ]]; then
  echo -e "${RED}❌ Error: macOS script not found at $MACOS_SCRIPT${NC}" >&2
  exit 1
fi

echo -e "${BLUE}📝 Generating macOS defaults preview...${NC}" >&2

# Write header
cat > "$OUTPUT_FILE" << 'HEADER'
# macOS Defaults Preview

The following preferences will be applied by `scripts/macos.sh`:

---

HEADER

# Parse the script and extract settings with descriptions
current_section=""
previous_comment=""
in_section=false

while IFS= read -r line; do
  # Detect section headers (lines like: # Section Name #)
  if [[ "$line" =~ ^#\ (.*)[[:space:]]+#$ ]]; then
    section="${BASH_REMATCH[1]}"
    section="${section//# /}"

    if [[ -n "$section" && "$section" != "$current_section" ]]; then
      current_section="$section"

      # Close previous table if exists
      if [[ "$in_section" == true ]]; then
        echo "" >> "$OUTPUT_FILE"
      fi

      echo "" >> "$OUTPUT_FILE"
      echo "## $current_section" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
      echo "| Setting | Details |" >> "$OUTPUT_FILE"
      echo "|---------|---------|" >> "$OUTPUT_FILE"
      in_section=true
    fi
    previous_comment=""
    continue
  fi

  # Capture comment lines (descriptions)
  if [[ "$line" =~ ^#\ (.+)$ ]]; then
    comment="${BASH_REMATCH[1]}"
    # Skip lines that are just separators or empty
    if [[ ! "$comment" =~ ^[-=]+$ ]]; then
      if [[ -n "$previous_comment" ]]; then
        previous_comment="$previous_comment $comment"
      else
        previous_comment="$comment"
      fi
    fi
    continue
  fi

  # Extract active command lines (not commented)
  if [[ "$line" =~ ^(defaults|sudo\ defaults|sudo\ pmset|sudo\ systemsetup|networksetup|chflags) ]] && \
     [[ ! "$line" =~ ^# ]]; then

    # Extract the value being set (if applicable)
    value=""
    if [[ "$line" =~ -bool\ (true|false) ]]; then
      value="${BASH_REMATCH[1]}"
      value="**${value}**"
    elif [[ "$line" =~ -int\ ([0-9]+) ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ -float\ ([0-9.]+) ]]; then
      value="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ -string\ [\"\'](.*)[\"\']] ]]; then
      value="${BASH_REMATCH[1]}"
      value="\`$value\`"
    fi

    # Use comment as description, or use a generic one
    description="${previous_comment:-Setting applied}"

    # Add value to description if we have one
    if [[ -n "$value" ]]; then
      echo "| $description | $value |" >> "$OUTPUT_FILE"
    else
      echo "| $description | ✓ |" >> "$OUTPUT_FILE"
    fi

    previous_comment=""
    continue
  fi

  # Reset comment if we hit a non-comment, non-command line
  if [[ ! "$line" =~ ^# ]] && [[ -n "$line" ]]; then
    previous_comment=""
  fi
done < "$MACOS_SCRIPT"

# Write footer
cat >> "$OUTPUT_FILE" << 'FOOTER'

---

**Note:** Commented out lines in the script are NOT included above.

To apply these settings, run: `dotfiles mac:set:defaults`
FOOTER

# Output the file path to stdout (so it can be used by other tools)
echo -e "${GREEN}✓ Preview generated${NC}" >&2
echo "$OUTPUT_FILE"
