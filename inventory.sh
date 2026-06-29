#!/bin/bash

echo -e "\033[0;36mTrusted Business Partners (Tax ID: M41304028K) - IT Inventory Tool\033[0m"

# When a script is run via `curl | bash`, standard input is taken by the pipe.
# We must explicitly read from /dev/tty to capture keyboard input from the user.
read -p "Employee Name / Workstation ID: " employee < /dev/tty
read -p "Godina (Text/number Input): " godina < /dev/tty
read -p "Kati (Text/number Input): " kati < /dev/tty
read -p "Zyra (Text/number Input): " zyra < /dev/tty

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

# If laptop, try to scrape charger data automatically
if [ "$category" == "Laptop" ]; then
    chargerInfo=$(system_profiler SPPowerDataType 2>/dev/null | grep -A 10 "AC Charger Information")
    if [[ "$chargerInfo" == *"Connected: Yes"* || "$chargerInfo" == *"Manufacturer"* ]]; then
        cMake=$(echo "$chargerInfo" | grep "Manufacturer:" | cut -d':' -f2 | xargs)
        cModel=$(echo "$chargerInfo" | grep "Name:" | cut -d':' -f2 | xargs)
        cSerial=$(echo "$chargerInfo" | grep "Serial Number:" | cut -d':' -f2 | xargs)
        
        if [ -z "$cMake" ]; then cMake="Unknown"; fi
        if [ -z "$cModel" ]; then cModel="Unknown Charger"; fi
        if [ -z "$cSerial" ]; then cSerial="Unknown"; fi
        
        echo "\"$cMake\",\"$cModel\",\"$cSerial\",\"Charger\",\"Accessory\",\"$serial\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"\"" >> "$tmpfile"
        echo -e "\033[0;32mAutomatically detected and linked MacBook Charger: $cModel ($cSerial)\033[0m"
    else
        read -p "Charger not connected. Do you want to add the Charger manually? (y/n) " addCharger < /dev/tty
        case $addCharger in
            [Yy]* )
                read -p "Charger Make: " cMake < /dev/tty
                read -p "Charger Model (e.g. 65W): " cModel < /dev/tty
                read -p "Charger Serial Number: " cSerial < /dev/tty
                echo "\"$cMake\",\"$cModel\",\"$cSerial\",\"Charger\",\"Accessory\",\"$serial\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"\"" >> "$tmpfile"
                ;;
        esac
    fi
fi

# Printers
echo -e "\033[0;33mScanning for connected printers...\033[0m"
printers=$(lpstat -p 2>/dev/null | awk '{print $2}')
for p in $printers; do
    echo "\"Unknown\",\"$p\",\"Unknown\",\"Printer\",\"Accessory\",\"$serial\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"\"" >> "$tmpfile"
done

# Additional items
while true; do
    read -p "Add another item (Monitor, Printer, Accessories)? (y/n) " add < /dev/tty
    case $add in
        [Yy]* ) 
            echo "Select Category:"
            echo "1. Monitor"
            echo "2. Printer"
            echo "3. Keyboard"
            echo "4. Mouse"
            echo "5. Headphones/Headset"
            echo "6. Docking Station"
            echo "7. Charger"
            echo "8. Other"
            read -p "Enter number (1-8): " catSelection < /dev/tty
            
            cat="Other"
            case $catSelection in
                1) cat="Monitor";;
                2) cat="Printer";;
                3) cat="Keyboard";;
                4) cat="Mouse";;
                5) cat="Headphones/Headset";;
                6) cat="Docking Station";;
                7) cat="Charger";;
                8) cat="Other";;
            esac
            
            read -p "Make: " dmake < /dev/tty
            read -p "Model: " dmodel < /dev/tty
            read -p "Serial Number: " dserial < /dev/tty
            echo "\"$dmake\",\"$dmodel\",\"$dserial\",\"$cat\",\"Accessory\",\"$serial\",\"$employee\",\"$godina\",\"$kati\",\"$zyra\",\"\"" >> "$tmpfile"
            ;;
        * ) break;;
    esac
done

echo -e "\033[0;33mSending data to Central Database...\033[0m"
python3 -c '
import csv
import json
import urllib.request
import sys

csv_file = sys.argv[1]
url = sys.argv[2]

data = []
with open(csv_file, "r") as f:
    reader = csv.DictReader(f)
    for row in reader:
        data.append(row)

req = urllib.request.Request(url, data=json.dumps(data).encode("utf-8"), headers={"Content-Type": "application/json"})
try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode())
        if result.get("status") == "success":
            print("\033[0;32mData successfully saved to Central Database!\033[0m")
        else:
            print("\033[0;31mServer reported an issue: " + result.get("message", "Unknown error") + "\033[0m")
except Exception as e:
    print("\033[0;31mFailed to send data: " + str(e) + "\033[0m")
' "$tmpfile" "https://script.google.com/macros/s/AKfycbyCJjgFceSqKS283KUtXYrL4X_g3woAlpya53sZPTFe9IQ8suZ9ZPVerBV-K25b698w/exec"

rm "$tmpfile"
