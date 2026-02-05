def main():
    while True:
        print("\n" + "="*40)
        print("DSXTool - Main Menu")
        print("="*40)
        print("1. Hyprdots")
        print("2. Tlp Config")
        print("3. Bash config")
        print("4. Exit")

        choice = input("Select an option (1-4): ")
        if choice == '1':
            from utils.hyprdots import hyprdots_menu
            hyprdots_menu()
        elif choice == '2':
            from utils.tlp_config import tlp_config_menu
            tlp_config_menu()
        elif choice == '3':
            from utils.bash_config import bash_config_menu
            bash_config_menu()
        elif choice == '4':
            print("Exiting DSXTool. Goodbye!")
            break
        else:
            print("Invalid choice. Please select a valid option.")


    pass
if __name__ == "__main__":
    main()




