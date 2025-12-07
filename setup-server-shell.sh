#!/usr/bin/env bash
set -e

echo "==> Detecting package manager..."
if command -v apt >/dev/null 2>&1; then
  PKG="apt"
elif command -v apt-get >/dev/null 2>&1; then
  PKG="apt-get"
else
  echo "❌ Підтримуються лише Debian/Ubuntu (apt/apt-get). Вихід."
  exit 1
fi

if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
else
  SUDO=""
fi

echo "==> Updating packages..."
$SUDO $PKG update -y || $SUDO $PKG update

echo "==> Installing base packages (zsh, git, nano, curl, bat)..."
# Якщо bat раптом недоступний – не падаємо, просто без нього
if ! $SUDO $PKG install -y zsh git nano curl bat 2>/dev/null; then
  echo "⚠️ Не вдалось встановити bat, ставимо без нього..."
  $SUDO $PKG install -y zsh git nano curl
fi

echo "==> Installing Oh My Zsh (if not installed)..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  export RUNZSH=no
  export CHSH=no
  export KEEP_ZSHRC=yes
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Oh My Zsh вже встановлено, пропускаю..."
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

echo "==> Installing zsh-autosuggestions..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions вже є, пропускаю..."
fi

echo "==> Installing zsh-syntax-highlighting..."
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting вже є, пропускаю..."
fi

echo "==> Backing up existing ~/.zshrc (if any)..."
if [ -f "$HOME/.zshrc" ]; then
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup-$(date +%Y%m%d-%H%M%S)"
fi

echo "==> Writing new ~/.zshrc (server profile)..."

cat > "$HOME/.zshrc" <<"EOF"
# ----------------------------
# Oh My Zsh / Theme / Plugins
# ----------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"

plugins=(
  git
  z
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source "$ZSH/oh-my-zsh.sh"

# ----------------------------
# Prompt: user@host:/path$  (зелений/жовтий)
# ----------------------------
PROMPT='%{$fg[green]%}%n@%m%{$reset_color%}:%{$fg[yellow]%}%~%{$reset_color%}$ '

# ----------------------------
# Aliases: ls / базові
# ----------------------------
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# ----------------------------
# Git aliases
# ----------------------------
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gba='git branch -a'
alias gpl='git pull'
alias gp='git push'
alias gl='git log --oneline --graph --decorate --all | head -50'
alias gd='git diff'
alias gds='git diff --staged'

# ----------------------------
# Docker aliases
# ----------------------------
alias d='docker'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dlogs='docker logs -f'
alias dexec='docker exec -it'

# ----------------------------
# Java / Gradle / Maven
# ----------------------------
alias gw='./gradlew'
alias gwc='./gradlew clean'
alias gwb='./gradlew build'
alias gwr='./gradlew bootRun'
alias gwt='./gradlew test'

alias mvncf='mvn clean package -DskipTests'
alias mvnct='mvn clean test'
alias mvncl='mvn clean'
alias mvnrt='mvn test'

# ----------------------------
# cat -> bat / batcat (syntax highlighting)
# ----------------------------
if command -v batcat >/dev/null 2>&1; then
  alias cat="batcat --style=plain --paging=never"
elif command -v bat >/dev/null 2>&1; then
  alias cat="bat --style=plain --paging=never"
fi
EOF

echo "==> Writing ~/.nanorc (nano syntax highlighting)..."

cat > "$HOME/.nanorc" <<"EOF"
include "/usr/share/nano/*.nanorc"

set linenumbers
set softwrap
set tabsize 4
set autoindent
EOF

echo
echo "✅ Готово."
echo
echo "1) Щоб активувати конфіг в поточній сесії:"
echo "   source ~/.zshrc"
echo
echo "2) Щоб зробити zsh оболонкою за замовчуванням:"
echo "   chsh -s \"$(command -v zsh)\""
echo "   (потім вийти з SSH та зайти знову)"
echo
