#!/bin/zsh

DEVELOPER_FOLDER=~/Developer
TEMP_DOWNLOAD_SETUP_FOLDER=~/Developer/setup_downloads
USER_PASSWORD='!Q2w3e4r'

 typeset -A APP_NAME_TO_CASK_MAP
APP_NAME_TO_CASK_MAP=(
	[sublime-text]="Sublime Text"
	[pycharm-ce]="PyCharm CE"
	[iterm2]="iTerm"
	[beyond-compare]="Beyond Compare"
)


# App paths
SUBL_PATH=$TEMP_DOWNLOAD_SETUP_FOLDER/SublimeText.dmg


_brew_install_app_and_keep_to_dock() {
	CASK_NAME=$1
	APP_NAME=${APP_NAME_TO_CASK_MAP[$CASK_NAME]}

	if [[ -d "/Applications/$APP_NAME.app" ]]; then
		echo "$APP_NAME is already installed (found in /Applications). Skipping."
	elif brew list --cask "$CASK_NAME" &>/dev/null 2>&1; then
		echo "$APP_NAME is already installed (registered with brew). Skipping."
	else
		brew install --cask $CASK_NAME
	fi

	if defaults read com.apple.dock persistent-apps 2>/dev/null | grep -q "$APP_NAME"; then
		echo "$APP_NAME is already in the Dock. Skipping."
	else
		defaults write com.apple.dock persistent-apps -array-add "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>/Applications/$APP_NAME.app</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
	fi
}

_setup_ssh_keys() {
	KEY_PATH=~/.ssh/id_rsa

	if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
		echo "GitHub SSH connection already verified. Skipping."
		return
	fi

	if [[ -f "$KEY_PATH" ]]; then
		echo "SSH key already exists at $KEY_PATH. Skipping generation."
	else
		ssh-keygen -t rsa -b 4096 -C "yanivhasbanidev@gmail.com" -f "$KEY_PATH" -N ""
		echo "SSH key generated."
	fi

	eval "$(ssh-agent -s)"
	ssh-add "$KEY_PATH"

	echo "\nAdd the following public key to GitHub (https://github.com/settings/ssh/new):"
	echo "----------------------------------------------------------------------"
	cat "${KEY_PATH}.pub"
	echo "----------------------------------------------------------------------"
	read -r "?Press Enter once you have added the key to GitHub..."

	ssh -T git@github.com 2>&1 | grep -q "successfully authenticated" \
		&& echo "GitHub SSH connection verified." \
		|| echo "Warning: could not verify GitHub SSH connection. Check that the key was added correctly."
}

_setup_homebrew() {
	if command -v brew &> /dev/null; then
	    echo "Homebrew is installed."
	    return
	fi

	NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" < /dev/null
	echo >> /Users/office.yh.mac/.zprofile
    echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> /Users/office.yh.mac/.zprofile
	eval "$(/opt/homebrew/bin/brew shellenv zsh)"
}

_install_xcode() {
	if xcode-select -p &>/dev/null; then
		echo "Xcode Command Line Tools are already installed. Skipping."
	else
		xcode-select --install
		read -r "continue?Please finish xcode-select installation UI then continue..."

		if xcode-select -p &>/dev/null; then
			echo "Xcode Command Line Tools are verified and installed."
		else
			echo "Xcode Command Line Tools are missing."
			exit
		fi
	fi

	brew install mas

	if [[ -d "/Applications/Xcode.app" ]]; then
		echo "Xcode IDE is already installed. Skipping."
	else
		echo "Installing Xcode IDE from App Store (this may take a while)..."
		mas install 497799835
	fi

	"$SCRIPT_DIR/xcode_switch.sh" --official
}

_setup_terminal_install_zsh_functionality() {
	brew install $1
	local share_dir="$(brew --prefix)/share/$1"
	local source_line
	if [[ -f "$share_dir/$1.plugin.zsh" ]]; then
		source_line="source $share_dir/$1.plugin.zsh"
	else
		source_line="source $share_dir/$1.zsh"
	fi
	local zshrc="${HOME}/.zshrc"
	local zshrc_real="${zshrc:A}"

	if grep -qF "$source_line" "$zshrc_real" 2>/dev/null; then
		echo "$1 source line already in ~/.zshrc. Skipping."
		return
	fi

	# Insert after the first blank line (after top-of-file declarations)
	awk -v line="$source_line" '
	!inserted && /^[[:space:]]*$/ { print; print line; inserted=1; next }
	{ print }
	END { if (!inserted) print line }
	' "$zshrc_real" > "${zshrc_real}.tmp" && mv "${zshrc_real}.tmp" "$zshrc_real"

	echo "Added $1 source line to ~/.zshrc."
}

_setup_terminal() {
	_setup_terminal_install_zsh_functionality zsh-autocomplete
	_setup_terminal_install_zsh_functionality zsh-autosuggestions
}

_setup_beyond_compare() {
	_brew_install_app_and_keep_to_dock beyond-compare

	local bc_cli="/Applications/Beyond Compare.app/Contents/MacOS/bcomp"
	local bc_link="$(brew --prefix)/bin/bcomp"

	if [[ ! -f "$bc_link" ]]; then
		ln -s "$bc_cli" "$bc_link"
		echo "Beyond Compare CLI tools installed."
	else
		echo "Beyond Compare CLI tools already installed. Skipping."
	fi

	git config --global diff.tool bc
	git config --global difftool.bc.path "$bc_cli"
	git config --global difftool.prompt false
	git config --global merge.tool bc
	git config --global mergetool.bc.path "$bc_cli"
	git config --global mergetool.prompt false
	echo "Beyond Compare set as default git difftool and mergetool."
}

_install_apps() {
	_brew_install_app_and_keep_to_dock sublime-text
	_brew_install_app_and_keep_to_dock pycharm-ce
	_brew_install_app_and_keep_to_dock iterm2
	_setup_beyond_compare
	brew install --cask claude-code
	killall Dock
}

mac_env_setup() {
	_setup_homebrew
	_install_xcode
	_setup_ssh_keys

	mkdir -p $DEVELOPER_FOLDER

	local dotfiles_dir="${0:A:h}"
	if [[ ! -L "$HOME/.zshrc" ]]; then
		ln -s "$dotfiles_dir/.zshrc" ~/.zshrc
	else
		echo "zshrc symlink already exists"
	fi

	_setup_terminal
	_install_apps
}

mac_env_setup
