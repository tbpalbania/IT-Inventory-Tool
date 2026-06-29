#!/bin/bash

echo -e "\033[0;36mTrusted Business Partners (Tax ID: M41304028K) - IT Inventory Tool\033[0m"

read -p "Employee Name / Workstation ID: " employee
read -p "Godina (Text/number Input): " godina
read -p "Kati (Text/number Input): " kati
read -p "Zyra (Text/number Input): " zyra

tmpfile=$(mktemp)
echo '"Make","Model","SerialNumber","Category","DeviceType","ParentPC_Serial","EmployeeName","Godina","Kati","Zyra","OSVersion"' > "$tmpfile"

# PC info
make="Apple"
model=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Model Name" | cut -d':' -f2 | xargs)
serial=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Serial Number" | cut -d':' -f2 | xargs)
osVersion="macOS $(sw_vers -productVersion 2>/dev/null)"

if [ -z "$serial" ]; then
    serial="UnknownPC"
fi

category="Desktop"
if [[ "$model" == *"MacBook"* ]]; then
    category="Laptop"
fi

echo "\"$make\",\"$model\",\"$serial\",\"$category\",\"Primary\",\"N/A\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"$osVersion\"" >> "$tmpfile"

# Printers
echo -e "\033[0;33mScanning for connected printers...\033[0m"
printers=$(lpstat -p 2>/dev/null | awk '{print $2}')
for p in $printers; do
    echo "\"Unknown\",\"$p\",\"Unknown\",\"Printer\",\"Accessory\",\"$serial\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"\"" >> "$tmpfile"
done

# Additional items
while true; do
    read -p "Add another item (Monitor, Printer, Accessories)? (y/n) " add
    case $add in
        [Yy]* ) 
            echo "Select Category:"
            echo "1. Monitor"
            echo "2. Printer"
            echo "3. Keyboard"
            echo "4. Mouse"
            echo "5. Headphones/Headset"
            echo "6. Docking Station"
            echo "7. Other"
            read -p "Enter number (1-7): " catSelection
            
            cat="Other"
            case $catSelection in
                1) cat="Monitor";;
                2) cat="Printer";;
                3) cat="Keyboard";;
                4) cat="Mouse";;
                5) cat="Headphones/Headset";;
                6) cat="Docking Station";;
                7) cat="Other";;
            esac
            
            read -p "Make: " dmake
            read -p "Model: " dmodel
            read -p "Serial Number: " dserial
            echo "\"$dmake\",\"$dmodel\",\"$dserial\",\"$cat\",\"Accessory\",\"$serial\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"\"" >> "$tmpfile"
            ;;
        * ) break;;
    esac
done

pbcopy < "$tmpfile"
rm "$tmpfile"

echo -e "\033[0;32mData copied to clipboard successfully as CSV! You can now paste it.\033[0m"
