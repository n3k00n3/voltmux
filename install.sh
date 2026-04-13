#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${CYAN}[*]${NC} $1"; }
ok()     { echo -e "${GREEN}[✓]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!]${NC} $1"; }
err()    { echo -e "${RED}[✗]${NC} $1"; exit 1; }

echo -e "${CYAN}"
echo "  ██╗   ██╗ ██████╗ ██╗  ████████╗███╗   ███╗██╗   ██╗██╗  ██╗"
echo "  ██║   ██║██╔═══██╗██║  ╚══██╔══╝████╗ ████║██║   ██║╚██╗██╔╝"
echo "  ██║   ██║██║   ██║██║     ██║   ██╔████╔██║██║   ██║ ╚███╔╝ "
echo "  ╚██╗ ██╔╝██║   ██║██║     ██║   ██║╚██╔╝██║██║   ██║ ██╔██╗ "
echo "   ╚████╔╝ ╚██████╔╝███████╗██║   ██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗"
echo "    ╚═══╝   ╚═════╝ ╚══════╝╚═╝   ╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝"
echo -e "${NC}"
echo -e "  voltmux — Voltron + tmux installer"
echo ""

detect_pkg_manager() {
    if command -v apt-get &>/dev/null; then
        PKG="apt-get"
        INSTALL="sudo apt-get install -y"
    elif command -v dnf &>/dev/null; then
        PKG="dnf"
        INSTALL="sudo dnf install -y"
    elif command -v pacman &>/dev/null; then
        PKG="pacman"
        INSTALL="sudo pacman -S --noconfirm"
    elif command -v brew &>/dev/null; then
        PKG="brew"
        INSTALL="brew install"
    else
        err "No package manager found. Please install tmux manually."
    fi
    ok "Package manager detected: $PKG"
}

install_tmux() {
    if command -v tmux &>/dev/null; then
        ok "tmux already installed: $(tmux -V)"
        return
    fi
    log "Installing tmux..."
    $INSTALL tmux || err "Failed to install tmux"
    ok "tmux installed: $(tmux -V)"
}

configure_tmux() {
    TMUX_CONF="$HOME/.tmux.conf"
    if grep -q "mouse on" "$TMUX_CONF" 2>/dev/null; then
        ok "Mouse already enabled in tmux"
    else
        log "Enabling mouse support in tmux..."
        echo "set -g mouse on" >> "$TMUX_CONF"
        ok "Mouse enabled in $TMUX_CONF"
    fi
}

check_python() {
    if command -v python3 &>/dev/null; then
        PYTHON="python3"
        PIP="pip3"
    elif command -v python &>/dev/null; then
        PYTHON="python"
        PIP="pip"
    else
        err "Python not found. Please install Python 3 before continuing."
    fi
    ok "Python detected: $($PYTHON --version)"
}

install_system_deps() {
    log "Installing system dependencies..."
    if [ "$PKG" = "apt-get" ]; then
        sudo apt-get update -qq
        $INSTALL python3-pip python3-dev libreadline-dev || warn "Some dependencies may have failed"
    elif [ "$PKG" = "dnf" ]; then
        $INSTALL python3-pip python3-devel readline-devel || warn "Some dependencies may have failed"
    elif [ "$PKG" = "pacman" ]; then
        $INSTALL python-pip readline || warn "Some dependencies may have failed"
    fi
    ok "System dependencies installed"
}

install_voltron() {
    if $PIP show voltron &>/dev/null 2>&1; then
        ok "Voltron already installed"
    else
        log "Installing Voltron..."
        $PIP install voltron --user || $PIP install voltron --break-system-packages || err "Failed to install Voltron"
        ok "Voltron installed"
    fi

    VOLTRON_PATH=$($PYTHON -c "import voltron; import os; print(os.path.dirname(voltron.__file__))" 2>/dev/null || echo "")
    if [ -z "$VOLTRON_PATH" ]; then
        warn "Could not detect Voltron path automatically"
    fi
}

configure_lldbinit() {
    LLDBINIT="$HOME/.lldbinit"

    if [ -z "$VOLTRON_PATH" ]; then
        warn "Skipping .lldbinit — Voltron path not found"
        return
    fi

    ENTRY="$VOLTRON_PATH/entry.py"

    if [ ! -f "$ENTRY" ]; then
        warn "entry.py not found at $ENTRY — please check your Voltron installation"
        return
    fi

    if grep -q "voltron" "$LLDBINIT" 2>/dev/null; then
        ok ".lldbinit already configured"
    else
        log "Configuring ~/.lldbinit..."
        echo "" >> "$LLDBINIT"
        echo "# Voltron" >> "$LLDBINIT"
        echo "command script import $ENTRY" >> "$LLDBINIT"
        ok "Voltron added to ~/.lldbinit"
    fi
}

create_debug_script() {
    SCRIPT="$HOME/debug.sh"
    log "Creating $SCRIPT..."

    cat > "$SCRIPT" << 'EOF'
#!/bin/bash
BINARY=${1:-""}
SESSION="voltron"

tmux kill-session -t $SESSION 2>/dev/null || true

tmux new-session -d -s $SESSION

tmux split-window -h -p 15 -t $SESSION
tmux send-keys -t $SESSION:0.1 "voltron view reg" Enter

tmux select-pane -t $SESSION:0.0
tmux split-window -v -p 65 -t $SESSION

tmux select-pane -t $SESSION:0.0
tmux split-window -h -p 44 -t $SESSION
tmux send-keys -t $SESSION:0.0 "voltron view disasm" Enter
tmux send-keys -t $SESSION:0.1 "voltron view bp" Enter

tmux select-pane -t $SESSION:0.2
tmux split-window -v -p 30 -t $SESSION

tmux select-pane -t $SESSION:0.3
tmux split-window -h -p 40 -t $SESSION
tmux send-keys -t $SESSION:0.3 "voltron view stack" Enter
tmux send-keys -t $SESSION:0.4 "voltron view bt" Enter

tmux send-keys -t $SESSION:0.2 "lldb $BINARY" Enter

tmux select-pane -t $SESSION:0.2

tmux attach -t $SESSION
EOF

    chmod +x "$SCRIPT"
    ok "Debug script created at $SCRIPT"
}

print_summary() {
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Installation complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  Usage:"
    echo -e "    ${CYAN}~/debug.sh ./binary${NC}   — launch tmux with full layout"
    echo -e "    ${CYAN}~/debug.sh${NC}             — launch without a binary"
    echo ""
    echo -e "  Inside LLDB:"
    echo -e "    ${CYAN}b main${NC}   → set breakpoint at main"
    echo -e "    ${CYAN}run${NC}      → Voltron panels update automatically"
    echo ""
}

detect_pkg_manager
install_tmux
configure_tmux
check_python
install_system_deps
install_voltron
configure_lldbinit
create_debug_script
print_summary
