remove_fastfetch(){
    echo "Removing Fastfetch..."
    apt remove fastfetch -y
    echo "Fastfetch removed successfully."
}
remove_config(){
    rm -rf "${HOME}/.config/fastfetch"
    echo "Fastfetch configuration removed successfully."
}

main(){
    remove_fastfetch
    remove_config
}
main