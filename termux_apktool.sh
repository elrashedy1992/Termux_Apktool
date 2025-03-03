#!/bin/bash

LOG_FILE="apktool_installation.log"
AUTHOR="mrnightmare"
YEAR=$(date +"%Y")

print_green() {
    echo -e "\033[1;32m$1\033[0m"
    echo "$(date): $1" >> $LOG_FILE
}

print_red() {
    echo -e "\033[1;31m$1\033[0m"
    echo "$(date): ERROR: $1" >> $LOG_FILE
}

print_yellow() {
    echo -e "\033[1;33m$1\033[0m"
    echo "$(date): WARNING: $1" >> $LOG_FILE
}

print_banner() {
    clear
    echo -e "\033[1;34m"
    echo "######################################################################"
    echo "#              Apktool Installation Script for Termux               #"
    echo "#                                                                    #"
    echo "#             A Powerful Tool by $AUTHOR ($YEAR)                     #"
    echo "#                                                                    #"
    echo "#       This script automates the installation of Apktool on Termux.  #"
    echo "#     Enjoy seamless Apktool building experience without root!       #"
    echo "######################################################################"
    echo -e "\033[0m"
}

check_package() {
    if ! command -v "$1" &>/dev/null; then
        print_red "$1 is not installed. Installing now..."
        pkg install -y "$1" || {
            print_red "Failed to install $1."
            exit 1
        }
    else
        print_yellow "$1 is already installed."
    fi
}

check_free_space() {
    free_space=$(df /data | tail -1 | awk '{print $4}')
    if [ "$free_space" -lt 1048576 ]; then
        print_red "Not enough storage space. Please ensure you have at least 1GB free."
        exit 1
    fi
}

check_gradle_version() {
    gradle_version=$(gradle --version | grep 'Gradle' | awk '{print $2}')
    if [[ "$gradle_version" != "7."* ]]; then
        print_red "The installed Gradle version is incompatible. Please install version 7 or higher."
        exit 1
    fi
}

choose_apktool_version() {
    print_green "Do you want to specify a version of Apktool? (y/n)"
    read -p "Apktool Version: " apktool_choice
    if [ "$apktool_choice" == "y" ]; then
        read -p "Enter the Apktool version you want (e.g., v2.5.0): " apktool_version
        print_green "Switching to the specified version: $apktool_version"
        git checkout "$apktool_version" || {
            print_red "Failed to switch to the specified version. Make sure it's a valid version."
            exit 1
        }
    fi
}

rebuild_apktool() {
    print_green "Rebuilding Apktool using Gradle..."
    ./gradlew clean build shadowJar proguard || {
        print_red "Failed to build Apktool. Check the build errors."
        exit 1
    }
}

print_banner

read -p "Do you want to update the current Apktool installation? (y/n): " update_choice
if [ "$update_choice" == "y" ]; then
    print_green "Updating current packages..."
    pkg update -y && pkg upgrade -y
    print_green "Updating Apktool..."
    rm -rf Apktool
fi

check_free_space

print_green "Checking for necessary tools..."
check_package "gradle"
check_package "root-repo"
check_package "x11-repo"
check_package "openjdk-17"
check_package "wget"
check_package "git"

check_gradle_version

if [ ! -d "Apktool" ]; then
    print_green "Cloning Apktool repository from GitHub..."
    git clone https://github.com/iBotPeaches/Apktool || {
        print_red "Failed to clone Apktool repository."
        exit 1
    }
else
    print_yellow "Apktool repository already exists. Updating it with git pull."
    cd Apktool && git pull || {
        print_red "Failed to update Apktool repository."
        exit 1
    }
fi

cd Apktool

if [ ! -f "./gradlew" ]; then
    print_red "Gradle Wrapper not found! Make sure you are in the correct Apktool directory."
    exit 1
fi

choose_apktool_version

print_green "Building Apktool using Gradle..."
rebuild_apktool

print_green "Setting up Apktool for use..."
echo 'java -jar /data/data/com.termux/files/home/Apktool/brut.apktool/apktool-cli/build/libs/apktool-cli.jar "$@"' > /data/data/com.termux/files/usr/bin/apktool

chmod +x /data/data/com.termux/files/usr/bin/apktool

print_green "Installation successful! You can now use Apktool."
apktool --version

print_green "Installation completed successfully. If you encounter any issues, check the error logs above."
