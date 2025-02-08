#!/usr/bin/env bash

# Enable strict error handling
set -euo pipefail
IFS=$'\n\t'

# Constants
readonly ZSHRC_FILE="$HOME/.zshrc"
readonly ZSHRC_BACKUP="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
readonly OH_MY_ZSH_DIR="$HOME/.oh-my-zsh"
readonly ZSH_CUSTOM_DIR="${ZSH_CUSTOM:-$OH_MY_ZSH_DIR/custom}"
readonly REQUIRED_COMMANDS=(git curl zsh)
readonly LOG_FILE="/tmp/zsh_setup_$(date +%Y%m%d_%H%M%S).log"

# Color constants
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Theme options with descriptions
declare -A THEME_DESCRIPTIONS=(
    ["robbyrussell"]="The default theme - simple and clean"
    ["agnoster"]="Powerline-style theme with git integration"
    ["powerlevel10k"]="Fast and feature-rich theme with many customization options"
    ["spaceship"]="Minimalistic and powerful theme for astronauts"
    ["af-magic"]="Magical theme with git information"
    ["bira"]="Two-line prompt with git and virtual env support"
    ["dallas"]="Dark theme with time and directory info"
    ["jonathan"]="Clean theme with git status"
    ["candy"]="Sweet and colorful theme"
    ["fino"]="Elegant theme with git indicators"
)

# Global variables for user selections
SELECTED_THEME=""
SELECTED_EDITOR=""
declare -a SELECTED_PLUGINS=()
declare -a BASIC_PLUGINS=(
    "git"
    "fzf"
    "zsh-syntax-highlighting"
    "zsh-autosuggestions"
    "colorize"
    "command-not-found"
    "history-substring-search"
)

# Logging functions
log() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE" >&2
}

# Select theme function
select_theme() {
    echo -e "\n${BLUE}Available themes:${NC}\n"
    local i=1
    local themes=()
    
    for theme in "${!THEME_DESCRIPTIONS[@]}"; do
        themes+=("$theme")
        printf "${GREEN}%2d)${NC} %-20s - %s\n" $i "$theme" "${THEME_DESCRIPTIONS[$theme]}"
        ((i++))
    done
    
    while true; do
        echo -e "\n${YELLOW}Select a theme (1-${#themes[@]}):${NC} "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#themes[@]}" ]; then
            SELECTED_THEME="${themes[$((selection-1))]}"
            break
        else
            error "Invalid selection. Please choose a number between 1 and ${#themes[@]}"
        fi
    done
    
    if [ "$SELECTED_THEME" = "powerlevel10k" ]; then
        install_powerlevel10k
    fi
    
    log "Selected theme: $SELECTED_THEME"
}

# Select editor function
select_editor() {
    echo -e "\n${BLUE}Select your preferred text editor:${NC}"
    local editors=("vim" "nano" "code" "nvim" "emacs" "custom")
    local i=1
    
    for editor in "${editors[@]}"; do
        if [ "$editor" = "custom" ]; then
            printf "${GREEN}%2d)${NC} Custom (specify your own)\n" $i
        else
            if command -v "$editor" &> /dev/null; then
                printf "${GREEN}%2d)${NC} %s ${GREEN}(installed)${NC}\n" $i "$editor"
            else
                printf "${GREEN}%2d)${NC} %s ${YELLOW}(not installed)${NC}\n" $i "$editor"
            fi
        fi
        ((i++))
    done
    
    while true; do
        echo -e "\n${YELLOW}Select editor (1-${#editors[@]}):${NC} "
        read -r selection
        
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#editors[@]}" ]; then
            if [ "${editors[$((selection-1))]}" = "custom" ]; then
                echo -e "${YELLOW}Enter your preferred editor command:${NC} "
                read -r SELECTED_EDITOR
            else
                SELECTED_EDITOR="${editors[$((selection-1))]}"
            fi
            break
        else
            error "Invalid selection. Please choose a number between 1 and ${#editors[@]}"
        fi
    done
    
    log "Selected editor: $SELECTED_EDITOR"
}

# Select additional plugins function
select_additional_plugins() {
    echo -e "\n${BLUE}Select additional plugins to install:${NC}"
    local available_plugins=(
        "kubectl:Kubernetes command-line tool autocomplete"
        "npm:Node.js package manager autocomplete"
        "pip:Python package manager autocomplete"
        "python:Python interpreter autocomplete"
        "rust:Rust language support"
        "golang:Go language support"
        "docker:Docker commands autocomplete"
        "docker-compose:Docker Compose autocomplete"
        "terraform:Terraform commands autocomplete"
        "aws:AWS CLI support"
    )
    
    SELECTED_PLUGINS=("${BASIC_PLUGINS[@]}")
    
    for plugin in "${available_plugins[@]}"; do
        local name="${plugin%%:*}"
        local description="${plugin#*:}"
        echo -e "\n${YELLOW}Include ${GREEN}$name${NC} plugin? (${BLUE}$description${NC})"
        echo -e "Enter ${GREEN}y${NC}/${RED}n${NC} [n]: "
        read -r answer
        if [[ "$answer" =~ ^[Yy]$ ]]; then
            SELECTED_PLUGINS+=("$name")
            log "Added plugin: $name"
        fi
    done
}

# Install Powerlevel10k if selected
install_powerlevel10k() {
    log "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM_DIR}/themes/powerlevel10k" || {
        error "Failed to install Powerlevel10k"
        exit 1
    }
    warn "Note: Powerlevel10k requires a Nerd Font to be installed."
    warn "Visit: https://github.com/romkatv/powerlevel10k#manual-font-installation"
}

