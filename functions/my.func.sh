find_container_ID() { 
    FILE1=$1 
    FILE2=$2 

    # Check if the input files exist
    if [[ ! -f "$FILE1" ]]; then
        echo "Error: $FILE1 does not exist."
        exit 1
    fi
    if [[ ! -f "$FILE2" ]]; then
        echo "Error: $FILE2 does not exist."
        exit 1
    fi

    # Extract the VMID column from both files and sort them
    awk 'NR>1 {print $1}' "$FILE1" | sort > sorted_file1_vmids.txt
    awk 'NR>1 {print $1}' "$FILE2" | sort > sorted_file2_vmids.txt

    # Use comm to find extra VM IDs in the second file
    current_lxc_id=$(comm -13 sorted_file1_vmids.txt sorted_file2_vmids.txt)
    echo "$current_lxc_id" > difference

    echo "the new container id is: $current_lxc_id"

    # Clean up temporary files
    rm sorted_file1_vmids.txt sorted_file2_vmids.txt
}

extra_admin_account() { 
 extra_admin=$(whiptail --inputbox "Please enter  second admin accountq:" 8 39 --title "Account Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$extra_admin" ]; do
            whiptail --msgbox "Extra account cannot be blank1. Please try again." 8 39 --title "Input Error"
            extra_admin_account
        done
    fi
export $extra_admin

}
extra_admin_password() { 
     extra_password=$(whiptail --inputbox "Please enter  second admin password:" 8 39 --title "password Input" --cancel-button Exit-Script 3>&1 1>&2 2>&3)
        if [ $? -ne 0 ]; then
            echo "Operation cancelled. Exiting..."
            exit 1
        else
            while [ -z "$extra_password" ]; do
            whiptail --msgbox "Extra account cannot be blank1. Please try again." 8 39 --title "Input Error"
            extra_admin_password
        done
    fi
export $extra_password
}