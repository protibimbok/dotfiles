curl https://cursor.com/install -fsS | bash
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
yay -S cursor-bin
sudo pacman -S --needed base-devel git
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -rf yay
yay -Yc
yay -S google-chrome
sudo pacman -S hyprland kitty
yay -S dolphin
sudo pacman -S neovim
git config --global init.defaultBranch mastersudo pacman -S power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon.service
sudo pacman -S gnome-keyring
gnome-keyring-daemon --start --components=secrets
yay -S quickshell
sudo pacman -S ttf-firacode-nerd
gsettings set org.gnome.desktop.interface monospace-font-name 'FiraCode Nerd Font 11'
sudo pacman -S ttf-liberation
sudo pacman -S noto-fonts noto-fonts-extra noto-fonts-cjk noto-fonts-emoji
sudo pacman -S ttf-ubuntu-font-family
sudo pacman -S ttf-jetbrains-mono-nerd
fc-cache -fv
sudo pacman -S grim slurp wl-clipboard
sudo pacman -S pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse pipewire-jack
sudo pacman -S pavucontrol
sudo pacman -S sof-firmware alsa-firmware alsa-ucm-conf
systemctl --user enable --now pipewire.service wireplumber.service pipewire-pulse.service
sudo pacman -S alsa-utils
yay -S qimgv-git
sudo pacman -S awww
sudo pacman -S python-pywal
mkdir ~/.cache/awww
sudo pacman -S brightnessctl
sudo pacman -S intel-media-driver
yay -S qt6-svg qt6-imageformats

sudo pacman -S bluez bluez-utils
sudo pacman -S xdg-desktop-portal xdg-desktop-portal-hyprland

sudo pacman -S power-profiles-daemon
sudo systemctl enable --now power-profiles-daemon.service
sudo pacman -S ttf-material-symbols-variable
sudo pacman -S fcitx5-im fcitx5-configtool
yay -S fcitx5-openbangla-git

sudo pacman -S ly
sudo systemctl enable ly@tty2.service
sudo systemctl disable getty@tty2.service
