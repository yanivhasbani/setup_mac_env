#!/bin/zsh

usage() {
	echo "Usage: ./xcode_switch.sh [options]"
	echo ""
	echo "Options:"
	echo "  --official           Switch to stable Xcode (/Applications/Xcode.app)"
	echo "  --beta               Switch to Xcode Beta (/Applications/Xcode-beta.app)"
	echo "  --path <path>        Switch to a specific Xcode.app path"
	echo "  -h, --help           Show this help message and exit"
	exit 0
}

XCODE_PATH=""

while [[ $# -gt 0 ]]; do
	case $1 in
		--official) XCODE_PATH="/Applications/Xcode.app" ;;
		--beta)     XCODE_PATH="/Applications/Xcode-beta.app" ;;
		--path)
			shift
			XCODE_PATH="$1"
			;;
		-h|--help) usage ;;
		*)
			echo "Unknown option: $1"
			usage
			;;
	esac
	shift
done

if [[ -z "$XCODE_PATH" ]]; then
	echo "Error: no Xcode version specified."
	usage
fi

XCODE_DEVELOPER_DIR="$XCODE_PATH/Contents/Developer"

if [[ ! -d "$XCODE_DEVELOPER_DIR" ]]; then
	echo "Error: Xcode not found at $XCODE_PATH"
	exit 1
fi

sudo xcode-select -s "$XCODE_DEVELOPER_DIR"
echo "Switched active Xcode to $XCODE_PATH"
echo "Active developer directory: $(xcode-select -p)"
