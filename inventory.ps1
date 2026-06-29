$ErrorActionPreference = 'Stop'
Write-Host "Trusted Business Partners (Tax ID: M41304028K) - IT Inventory Tool" -ForegroundColor Cyan

$EmployeeName = Read-Host "Employee Name / Workstation ID"
$Godina = Read-Host "Godina (Text/number Input)"
$Kati = Read-Host "Kati (Text/number Input)"
$Zyra = Read-Host "Zyra (Text/number Input)"

$csvData = @()

# Get Main PC Info
$os = Get-CimInstance Win32_OperatingSystem
$cs = Get-CimInstance Win32_ComputerSystem
$bios = Get-CimInstance Win32_BIOS
$enclosure = Get-CimInstance Win32_SystemEnclosure

$osVersion = $os.Caption
$make = $cs.Manufacturer
$model = $cs.Model
$serial = $bios.SerialNumber
if (-not $serial) { $serial = "UnknownPC" }

# Determine Category
$chassis = $enclosure.ChassisTypes[0]
$category = "Desktop"
if ($chassis -in @(8,9,10,11,12,14,18,21,31,32)) {
    $category = "Laptop"
}

$csvData += [PSCustomObject]@{
    Make = $make
    Model = $model
    SerialNumber = $serial
    Category = $category
    DeviceType = "Primary"
    ParentPC_Serial = "N/A"
    EmployeeName = $EmployeeName
    Godina = $Godina
    Kati = $Kati
    Zyra = $Zyra
    OSVersion = $osVersion
}

if ($category -eq "Laptop") {
    Write-Host "Laptop detected. Windows does not automatically expose Charger Serials across all brands." -ForegroundColor Yellow
    $addCharger = Read-Host "Do you want to manually document the Charger? (y/n)"
    if ($addCharger -match '^[yY]') {
        $cMake = Read-Host "Charger Make"
        $cModel = Read-Host "Charger Model/Wattage"
        $cSerial = Read-Host "Charger Serial Number"
        
        $csvData += [PSCustomObject]@{
            Make = $cMake
            Model = $cModel
            SerialNumber = $cSerial
            Category = "Charger"
            DeviceType = "Accessory"
            ParentPC_Serial = $serial
            EmployeeName = $EmployeeName
            Godina = $Godina
            Kati = $Kati
            Zyra = $Zyra
            OSVersion = ""
        }
    }
}

# Scan Monitors
Write-Host "Scanning for connected monitors..." -ForegroundColor Yellow
$monitors = Get-CimInstance WmiMonitorID -Namespace root\wmi -ErrorAction SilentlyContinue
foreach ($m in $monitors) {
    $monMake = ""
    if ($m.ManufacturerName) { $monMake = ($m.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join '' }
    $monModel = ""
    if ($m.UserFriendlyName) { $monModel = ($m.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join '' }
    $monSerial = ""
    if ($m.SerialNumberID) { $monSerial = ($m.SerialNumberID | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ }) -join '' }
    
    if (-not $monMake) { $monMake = "Unknown" }
    if (-not $monModel) { $monModel = "Unknown" }
    if (-not $monSerial) { $monSerial = "Unknown" }
    
    $csvData += [PSCustomObject]@{
        Make = $monMake.Trim()
        Model = $monModel.Trim()
        SerialNumber = $monSerial.Trim()
        Category = "Monitor"
        DeviceType = "Accessory"
        ParentPC_Serial = $serial
        EmployeeName = $EmployeeName
        Godina = $Godina
        Kati = $Kati
        Zyra = $Zyra
        OSVersion = ""
    }
}

# Scan Printers
Write-Host "Scanning for connected local printers..." -ForegroundColor Yellow
$printers = Get-CimInstance Win32_Printer -ErrorAction SilentlyContinue | Where-Object { $_.Local -eq $true -and $_.Name -notmatch "PDF|XPS|OneNote|WebEx" }
foreach ($p in $printers) {
    $csvData += [PSCustomObject]@{
        Make = "Unknown"
        Model = $p.Name
        SerialNumber = "Unknown"
        Category = "Printer"
        DeviceType = "Accessory"
        ParentPC_Serial = $serial
        EmployeeName = $EmployeeName
        Godina = $Godina
        Kati = $Kati
        Zyra = $Zyra
        OSVersion = ""
    }
}

# Ask for additional items
while ($true) {
    $add = Read-Host "Add another item (Accessories: Keyboard, mouse, headphones, etc...)? (y/n)"
    if ($add -notmatch '^[yY]') { break }
    
    Write-Host "Select Category:"
    Write-Host "1. Monitor"
    Write-Host "2. Printer"
    Write-Host "3. Keyboard"
    Write-Host "4. Mouse"
    Write-Host "5. Headphones/Headset"
    Write-Host "6. Docking Station"
    Write-Host "7. Charger"
    Write-Host "8. Other"
    
    $catSelection = Read-Host "Enter number (1-8)"
    $cat = "Other"
    switch ($catSelection) {
        "1" { $cat = "Monitor" }
        "2" { $cat = "Printer" }
        "3" { $cat = "Keyboard" }
        "4" { $cat = "Mouse" }
        "5" { $cat = "Headphones/Headset" }
        "6" { $cat = "Docking Station" }
        "7" { $cat = "Charger" }
        "8" { $cat = "Other" }
    }
    
    $mMake = Read-Host "Make"
    $mModel = Read-Host "Model"
    $mSerial = Read-Host "Serial Number"
    
    $csvData += [PSCustomObject]@{
        Make = $mMake
        Model = $mModel
        SerialNumber = $mSerial
        Category = $cat
        DeviceType = "Accessory"
        ParentPC_Serial = $serial
        EmployeeName = $EmployeeName
        Godina = $Godina
        Kati = $Kati
        Zyra = $Zyra
        OSVersion = ""
    }
}

# Copy to clipboard in CSV format
$csvString = $csvData | ConvertTo-Csv -NoTypeInformation | Out-String
Set-Clipboard -Value $csvString
Write-Host "Data copied to clipboard successfully as CSV! You can now paste it." -ForegroundColor Green
