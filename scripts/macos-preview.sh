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

The following defaults will be applied by `scripts/macos.sh`:

---

HEADER

# Extract defaults commands organized by section
current_section=""
while IFS= read -r line; do
  # Detect section headers (lines like: # Section Name #)
  if [[ "$line" =~ ^#\ (.*)[[:space:]]+#$ ]]; then
    section="${BASH_REMATCH[1]}"
    section="${section//# /}"
    if [[ -n "$section" && "$section" != "$current_section" ]]; then
      current_section="$section"
      echo "" >> "$OUTPUT_FILE"
      echo "## $current_section" >> "$OUTPUT_FILE"
      echo "" >> "$OUTPUT_FILE"
    fi
  fi

  # Extract active defaults write commands (not commented)
  if [[ "$line" =~ ^(defaults|sudo\ defaults|sudo\ pmset|sudo\ systemsetup|networksetup|chflags|killall) ]] && \
     [[ ! "$line" =~ ^#.*(defaults|sudo|chflags|killall) ]]; then
    # Clean up the command for display
    clean_line="$line"
    clean_line="${clean_line// 2>\/dev\/null \|\| true/}"
    clean_line="${clean_line// &>\/dev\/null \|\| true/}"
    echo '```bash' >> "$OUTPUT_FILE"
    echo "$clean_line" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
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
