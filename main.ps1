
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    Exit
}

$ScriptBaseDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
$TARGET_NODES = 50
$API_URL = 'https://api.etcnodes.org/peers?all=true'
$AllNodesFile = "reachablenodes.txt"
$FilteredNodesFile = "30303.txt"
$CONFIG_FILE = "config.toml"
$LOG_FILE = "script_log.txt"
$CUSTOM_PORT_FILE = "custom port detected.txt"


$PROVIDED_ENODES = @(
"enode://9606793ccb2daa49e12c7a5e152544928c2ca9d5f610a2f213fbbb45d271fd94d1e18a2ded4bf43b319c1a7751ee9d95a749f04761b165fe53e1c1ed3260f29d@158.220.105.249:30303",
"enode://edcb4922dd61a10d32d4d73e1c8413a0c473154615af48865d2ac0841f82b1ff4b9dee0f6d5ccdd8d037a14ee0c63a178cab215f2f7eb9494faa8260b1cd266d@167.86.77.160:30303",
"enode://18210f25fb151dac37d972027d97b67b70abc8bb4a54e14df2072a7619103a9ed5e62873aa64fd4dfab98242f25eb42b424b44bf6008149520c02dae139f5df3@62.171.169.170:30303",
"enode://7517174774317dd96c6f151d5d2866189b2e604c6d3a66c8f9d92269284fda1bf7ce8e6b078a168227540d4e090c95dbf0810ca26ddf4a957d886ffc48201615@67.188.2.34:30303",
"enode://aba4fc3d856f3850f99ec9db7e45af43acad03c925c4c44e334fae14e32249c58cfc705cc54796d88bae5c9a99c7184768d518b2496cb105871bc74c12ecc9c8@217.122.83.122:30303",
"enode://9519990a042006719739daad199c4a363dc30a22d632ff3085a70a2ec7041ae78a4c0ba5851fe3b487d4e461c65e83c33c39d0c64a691b1e87cbaf07de64ad8d@217.122.83.122:30330",
"enode://792c4a3864fdd475de982f021ea24a145162474695c9f4d37c42f1eb22a715d72842bceed7fb238cfd8c9c9ff05d17b21eb497637a0921440f2369ebdb3973d9@217.122.83.122:30340",
"enode://10fb601da4043ff8cf6831c3ce3abf747a6cb8fb96bd4e07b1d2e0740a18ed205cb495aed4b536488c49891ddb581d5aaf5f9fbdd7abf1b4b0c980c819d1a80e@217.122.83.122:30350",
"enode://2c5cb2e331f56256696996a465709f2cae9fe0ca7358cf1a820ab61bcf233e7458b73d0e414e60bb2a0bf7d7ad1887c62ee5c333212cc64509b80b214274f079@197.234.147.16:30303",
"enode://d3a09543e3991a0bc2bf447017f719c56651905a434f6a95ca7219ea945f1493eb3ae4e8d3605ff82dd86d1e231111ff204201774b7ee78fe38394fe5f36cb06@185.157.26.107:30303",
"enode://5dbc6cfe4a31ac2d79e2052ede6194fd849af2adfe9f8f3d2eefa375bd7676dee717009db1caeedb21f2256f5bae69753a33b6c9b47107caf785899aaa4da5cd@72.75.209.137:30303",
"enode://4d30be4952784686e0deb7743cbaecf560eb050ef77a7bd6cbeddd248b091c65eff6fd84162a2f465a7b5af283923cea7428cd2da2ad658163ed647d7739dc0f@207.180.217.136:30303",
"enode://df3b5fb7210c9d4c595bf3d859f0efcb0533eb5509730c97449113b2cd7f88cb47b1aec62f66e2f1ecf95f7a0d1cf2f661cfae6ca760d41a9b0e070d7e6a76a1@115.85.88.10:30303",
"enode://6bf6b5878193cb39ca8cb0beecbf2b3ef43c7aec2c9cce39c3a08f7ef6f05fbd4387d492bb913d0916a2a6afd14b12068739ece614864942691fa5befd4914f7@80.112.90.238:30303",
"enode://17a7c2c816f9086e9ec41a83dd714ac3f2746cc5dd8d0503e340e6c0e5a7f88598f1910390bfbe667b95383620786b7d4159517a82d4a05b6f16a7d09d02446c@94.132.52.132:30303",
"enode://c4d324003be91205b3d07de36a52abf033078e23ac231571eb99a08d7ceb9c8136316dd7d0a7de80c2c2e27f3544e50c994d950ef7a0e24cff06afa40cd2e6eb@77.247.90.134:30303",
"enode://b170973d769385e9a005b13374ff94c18cc9bb8c4605dbffb69f9317f0dcb1026152bf3b5b7d4ea6e19d5858cf8bf0c6caa4d16c88aa94970b40a8565b56831f@208.69.189.17:30303",
"enode://66dcb7b903255a117e614fe60b430c8131eb89f325f3ed7b7a313fe19bf2890195b29e9ca000bfad40a6f15a322c96b64ba1248a2d00f1d2a8e70aae944e947d@173.24.58.9:30303"
)


