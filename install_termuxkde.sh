#!/bin/bash

# ════════════════════════════════════════════════
#   TermuxKDE Installer — by xenoZ0x (c) 2026
# ════════════════════════════════════════════════

LOG="$HOME/termuxkde_error.log"
START_TIME=$(date +%s)
BYTES_BEFORE=$(cat /proc/net/dev 2>/dev/null | awk '/wlan0|rmnet/{sum+=$2} END{print sum+0}')

RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()    { echo -e "${CYAN}[*]${RESET} $1"; }
detail()  { echo -e "${DIM}    └─ $1${RESET}"; }
success() { echo -e "${GREEN}[✓]${RESET} $1"; }
error()   { echo -e "${RED}[✗]${RESET} $1${DIM} — cat ~/termuxkde_error.log${RESET}"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}── $1 ──${RESET}"; }

# ── Terminal Size Check ───────────────────────────
REQUIRED_COLS=88
REQUIRED_LINES=35

check_terminal_size() {
  local cols lines
  cols=$(tput cols 2>/dev/null || echo "${COLUMNS:-0}")
  lines=$(tput lines 2>/dev/null || echo "${LINES:-0}")

  if [[ "$cols" -lt "$REQUIRED_COLS" || "$lines" -lt "$REQUIRED_LINES" ]]; then
    clear
    echo -e "${RED}${BOLD}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║        Terminal Size Too Small!          ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${RESET}"
    echo -e "  ${DIM}Current size :${RESET} ${RED}${BOLD}${cols}x${lines}${RESET}"
    echo -e "  ${DIM}Required     :${RESET} ${GREEN}${BOLD}${REQUIRED_COLS}x${REQUIRED_LINES}${RESET}"
    echo ""
    echo -e "  ${YELLOW}${BOLD}How to resize in Termux:${RESET}"
    echo -e "  ${DIM}1. Pinch-zoom out on your keyboard to shrink font size${RESET}"
    echo -e "  ${DIM}2. Or long-press on the terminal → More → Resize Terminal${RESET}"
    echo -e "  ${DIM}3. Or run this command to set font size manually:${RESET}"
    echo ""
    echo -e "     ${CYAN}tput reset${RESET}"
    echo -e "     ${CYAN}# Then pinch-zoom until you see ${REQUIRED_COLS}x${REQUIRED_LINES}${RESET}"
    echo ""
    echo -e "  ${DIM}Check current size anytime with:${RESET}"
    echo -e "     ${CYAN}echo \"\${COLUMNS}x\${LINES}\"${RESET}"
    echo ""
    echo -e "  ${DIM}Once resized, re-run the installer:${RESET}"
    echo -e "     ${CYAN}bash install_termuxkde.sh${RESET}"
    echo ""
    exit 1
  fi
}

# ── Detect Shell ──────────────────────────────────
detect_shell() {
  if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
    RC_FILE="$HOME/.zshrc"
    SHELL_NAME="zsh"
  else
    RC_FILE="$HOME/.bashrc"
    SHELL_NAME="bash"
  fi
}

# ── Banner ────────────────────────────────────────
show_banner() {
  clear
  echo -e "${BOLD}${CYAN}"
  echo "  ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗██╗  ██╗██████╗ ███████╗"
  echo "  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝██║ ██╔╝██╔══██╗██╔════╝"
  echo "     ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝ █████╔╝ ██║  ██║█████╗  "
  echo "     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗ ██╔═██╗ ██║  ██║██╔══╝  "
  echo "     ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║  ██╗██████╔╝███████╗"
  echo "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝"
  echo -e "${RESET}"
  echo -e "${YELLOW}KDE Plasma for Termux${RESET} ${DIM}by xenoZ0x (c) 2026${RESET}"
}

# ── Confirmation ──────────────────────────────────
confirm() {
  echo -e "${DIM}Shell: ${SHELL_NAME} → ${RC_FILE}${RESET}"
  echo -ne "${YELLOW}Continue? [Y/n]:${RESET} "
  read -r CHOICE
  case "$CHOICE" in
    Y|y|"") echo -e "${GREEN}Starting...${RESET}\n" ;;
    *)       echo -e "${RED}Cancelled.${RESET}"; exit 0 ;;
  esac
}

# ── Silent pkg wrapper ────────────────────────────
pkg_silent() {
  local desc="$1" explain="$2"; shift 2
  info "$desc"
  detail "$explain"
  DEBIAN_FRONTEND=noninteractive yes | pkg "$@" \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    >> "$LOG" 2>&1 || error "Failed: $desc"
  success "$desc"
}

