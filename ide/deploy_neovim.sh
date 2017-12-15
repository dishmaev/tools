#!/bin/sh

###header
. $(dirname "$0")/../common/define.sh #include common defines, like $COMMON_...
targetDescription 'Deploy Neovim with Go plugin on the local OS'

##private consts
readonly CONST_FILE_LINUX_URL='https://github.com/neovim/neovim/releases/download/v@PRM_VERSION@/nvim.appimage' #Linux url for download
readonly CONST_FILE_MACOS_URL='https://github.com/neovim/neovim/releases/download/v@PRM_VERSION@/nvim-macos.tar.gz' #MacOS url for download
readonly CONST_VIM_PLUG_URL='https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
readonly CONST_FILE_VERSION='0.2.2'
readonly CONST_NVIM_NAME='nvim'
readonly CONST_NVIM_PATH="$HOME/$CONST_NVIM_NAME"

##private vars
PRM_VERSION='' #IDE version
VAR_LINUX_BASED='' #for checking supported OS
VAR_ORIG_FILE_NAME='' #original file name
VAR_ORIG_FILE_PATH='' #original file name with local path
VAR_FILE_URL='' #url specific version for download
VAR_TMP_DIR_PATH='' #temporary directory name

###check autoyes

checkAutoYes "$1" || shift

###help

echoHelp $# 1 '[version=$CONST_FILE_VERSION]' \
"$CONST_FILE_VERSION" "Version format 'X.X.X'. Neovim editor url https://github.com/neovim/neovim. Go development plugin for Vim url https://github.com/fatih/vim-go"

###check commands

PRM_VERSION=${1:-$CONST_FILE_VERSION}

checkCommandExist 'version' "$PRM_VERSION" ''

###check body dependencies

#checkDependencies 'dep1 dep2 dep3'

###check required files

#checkRequiredFiles "file1 file2 file3"

###start prompt

startPrompt

###body

#test!
rm -fR "${CONST_NVIM_PATH}-$PRM_VERSION"
rm -fR ~/.vim/
rm -fR ~/.config/nvim/
#test!

if ! isCommandExist 'go' || ! isCommandExist 'gocode'; then
  exitError "missing command vboxmanage. Try to exec $ENV_ROOT_DIR/framework/deploy_golang.sh"
fi

if isCommandExist "$CONST_NVIM_NAME"; then
  echoInfo "already deployed"
  $CONST_NVIM_NAME --version
  checkRetValOK

  doneFinalStage
  exitOK
fi
#check supported OS
if isLinuxOS; then
  checkDependencies 'wget'
  VAR_LINUX_BASED=$(checkLinuxAptOrRpm) || exitChildError "$VAR_LINUX_BASED"
  if isAPTLinux "$VAR_LINUX_BASED" || isRPMLinux "$VAR_LINUX_BASED"; then
    VAR_FILE_URL="$CONST_FILE_LINUX_URL"
  else
    exitError "unknown Linux based package system"
  fi
elif isMacOS; then
  checkDependencies 'unzip'
  VAR_FILE_URL="$CONST_FILE_MACOS_URL"
else
  exitError 'not supported OS'
fi

VAR_FILE_URL=$(echo "$VAR_FILE_URL" | $SED -e "s#@PRM_VERSION@#$PRM_VERSION#") || exitChildError "$VAR_FILE_URL"
VAR_ORIG_FILE_NAME=$(getFileNameFromUrlString "$VAR_FILE_URL") || exitChildError "$VAR_ORIG_FILE_NAME"
VAR_ORIG_FILE_PATH=$ENV_DOWNLOAD_PATH/$VAR_ORIG_FILE_NAME
if ! isFileExistAndRead "$VAR_ORIG_FILE_PATH"; then
  if isLinuxOS; then
    wget -O $VAR_ORIG_FILE_PATH $VAR_FILE_URL
    checkRetValOK
  elif isMacOS; then
    curl -L -o $VAR_ORIG_FILE_PATH $VAR_FILE_URL
    checkRetValOK
  fi
fi

mkdir -p "${CONST_NVIM_PATH}-$PRM_VERSION"
checkRetValOK

if isLinuxOS; then
  if isAPTLinux "$VAR_LINUX_BASED"; then
    sudo apt -y install vim
    checkRetValOK
    sudo apt -y install vim-python-jedi
    checkRetValOK
#    sudo apt -y install python-pip
#    checkRetValOK
    sudo apt -y install python3-pip
    checkRetValOK
#    pip2 install --upgrade neovim
#    checkRetValOK
    pip3 install --upgrade neovim
    checkRetValOK
#    sudo apt -y install ruby-neovim
#    checkRetValOK
  elif isRPMLinux "$VAR_LINUX_BASED"; then
    :
  fi
  cp "$VAR_ORIG_FILE_PATH" "${CONST_NVIM_PATH}-$PRM_VERSION/$CONST_NVIM_NAME"
  checkRetValOK
  chmod u+x "${CONST_NVIM_PATH}-$PRM_VERSION/$CONST_NVIM_NAME"
  checkRetValOK
  echo "export PATH=$PATH:${CONST_NVIM_PATH}-$PRM_VERSION" | tee -a "$HOME/.bashrc"
  checkRetValOK
  export PATH=$PATH:${CONST_NVIM_PATH}-$PRM_VERSION
  checkRetValOK
  if isCommandExist "source"; then
    source "$HOME/.bashrc"
    checkRetValOK
  fi
elif isMacOS; then
  tar --strip-component=1 -C "${CONST_NVIM_PATH}-$PRM_VERSION" -xvf "$VAR_ORIG_FILE_PATH"
  checkRetValOK
  echo "export PATH=$PATH:${CONST_NVIM_PATH}-$PRM_VERSION/bin" | tee -a "$HOME/.bash_profile"
  checkRetValOK
  PATH=$PATH:${CONST_NVIM_PATH}-$PRM_VERSION/bin
  checkRetValOK
  if isCommandExist "source"; then
    source "$HOME/.bash_profile"
    checkRetValOK
  fi
fi

mkdir -p $HOME/.config/nvim/autoload
mkdir -p $HOME/.vim/autoload
wget -O $HOME/.vim/autoload/plug.vim $CONST_VIM_PLUG_URL
ln -s $HOME/.vim/autoload/plug.vim $HOME/.config/nvim/autoload/plug.vim
cp "$ENV_SCRIPT_DIR_NAME/init.vim" $HOME/.vimrc
ln -s $HOME/.vimrc $HOME/.config/nvim/init.vim

$CONST_NVIM_NAME --version
checkRetValOK

doneFinalStage

echo ''
echo "Now start $CONST_NVIM_NAME and make some final things:"
echo ':PlugInstall'
echo ':GoInstallBinaries'

exitOK
