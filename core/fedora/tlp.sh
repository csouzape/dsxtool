#!/bin/bash
tlp_install(){
    echo "Installing TLP..."
    sudo dnf install tlp tlp-rdw -y
    sudo dnf remove tuned tuned-ppd -y 
    sudo systemctl enable tlp.service
    sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket
    sudo tlp start
    echo "TLP installed and started successfully."
}
main(){
    tlp_install
}
main