# Check if running with sudo/root
check_root() {
    if [ "$(id -u)" = "0" ]; then
        error "This script should NOT be run as root or with sudo"
        exit 1
    fi
}

# Check for required commands
check_requirements() {
    log "Checking requirements..."
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            error "Required command not found: $cmd"
            error "Please install it and try again"
            exit 1
        fi
    done
}

# Backup existing .zshrc if it exists
backup_existing_config() {
    if [ -f "$ZSHRC_FILE" ]; then
        log "Creating backup of existing .zshrc..."
        if cp "$ZSHRC_FILE" "$ZSHRC_BACKUP"; then
            log "Backup created at $ZSHRC_BACKUP"
        else
            error "Failed to create backup"
            exit 1
        fi
    fi
}

# Install Oh My Zsh if not already installed
install_oh_my_zsh() {
    if [ ! -d "$OH_MY_ZSH_DIR" ]; then
        log "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log "Oh My Zsh is already installed"
    fi
}

# Install plugins
install_plugins() {
    log "Installing plugins..."
    
    local external_plugins=(
        "zsh-users/zsh-syntax-highlighting"
        "zsh-users/zsh-autosuggestions"
    )
    
    for plugin in "${external_plugins[@]}"; do
        local plugin_name=$(basename "$plugin")
        local plugin_path="$ZSH_CUSTOM_DIR/plugins/$plugin_name"
        
        if [ ! -d "$plugin_path" ]; then
            log "Installing $plugin_name..."
            git clone --depth=1 "https://github.com/$plugin" "$plugin_path" || {
                error "Failed to install $plugin_name"
                return 1
            }
        else
            log "$plugin_name is already installed"
        fi
    done
    
    # Install fzf separately
    if [ ! -d "$HOME/.fzf" ]; then
        log "Installing fzf..."
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf" || {
            error "Failed to clone fzf repository"
            return 1
        }
        "$HOME/.fzf/install" --all || {
            error "Failed to install fzf"
            return 1
        }
    else
        log "fzf is already installed"
    fi
}

# Generate new .zshrc content
generate_zshrc_content() {
    local plugins_str=$(printf "    %s\n" "${SELECTED_PLUGINS[@]}" | paste -sd " " -)
    
    cat << EOF
# Path to your oh-my-zsh installation.
export ZSH="\$HOME/.oh-my-zsh"

# Theme configuration
ZSH_THEME="$SELECTED_THEME"

# Plugin configuration
plugins=($plugins_str)

# Performance optimizations
DISABLE_UNTRACKED_FILES_DIRTY="true"
HIST_STAMPS="yyyy-mm-dd"
COMPLETION_WAITING_DOTS="true"

# History configuration
HISTFILE="\$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

# Editor configuration
export EDITOR='$SELECTED_EDITOR'

# Source Oh My Zsh
source "\$ZSH/oh-my-zsh.sh"

# Configure PATH
export PATH="\$HOME/.local/bin:\$PATH"

# Basic aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias l='ls -l'
alias zshconfig="\$EDITOR ~/.zshrc"
alias ohmyzsh="\$EDITOR ~/.oh-my-zsh"

# FZF configuration
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"

# Auto suggestions configuration
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# Directory navigation
setopt AUTO_CD
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_MINUS

# Completion system configuration
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' list-colors \${(s.:.)LS_COLORS}
zstyle ':completion:*' verbose yes

# Load custom functions if they exist
[ -f ~/.zsh_functions ] && source ~/.zsh_functions

# Load local configuration if it exists
[ -f ~/.zshrc.local ] && source ~/.zshrc.local
EOF
}

# Preview theme function
preview_theme() {
    log "Theme preview instructions:"
    echo -e "${YELLOW}To preview how your prompt will look with ${GREEN}$SELECTED_THEME${YELLOW}:${NC}"
    echo -e "1. After installation, run: ${GREEN}exec zsh${NC}"
    echo -e "2. Try some commands to see how the prompt reacts"
    echo -e "3. If you want to change the theme later, edit ${GREEN}~/.zshrc${NC} and change the ${GREEN}ZSH_THEME${NC} variable"
    
    if [ "$SELECTED_THEME" = "powerlevel10k" ]; then
        echo -e "${YELLOW}Note: Powerlevel10k will start its configuration wizard on first run${NC}"
    fi
    
    if [ "$SELECTED_THEME" = "agnoster" ] || [ "$SELECTED_THEME" = "powerlevel10k" ]; then
        echo -e "${YELLOW}Note: This theme works best with a Powerline-compatible font${NC}"
    fi
}

# Main installation function
main() {
    exec 1> >(tee -a "$LOG_FILE")
    exec 2> >(tee -a "$LOG_FILE" >&2)
    
    log "Starting zsh configuration setup..."
    log "Log file: $LOG_FILE"
    
    check_root
    check_requirements
    backup_existing_config
    install_oh_my_zsh
    select_theme
    select_editor
    select_additional_plugins
    install_plugins
    
    log "Generating new .zshrc..."
    generate_zshrc_content > "$ZSHRC_FILE"
    
    # Create empty local configuration file if it doesn't exist
    touch "$HOME/.zshrc.local"
    
    preview_theme
    
    log "Configuration complete!"
    echo -e "\n${GREEN}Installation completed successfully!${NC}"
    echo -e "\n${YELLOW}To apply the new configuration:${NC}"
    echo -e "1. Run: ${GREEN}exec zsh${NC}"
    echo -e "2. For additional customizations, edit: ${GREEN}~/.zshrc.local${NC}"
}

# Trap errors
trap 'error "An error occurred. Check the log file: $LOG_FILE"' ERR

# Run main function
main "$@"