function Log-Message {
    param (
        [string]$message,
        [string]$level = "INFO"
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $styledMessage = "[ $($timestamp) ] [ $($level.ToUpper()) ] $message"

    $separatorLength = $styledMessage.Length
    $separator = "-" * $separatorLength
    $formattedMessage = @"
$separator
$styledMessage
$separator
"@

    $formattedMessage | Out-File -Append -FilePath $LOG_FILE
    Write-Host $formattedMessage -ForegroundColor Green
}



function Read-CurrentPort {
    $defaultPort = 30303
    $jsonFileName = "geth_port.json"
    $folderPaths = @(
        "\Users\Public\Desktop\ETCMC\ETCMC Client",
        "\Program Files (x86)\ETCMC\ETCMC Client",
        "\Program Files (x86)\ETCMC ETC NODE LAUNCHER 1920x1080\ETCMC_GUI\ETCMC_GETH",
        "\Program Files (x86)\ETCMC ETC NODE LAUNCHER 1024x600\ETCMC_GUI\ETCMC_GETH",
        "\ETCMC ETC NODE LAUNCHER 1920x1080\ETCMC_GUI\ETCMC_GETH",
        "\ETCMC ETC NODE LAUNCHER 1024x600\ETCMC_GUI\ETCMC_GETH"
    )

    $drives = [System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq "Fixed" }
    foreach ($drive in $drives) {
        foreach ($folderPath in $folderPaths) {
            $fullPath = Join-Path $drive.Name $folderPath
            $jsonFilePath = Join-Path $fullPath $jsonFileName
            Log-Message "Checking for JSON file at: $jsonFilePath"
            if (Test-Path $jsonFilePath) {
                Log-Message "Found JSON file at: $jsonFilePath"
                try {
                    $jsonContent = Get-Content $jsonFilePath | ConvertFrom-Json
                    if ($jsonContent -and $jsonContent.port) {
                        $currentPort = $jsonContent.port -replace '[^0-9]'
                        $customPortFilePath = Join-Path $ScriptBaseDirectory $CUSTOM_PORT_FILE
                        Set-Content -Path $customPortFilePath -Value $currentPort
                        Log-Message "Current port ($currentPort) detected and saved to $customPortFilePath"
                        return $currentPort, $fullPath
                    } else {
                        Log-Message "No port information found in JSON file at: $jsonFilePath. Defaulting to port $defaultPort."
                        return $defaultPort, $fullPath
                    }
                } catch {
                    Log-Message "Error reading JSON file at: $jsonFilePath. Defaulting to port $defaultPort."
                    return $defaultPort, $fullPath
                }
            } else {
                Log-Message "JSON file not found at: $jsonFilePath"
            }
        }
    }
    Log-Message "No geth_port.json file found in the specified locations. Defaulting to port $defaultPort."
    return $defaultPort, $null
}

function Fetch-And-Process-Nodes {
    $asciiArt = @"

  _____ _____ ____ __  __  ____ 
 | ____|_   _/ ___|  \/  |/ ___|
 |  _|   | || |   | |\/| | |    
 | |___  | || |___| |  | | |___ 
 |_____| |_| \____|_|  |_|\____|
                                
                              
"@

    Write-Host $asciiArt -ForegroundColor Cyan

    try {
        $response = Invoke-WebRequest -Uri $API_URL -UseBasicParsing
        $nodes = $response.Content | ConvertFrom-Json
        if ($nodes -and $nodes.Count -gt 0) {
            $enodes = $nodes | ForEach-Object { $_.enode }
            Write-Host "Fetched $($enodes.Count) nodes." -ForegroundColor Yellow
            $enodes | Out-File -FilePath $AllNodesFile
            Write-Host "Written all enodes to $AllNodesFile." -ForegroundColor Yellow
            $filteredEnodes = $enodes | Where-Object { $_ -match ":30303" }
            Write-Host "Filtered enodes for port 30303: $($filteredEnodes.Count)" -ForegroundColor Cyan
            $filteredEnodes | Out-File -FilePath $FilteredNodesFile
            Write-Host "Written $($filteredEnodes.Count) filtered enodes to $FilteredNodesFile." -ForegroundColor Yellow
            return $filteredEnodes
        } else {
            Write-Host "No nodes were found in the API response." -ForegroundColor Red
            return @()
        }
    } catch {
        Write-Host "An error occurred: $_" -ForegroundColor Red
        return @()
    }
}




function Write-Files {
    param (
        [string]$customPort,
        [string]$destinationDir
    )
    $staticNodesFilePath = "30303.txt"
    $staticNodes = Get-Content $staticNodesFilePath
    $staticNodesFormatted = '"' + ($staticNodes -join '",' + "`n" + '"') + '"'
    $bootstrapNodesFormatted = '"' + ($PROVIDED_ENODES -join '",' + "`n" + '"') + '"'

    $configContent = "# Ethereum Classic Node Configuration`n`n" +
    "[Eth]`n" +
    "# Network ID for Ethereum Classic`n" +
    "NetworkId = 61`n" +
    "# Sync mode (snap is faster for initial sync)`n" +
    'SyncMode = "snap"' + "`n" +
    "# Other optimization parameters`n" +
    "NoPruning = false`n" +
    "NoPrefetch = false`n" +
    "LightPeers = 100`n" +
    "UltraLightFraction = 75`n" +
    "# Cache size for database in MB`n" +
    "DatabaseCache = 1024`n`n" +
    "[Node]`n" +
    "# Data directory for the Ethereum node data`n" +
    'DataDir = ".\\gethDataDirFastNode"' + "`n" +
    "# Path to IPC file for inter-process communication`n" +
    'IPCPath = "geth.ipc"' + "`n" +
    "# HTTP configurations for the node`n" +
    'HTTPHost = "localhost"' + "`n" +
    'HTTPPort = 8544' + "`n" +
    'HTTPCors = ["*"]' + "`n" +
    'HTTPVirtualHosts = ["localhost"]' + "`n" +
    "# Websocket configurations`n" +
    'WSHost = "localhost"' + "`n" +
    'WSPort = 8546' + "`n`n" +
    "[Node.P2P]`n" +
    "# Peer-to-peer configurations`n" +
    "MaxPeers = 50`n" +
    "NoDiscovery = false`n" + "`n" +
    "# Add your bootstrap nodes here`n" +
    "BootstrapNodes = [" + "`n" +
    $bootstrapNodesFormatted + "`n]" + "`n`n" +
    "# Add your static nodes here`n" +
    "# Static nodes configuration (from 30303.txt)`n" +
    "StaticNodes = [" + "`n" +
    $staticNodesFormatted + "`n]" + "`n"

    $configFilePath = Join-Path $destinationDir $CONFIG_FILE
    Set-Content -Path $configFilePath -Value $configContent
    Log-Message "Configuration file created at $configFilePath"
}
function Open-FirewallPorts {
    Log-Message "Checking and opening firewall ports if needed..."
    $ports = @(30303, 8545, 8546)

    # Read the current port
    $customPort, $folderPath = Read-CurrentPort

    # Add the custom port to the list of ports to be opened
    if ($customPort -ne 30303) {
        $ports += [int]$customPort
    }

    foreach ($port in $ports) {
        $tcpRuleName = "Open TCP Port $port"
        $udpRuleName = "Open UDP Port $port"
        $existingTCPRule = Get-NetFirewallRule -DisplayName $tcpRuleName -ErrorAction SilentlyContinue
        if (-not $existingTCPRule) {
            netsh advfirewall firewall add rule name="$tcpRuleName" dir=in action=allow protocol=TCP localport=$port | Out-Null
            Log-Message "TCP Port $port rule added"
        } else {
            Log-Message "TCP Port $port rule already exists"
        }
        $existingUDPRule = Get-NetFirewallRule -DisplayName $udpRuleName -ErrorAction SilentlyContinue
        if (-not $existingUDPRule) {
            netsh advfirewall firewall add rule name="$udpRuleName" dir=in action=allow protocol=UDP localport=$port | Out-Null
            Log-Message "UDP Port $port rule added"
        } else {
            Log-Message "UDP Port $port rule already exists"
        }
    }

    # Add the folder to exclusion from Windows Defender
    $currentPort, $folderPath = Read-CurrentPort
    if ($folderPath -ne $null) {
        Add-MpPreference -ExclusionPath $folderPath
        Log-Message "Added folder $folderPath to Windows Defender exclusion list."
    } else {
        Log-Message "Folder path not found. Cannot add to Windows Defender exclusion list."
    }
}
Log-Message "Script started."
$customPort, $destinationDir = Read-CurrentPort
if ($destinationDir -eq $null) {
    $destinationDir = "C:\Program Files (x86)\ETCMC\ETCMC Client"
    Log-Message "Using default destination directory: $destinationDir"
}

if (-not (Test-Path $destinationDir)) {
    New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
    Log-Message "Created destination directory: $destinationDir"
}

$filteredEnodes = Fetch-And-Process-Nodes
if ($filteredEnodes.Count -gt 0) {
    Write-Files -customPort $customPort -destinationDir $destinationDir
    Open-FirewallPorts
    Log-Message "Script completed successfully."
} else {
    Log-Message "No valid nodes found. Script terminated."
}

# Thank you message
Write-Host "Thank you for using this tool! If you need more help, visit our Discord: https://discord.gg/etcmc" -ForegroundColor Yellow
Read-Host "Press Enter to exit..."