#!/bin/bash
install_gaming_setup(){
    sudo dnf install gnutls lib32-gnutls base-devel gtk3 lib32-gtk3 python-google-auth python-protobuf \
                libpulse lib32-libpulse alsa-lib lib32-alsa-lib alsa-utils alsa-plugins lib32-alsa-plugins \
                giflib lib32-giflib libpng lib32-libpng libldap lib32-libldap openal lib32-openal \
                libxcomposite lib32-libxcomposite libxinerama lib32-libxinerama libgcrypt lib32-libgcrypt \
                libgpg-error lib32-libgpg-error ncurses lib32-ncurses mpg123 lib32-mpg123 \
                libjpeg-turbo lib32-libjpeg-turbo sqlite lib32-sqlite libva lib32-libva \
                gst-plugins-base-libs lib32-gst-plugins-base-libs sdl2 lib32-sdl2 v4l-utils lib32-v4l-utils \
                vulkan-icd-loader lib32-vulkan-icd-loader ocl-icd lib32-ocl-icd opencl-icd-loader lib32-opencl-icd-loader \
                libxslt lib32-libxslt cups samba lib32-mesa vulkan-radeon lib32-vulkan-radeon \
                gamescope mangohud lib32-mangohud gamemode lib32-gamemode
}
main(){
    install_gaming_setup
    echo "Gaming setup installed successfully."
}
main