# ── Steps ─────────────────────────────────────────
update_system() {
  step "Update & Upgrade"
  info "Updating package lists"
  detail "Fetching latest index from Termux repos..."
  DEBIAN_FRONTEND=noninteractive yes | pkg update >> "$LOG" 2>&1 || error "Failed: update"
  success "Package lists updated"
  info "Upgrading packages"
  detail "Upgrading all outdated packages..."
  DEBIAN_FRONTEND=noninteractive yes | pkg upgrade \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    >> "$LOG" 2>&1 || error "Failed: upgrade"
  success "Packages upgraded"
}

install_x11() {
  step "X11 Setup"
  pkg_silent "Installing x11-repo"           "Adding Termux X11 package repository..."        install x11-repo
  pkg_silent "Installing termux-x11-nightly" "Installing X11 display bridge for Termux:X11..." install termux-x11-nightly
}

install_kde() {
  step "KDE Plasma"
  pkg_silent "Installing Plasma desktop"    "Installing KDE shell, window manager, core components..." install plasma
  pkg_silent "Installing KDE Applications" "Installing file manager, terminal, text editor..."         install kde-applications
}

# ── Setup Scripts, MOTD & Uninstaller ────────────
setup_aliases() {
  step "Shell Config"

  mkdir -p "$HOME/bin"

  # ── startplasma ──
  cat > "$HOME/bin/startplasma" << 'EOF'
#!/bin/bash
nohup termux-x11 -xstartup startplasma-x11 > /dev/null 2>&1 &
disown
sleep 2
echo -e "\033[1m\033[32m[✓] KDE Plasma started\033[0m  \033[2m— stop: stoplasma\033[0m"
EOF

  # ── stoplasma ──
  cat > "$HOME/bin/stoplasma" << 'EOF'
#!/bin/bash
pkill -f termux-x11 > /dev/null 2>&1
pkill -f startplasma-x11 > /dev/null 2>&1
echo -e "\033[1m\033[33m[■] KDE Plasma stopped\033[0m  \033[2m— start: startplasma\033[0m"
EOF

  # ── TermuxKDE-Remove ──
  cat > "$HOME/bin/TermuxKDE-Remove" << 'EOF'
#!/bin/bash
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

echo -e "${BOLD}${RED}"
echo "  ╔══════════════════════════════════════════╗"
echo "  ║         TermuxKDE — UNINSTALLER          ║"
echo "  ╚══════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "${YELLOW}${BOLD}⚠ WARNING:${RESET} This will permanently remove:"
echo -e "${DIM}  • startplasma, stoplasma, TermuxKDE-Remove scripts"
echo -e "  • All TermuxKDE entries from your shell config"
echo -e "  • KDE Plasma & kde-applications packages"
echo -e "  • termux-x11-nightly package"
echo -e "  • termuxkde_error.log${RESET}"
echo ""
echo -ne "${YELLOW}Are you sure? This cannot be undone. [y/N]:${RESET} "
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo -e "${GREEN}Uninstall cancelled.${RESET}"
  exit 0
fi
echo ""

if [ -n "$ZSH_VERSION" ] || [ "$(basename "$SHELL")" = "zsh" ]; then
  RC_FILE="$HOME/.zshrc"
else
  RC_FILE="$HOME/.bashrc"
fi

echo -e "\033[36m[*]\033[0m Removing launcher scripts..."
rm -f "$HOME/bin/startplasma" "$HOME/bin/stoplasma" "$HOME/bin/TermuxKDE-Remove"
echo -e "\033[32m[✓]\033[0m Scripts removed"

echo -e "\033[36m[*]\033[0m Cleaning shell config..."
sed -i '/# ── TermuxKDE ──/,+10d' "$RC_FILE" 2>/dev/null
echo -e "\033[32m[✓]\033[0m Shell config cleaned"

echo -e "\033[36m[*]\033[0m Uninstalling KDE packages..."
DEBIAN_FRONTEND=noninteractive yes | pkg uninstall -y \
  kde-applications plasma termux-x11-nightly > /dev/null 2>&1
echo -e "\033[32m[✓]\033[0m Packages removed"

echo -e "\033[36m[*]\033[0m Removing log file..."
rm -f "$HOME/termuxkde_error.log"
echo -e "\033[32m[✓]\033[0m Log removed"

echo ""
echo -e "${GREEN}${BOLD}TermuxKDE has been fully removed.${RESET}"
echo -e "${DIM}Restart Termux to apply changes.${RESET}"
EOF

  chmod +x "$HOME/bin/startplasma" "$HOME/bin/stoplasma" "$HOME/bin/TermuxKDE-Remove"
  success "Launcher scripts created"

  # ── Check for duplicate before writing to RC ──
  if grep -q "# ── TermuxKDE ──" "$RC_FILE" 2>/dev/null; then
    info "TermuxKDE entries already exist in ${RC_FILE} — skipping"
  else
    cat >> "$RC_FILE" << 'RCEOF'

# ── TermuxKDE ──
export PATH="$HOME/bin:$PATH"
echo -e "\033[1m\033[36m"
echo "  ╔══════════════════════════╗"
echo "  ║       TermuxKDE          ║"
echo "  ╠══════════════════════════╣"
echo "  ║  startplasma  → Start    ║"
echo "  ║  stoplasma    → Stop     ║"
echo "  ╠══════════════════════════╣"
echo -e "  ║  \033[0m\033[1m\033[31mTermuxKDE-Remove\033[0m\033[1m\033[36m → Uninstall ║"
echo "  ╚══════════════════════════╝"
echo -e "\033[0m\033[2m  ⚠ TermuxKDE-Remove will delete everything\033[0m"
RCEOF
    success "MOTD written to ${RC_FILE}"
  fi

  info "Activating config"
  detail "Running source on ${RC_FILE}..."
  # shellcheck disable=SC1090
  source "$RC_FILE" > /dev/null 2>&1
  success "Config activated (${SHELL_NAME})"
}

