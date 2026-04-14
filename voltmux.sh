#!/bin/bash
BINARY=${1:-""}
SESSION="voltron"
VOLTRON="$HOME/Library/Python/3.9/bin/voltron"

if [ -n "$TMUX" ]; then
    echo "Already inside a tmux session. Please run outside of tmux."
    exit 1
fi

tmux kill-session -t $SESSION 2>/dev/null || true

tmux new-session -d -s $SESSION

# Split right column (25% width)
tmux split-window -h -p 25 -t $SESSION

# Right column: reg on top (~60%), bp middle, bt bottom
tmux select-pane -t $SESSION:0.1
tmux send-keys -t $SESSION:0.1 "$VOLTRON view reg" Enter

tmux split-window -v -p 30 -t $SESSION:0.1
tmux send-keys -t $SESSION:0.2 "$VOLTRON view bp" Enter

tmux split-window -v -p 50 -t $SESSION:0.2
tmux send-keys -t $SESSION:0.3 "$VOLTRON view bt" Enter

# Left column: disasm top, lldb middle, stack bottom
tmux select-pane -t $SESSION:0.0
tmux split-window -v -p 50 -t $SESSION:0.0

tmux select-pane -t $SESSION:0.1
tmux split-window -v -p 40 -t $SESSION:0.1

tmux send-keys -t $SESSION:0.0 "$VOLTRON view disasm" Enter
tmux send-keys -t $SESSION:0.1 "lldb $BINARY" Enter
tmux send-keys -t $SESSION:0.2 "$VOLTRON view stack" Enter

tmux select-pane -t $SESSION:0.1

tmux attach -t $SESSION
