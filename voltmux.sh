#!/bin/bash
BINARY=${1:-""}
SESSION="voltron"

tmux new-session -d -s $SESSION

# registers
tmux split-window -h -t $SESSION
tmux send-keys -t $SESSION:0.1 "voltron view reg" Enter

# disasm | bp
tmux select-pane -t $SESSION:0.0
tmux split-window -v -t $SESSION


# stack|bt
tmux select-pane -t $SESSION:0.1
tmux split-window -v -t $SESSION

# stack | bt
tmux select-pane -t $SESSION:0.2
tmux split-window -h -t $SESSION

# disasm | bp
tmux select-pane -t $SESSION:0.0
tmux split-window -h -t $SESSION

# Commands
tmux send-keys -t $SESSION:0.0 "voltron view disasm" Enter
tmux send-keys -t $SESSION:0.1 "voltron view bp" Enter
tmux send-keys -t $SESSION:0.2 "lldb $BINARY" Enter
tmux send-keys -t $SESSION:0.3 "voltron view stack" Enter
tmux send-keys -t $SESSION:0.4 "voltron view bt" Enter

# Focusing lldb
tmux select-pane -t $SESSION:0.2

tmux attach -t $SESSION