# ── Summary ───────────────────────────────────────
show_summary() {
  local END_TIME ELAPSED BYTES_AFTER BYTES_USED MB_USED MINS SECS
  END_TIME=$(date +%s)
  ELAPSED=$((END_TIME - START_TIME))
  BYTES_AFTER=$(cat /proc/net/dev 2>/dev/null | awk '/wlan0|rmnet/{sum+=$2} END{print sum+0}')
  BYTES_USED=$((BYTES_AFTER - BYTES_BEFORE))
  MB_USED=$(echo "scale=1; $BYTES_USED / 1048576" | bc 2>/dev/null || echo "?")
  MINS=$(( ELAPSED / 60 ))
  SECS=$(( ELAPSED % 60 ))

  clear
  echo -e "${BOLD}${CYAN}"
  echo "  ████████╗███████╗██████╗ ███╗   ███╗██╗   ██╗██╗  ██╗██╗  ██╗██████╗ ███████╗"
  echo "  ╚══██╔══╝██╔════╝██╔══██╗████╗ ████║██║   ██║╚██╗██╔╝██║ ██╔╝██╔══██╗██╔════╝"
  echo "     ██║   █████╗  ██████╔╝██╔████╔██║██║   ██║ ╚███╔╝ █████╔╝ ██║  ██║█████╗  "
  echo "     ██║   ██╔══╝  ██╔══██╗██║╚██╔╝██║██║   ██║ ██╔██╗ ██╔═██╗ ██║  ██║██╔══╝  "
  echo "     ██║   ███████╗██║  ██║██║ ╚═╝ ██║╚██████╔╝██╔╝ ██╗██║  ██╗██████╔╝███████╗"
  echo "     ╚═╝   ╚══════╝╚═╝  ╚═╝╚═╝     ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝ ╚══════╝"
  echo -e "${RESET}"
  echo -e "${GREEN}${BOLD}✓ Installation Complete!${RESET}"
  echo -e "${DIM}────────────────────────────────────${RESET}"
  echo -e "${DIM}⏱  Time  :${RESET} ${BOLD}${MINS}m ${SECS}s${RESET}"
  echo -e "${DIM}📶 Data  :${RESET} ${BOLD}${MB_USED} MB${RESET}"
  echo -e "${DIM}🐚 Shell :${RESET} ${BOLD}${SHELL_NAME} → ${RC_FILE}${RESET}"
  echo -e "${DIM}────────────────────────────────────${RESET}"
  echo -e "${GREEN}startplasma${RESET}        →  Launch KDE Plasma"
  echo -e "${YELLOW}stoplasma${RESET}          →  Stop the Desktop"
  echo -e "${RED}TermuxKDE-Remove${RESET}   →  Uninstall everything"
  echo -e "${DIM}⚠ TermuxKDE-Remove will delete all project files & packages${RESET}"
  echo -e "${DIM}────────────────────────────────────${RESET}"
  echo -e "${BOLD}<3 Enjoy Your KDE — xenoZ0x${RESET}"
}

# ── Main ──────────────────────────────────────────
main() {
  check_terminal_size
  > "$LOG"
  detect_shell
  show_banner
  confirm
  update_system
  install_x11
  install_kde
  setup_aliases
  show_summary
}

main
