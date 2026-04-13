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

tmux split-window -h -t $SESSION
tmux send-keys -t $SESSION:0.1 "$VOLTRON view reg" Enter

tmux select-pane -t $SESSION:0.0
tmux split-window -v -t $SESSION

tmux select-pane -t $SESSION:0.1
tmux split-window -v -t $SESSION

tmux select-pane -t $SESSION:0.2
tmux split-window -h -t $SESSION

tmux select-pane -t $SESSION:0.0
tmux split-window -h -t $SESSION

tmux send-keys -t $SESSION:0.0 "$VOLTRON view disasm" Enter
tmux send-keys -t $SESSION:0.1 "$VOLTRON view bp" Enter
tmux send-keys -t $SESSION:0.2 "lldb $BINARY" Enter
tmux send-keys -t $SESSION:0.3 "$VOLTRON view stack" Enter
tmux send-keys -t $SESSION:0.4 "$VOLTRON view bt" Enter

tmux select-pane -t $SESSION:0.2

tmux attach -t $SESSION
