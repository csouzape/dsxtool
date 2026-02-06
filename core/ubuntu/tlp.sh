# this is tlp script for ubuntu 
tlp_install(){
    echo "Installing TLP..."
    apt update
    sudo apt remove power-profiles-daemon
    sudo systemctl stop power-profiles-daemon 
    sudo systemctl disable power-profiles-daemon
    apt install tlp tlp-rdw -y
    systemctl enable tlp
    sudo tlp start
    systemctl start tlp
    echo "TLP installed and started successfully."
}
main(){
    tlp_install
}
main


