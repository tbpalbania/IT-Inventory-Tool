# IT Inventory Collection Tool

This repository contains two scripts designed for **Trusted Business Partners** (Tax ID: M41304028K) to easily collect and catalog hardware inventory across both Windows and macOS systems.

When run, the scripts will automatically gather the computer's Make, Model, Serial Number, and OS Version. It will also prompt you for Employee Name, Location details (Godina, Kati, Zyra), and allow you to document connected accessories (Monitors, Printers, Chargers, etc.).

When finished, **all collected data is perfectly formatted as a CSV and copied directly to your clipboard**, ready to be pasted into Excel or Google Sheets.

## How to Run

You do not need to download these files manually. You can run them directly from the web using the terminal commands below.

### Windows (PowerShell)
Open PowerShell and run the following command:
```powershell
iex (irm https://raw.githubusercontent.com/tbpalbania/IT-Inventory-Tool/main/inventory.ps1)
```

### macOS (Terminal)
Open the Terminal app and run the following command:
```bash
curl -sL https://raw.githubusercontent.com/tbpalbania/IT-Inventory-Tool/main/inventory.sh | bash
```

## Features
- **Automatic Scraping:** Collects PC Serial Numbers and OS versions automatically.
- **MacBook Chargers:** Automatically detects and logs connected MacBook chargers.
- **Accessory Linking:** Associates all accessories scanned during a session with the Parent PC's Serial Number so you can easily group Workstations in your spreadsheet.
- **Standardized Categories:** Ensures all data is clean by using a numbered selection menu for accessories.
