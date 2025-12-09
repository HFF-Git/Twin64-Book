#!/usr/bin/env bash
set -u
# macOS-friendly script to create LaTeX command files from a template.
# It writes files to the "chapter-simulator-commands" directory next to this script.

# --- Determine script directory (absolute) so output dir is predictable) ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$SCRIPT_DIR/chapter-simulator-commands"

# Template (uses HELP as placeholder)
read -r -d '' TEMPLATE <<'EOF'
%--------------------------------------------------------------------------------
%
%
%--------------------------------------------------------------------------------
\pagebreak
\section*{HELP - list help info}
\addcontentsline{toc}{section}{HELP - ...}

%--------------------------------------------------------------------------------
\begin{iPageDescEntry}{Syntax}
\texttt{HELP } \\
\end{iPageDescEntry}

%--------------------------------------------------------------------------------
\begin{iPageDescEntry}{Description}

The \texttt{HELP} command ...

\end{iPageDescEntry}

%--------------------------------------------------------------------------------
\begin{iPageDescOpEntry}{Example}
\begin{lstlisting}[style=iPageOpStyle]

... 

\end{lstlisting}
\end{iPageDescOpEntry}

%--------------------------------------------------------------------------------
\begin{iPageDescEntry}{Notes}
None.
\end{iPageDescEntry}
EOF

# --- Input check ---
if [ $# -lt 1 ]; then
    echo "Usage: $0 <word1> [word2] ..."
    exit 1
fi

mkdir -p "$TARGET_DIR" || { echo "ERROR: cannot create $TARGET_DIR"; exit 2; }

# --- Create files ---
for WORD in "$@"; do
    # sanitize simple problematic characters for filename (keeps alnum, -, _)
    SAFE_WORD="$(printf '%s' "$WORD" | tr -cd '[:alnum:]\-_')"
    if [ -z "$SAFE_WORD" ]; then
        echo "Skipping empty/invalid word: '$WORD'"
        continue
    fi

    # Uppercase the placeholder replacement in a macOS-compatible way
    UWORD="$(printf '%s' "$SAFE_WORD" | tr '[:lower:]' '[:upper:]')"

    FILENAME="$TARGET_DIR/chapter-sim-cmd-${SAFE_WORD}.tex"
    ABS_PATH="$(cd "$(dirname "$FILENAME")" && pwd)/$(basename "$FILENAME")"

    # perform replacement and write atomically
    TMPFILE="$(mktemp "${TARGET_DIR}/.tmp.XXXXXX")" || { echo "ERROR: mktemp failed"; exit 3; }
    printf '%s\n' "${TEMPLATE//HELP/$UWORD}" > "$TMPFILE" || { echo "ERROR: write failed to $TMPFILE"; rm -f "$TMPFILE"; exit 4; }
    mv -f "$TMPFILE" "$FILENAME" || { echo "ERROR: move failed"; rm -f "$TMPFILE"; exit 5; }

    # verify and report
    if [ -f "$FILENAME" ]; then
        echo "Created: $ABS_PATH"
        echo "Size: $(stat -f%z "$FILENAME") bytes"
        echo "----- start of file preview -----"
        head -n 20 "$FILENAME"
        echo "------ end of preview ------"
    else
        echo "ERROR: file not found after creation: $ABS_PATH"
    fi
done

echo "All done. Files are in: $TARGET_DIR"
