# DCS World Startup Script
# Starts DCS with additional programs and kills them when DCS is closed

#################
# CONFIGURATION #
#################

# Boolean flags
[bool]$voiceattack_enabled = 1
[bool]$trackir_enabled = 1
[bool]$simshaker_enabled = 0
[bool]$pitool_enabled = 0
[bool]$steamvr_enabled = 1
[bool]$lhb_control_enabled = 1
[bool]$controller_check_enabled = 1
[bool]$mfds_enabled = 0
[bool]$kill_bloatware = 0
[bool]$cleanup_tracks = 0
[bool]$cleanup_kneeboard = 0

# Path variables
$dcs_directory = "D:\Program Files\Eagle Dynamics\DCS World"
$dcs_exe = ($dcs_directory) +"\bin\DCS.exe"
$dcs_updater_exe = ($dcs_directory) +"\bin\DCS_updater.exe"
$trackir_exe = "C:\Program Files (x86)\NaturalPoint\TrackIR5\TrackIR5.exe"
$displaychanger_exe = "D:\Program Files\Display Changer\dc64cmd.exe"
$voiceattack_exe = "C:\Program Files\VoiceAttack\VoiceAttack.exe"
$simshaker_appref = "C:\Users\geekpilot\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\SimShaker for Aviators\SimShaker for Aviators.lnk"
$nircmd_exe = "D:\Program Files\nircmd\nircmd.exe"
$cmdow_exe = "D:\Program Files\cmdow\cmdow.exe"
$powercfg_exe = "$env:windir\System32\powercfg.exe"
$nvidiainspector_exe = "D:\Program Files\Nvidia Inspector\nvidiaInspector.exe"
$refreshtray_exe = "D:\Program Files\RefreshNotificationArea\RefreshNotificationArea.exe"
$steamvr_settings = "C:\Program Files (x86)\Steam\config\steamvr.vrsettings"
$pitool_exe = "C:\Program Files\Pimax\Runtime\PiTool.exe"
$steamvr_server_exe = "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrserver.exe"
$steamvr_monitor_exe = "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrmonitor.exe"
$steamvr_startup_exe = "C:\Program Files (x86)\Steam\steamapps\common\SteamVR\bin\win64\vrstartup.exe"
$lighthouse_manager_exe = "D:\Program Files\Lighthouse V2 Manager\lighthouse-v2-manager.exe"
$icue_exe = "C:\Program Files\Corsair\CORSAIR iCUE 4 Software\iCUE Launcher.exe"

# Process variables
$voiceattack_proc = Get-Process "VoiceAttack" -ErrorAction SilentlyContinue
$simshaker_proc = Get-Process "SimShaker for Aviators" -ErrorAction SilentlyContinue
$iba_proc = Get-Process "ibaJetseatHandler" -ErrorAction SilentlyContinue
$srs_proc = Get-Process "SR-ClientRadio" -ErrorAction SilentlyContinue
$trackir_proc = Get-Process "TrackIR5" -ErrorAction SilentlyContinue
$dcs_proc = Get-Process "DCS" -ErrorAction SilentlyContinue
$nvidiainspector_proc = Get-Process "nvidiaInspector" -ErrorAction SilentlyContinue
$pitool_proc = Get-Process "PiTool" -ErrorAction SilentlyContinue
$vrmonitor_proc = Get-Process "vrmonitor" -ErrorAction SilentlyContinue

# Performance profile variables (Get GUIDs with powercfg /list in cmd)
$dcs_profile_desc = "High performance"
$dcs_profile_uuid = "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c"
$std_profile_desc = "Balanced"
$std_profile_uuid = "381b4222-f694-41f0-9685-ff5bb260df2e"

# GPU variables
$gpu_bclk_oset = 110
$gpu_memclk_oset = 0200
$gpu_lock_voltage = 968000
$gpu_pwr_tgt = 114
$gpu_temp_tgt = 83

# Valve lighthouses
$valve_lhb = @{
	'F1:D0:1B:99:C7:5C' = 'LHB-B07B2E11'
	'D6:DC:1A:DA:A7:D7' = 'LHB-E51493C5'
}

# USB game controller devices required for gameplay
$game_controllers = @{
	'VID_3344&PID_0134' = 'VPC Stick MT-50CM2'
	'VID_3344&PID_01F6' = 'BRD-F2'
	'VID_4098&PID_BE03' = 'WINWING F18 STARTUP PANEL'
	'VID_4098&PID_BE04' = 'WINWING F18 TAKEOFF PANEL'
	'VID_4098&PID_BE05' = 'WINWING F18 COMBAT READY PANEL'
	'VID_4098&PID_BE22' = 'WINWING F18 THROTTLE BASE + F18 HANDLE'
}

# Audio device name variables
$default_playback_device = "Headset Earphone"
$default_recording_device = "Headset Microphone"
$vr_playback_device = "HMD Earphone"
$vr_recording_device = "HMD Microphone"

#####################
# END CONFIGURATION #
#####################

# Get DCS version
$dcs_version = (Get-Command "$dcs_exe").FileVersionInfo.FileVersion
$dcs_variant_file = ($dcs_directory) +"\dcs_variant.txt.txt"
$dcs_variant = [IO.File]::ReadAllText("$dcs_variant_file")

# Parse VR command-line argument
	if ( $args[0] -eq "/VR" ) {
		[bool]$vr_enabled = 1
	}

	if ($cleanup_tracks){
		#Cleanup multiplayer tracks older than 30 days
		Get-ChildItem "$env:userprofile\Saved Games\DCS\Tracks\Multiplayer\" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | Remove-Item
	}

	if ($cleanup_kneeboard){
		#Cleanup kneeboard pages
		Get-ChildItem "$dcs_directory\Mods\terrains\Caucasus\Kneeboard" | Where-Object { $_.name -notlike '*Aerodromes*' } | Remove-Item
		Get-ChildItem "$dcs_directory\Mods\terrains\Nevada\Kneeboard" | Where-Object { $_.name -notlike '*Aerodromes*' } | Remove-Item
	}

# Drawing Functions
    function Write-Color([String[]]$Text, [ConsoleColor[]]$Color = "White", [int]$StartTab = 0, [int] $LinesBefore = 0,[int] $LinesAfter = 0, [string] $LogFile = "", $TimeFormat = "yyyy-MM-dd HH:mm:ss") {
    $DefaultColor = $Color[0]
    if ($LinesBefore -ne 0) {  for ($i = 0; $i -lt $LinesBefore; $i++) { Write-Host "`n" -NoNewline } }
    if ($StartTab -ne 0) {  for ($i = 0; $i -lt $StartTab; $i++) { Write-Host "`t" -NoNewline } }
    if ($Color.Count -ge $Text.Count) {
        for ($i = 0; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewline } 
    }
	else {
        for ($i = 0; $i -lt $Color.Length ; $i++) { Write-Host $Text[$i] -ForegroundColor $Color[$i] -NoNewline }
        for ($i = $Color.Length; $i -lt $Text.Length; $i++) { Write-Host $Text[$i] -ForegroundColor $DefaultColor -NoNewline }
	}
    Write-Host
    if ($LinesAfter -ne 0) {  for ($i = 0; $i -lt $LinesAfter; $i++) { Write-Host "`n" } }
    if ($LogFile -ne "") {
        $TextToFile = ""
        for ($i = 0; $i -lt $Text.Length; $i++) {
            $TextToFile += $Text[$i]
        }
        Write-Output "[$([datetime]::Now.ToString($TimeFormat))]$TextToFile" | Out-File $LogFile -Encoding unicode -Append
		}
	}

    function Bullet([String[]]$Text) {
    Write-Color "[", "►", "] ", "$Text" -Color Yellow, Green, Yellow, Gray
	}

    function BulletRed([String[]]$Text) {
    Write-Color "[", "►", "] ", "$Text" -Color Yellow, Red, Yellow, Gray
	}

    function BulletSound([String[]]$Text) {
    Write-Color "[", "♫", "] ", "$Text" -Color Yellow, Green, Yellow, Gray
	}

    function BulletInfinity([String[]]$Text) {
    Write-Color "[", "∞", "] ", "$Text" -Color Yellow, Green, Yellow, Gray
	}

    function BulletMisc([String[]]$Text) {
    Write-Color "[", "☼", "] ", "$Text" -Color Yellow, Green, Yellow, Gray
	}

    function BulletController([String[]]$Text) {
    Write-Color " ►", "○", "◄ ", "$Text" -Color Magenta, Magenta, Magenta, Gray
	}

    function BulletDone([String[]]$Text) {
    Write-Color "[", "√", "] ", "$Text" -Color Yellow, Green, Yellow, Gray
	}

#############
# DCS START #
#############

# Set boolean status display variables
    if ([bool]$trackir_enabled) {
    $trackir_status = "Enabled "
    }
    else {
    $trackir_status = "Disabled"
    }

    if ([bool]$simshaker_enabled) {
    $simshaker_status = "Enabled "
    }
    else {
    $simshaker_status = "Disabled"
    }

    if ([bool]$voiceattack_enabled) {
    $voiceattack_status = "Enabled "
    }
    else {
    $voiceattack_status = "Disabled"
    }
	
    if ([bool]$pitool_enabled) {
    $pitool_status = "Enabled "
    }
    else {
    $pitool_status = "Disabled"
    }

	if ([bool]$steamvr_enabled) {
    $steamvr_status = "Enabled "
    }
    else {
    $steamvr_status = "Disabled"
    }
	
	if ([bool]$kill_bloatware) {
    $bloatware_status = "Enabled "
    }
    else {
    $bloatware_status = "Disabled"
    }

Write-Color "╔═══════════════════════════════════════════════════════════════════╗" -Color White

if ($vr_enabled){
Write-Color "║ ░▒▓ ","DCS World Launcher VR"," ▓▒░	(DCS Version: ","$dcs_version $dcs_variant",") ║" -Color White, Blue, White, Red, White
Write-Color "╠══════════════════╦═══════════════════╦════════════════════════════╣" -Color White
Write-Color "║ PiTool: ","$pitool_status"," ║ SteamVR: ","$steamvr_status"," ║ Bloatware Kill: ","$bloatware_status","	║" -Color White, Yellow, White, Yellow, White, Yellow, White
Write-Color "╠══════════════════╩══╦════════════════╩════════════════════════════╣" -Color White
Write-Color "║ SimShaker: ","$simshaker_status"," ║ VoiceAttack: ","$voiceattack_status","				║" -Color White, Yellow, White, Yellow, White
Write-Color "╚═════════════════════╩═════════════════════════════════════════════╝" -Color White
}

else {
Write-Color "║ ░▒▓ ","DCS World Launcher"," ▓▒░	(DCS Version: ","$dcs_version $dcs_variant",") ║" -Color White, Blue, White, Red, White
Write-Color "╠════════════════════╦═════════════════════╦════════════════════════╣" -Color White
Write-Color "║ TrackIR: ","$trackir_status","  ║ SimShaker: ","$simshaker_status"," ║ VoiceAttack: ","$voiceattack_status","	║" -Color White, Yellow, White, Yellow, White, Yellow, White
Write-Color "╚════════════════════╩═════════════════════╩════════════════════════╝" -Color White
}

	if ($controller_check_enabled){
BulletMisc -Text "Checking for peripherals..."

	foreach ( $device in $game_controllers.GetEnumerator() ){
			if (Get-PnpDevice -PresentOnly -Status "OK" | Where-Object { $_.instanceId -match $device.Name }) {
				BulletController "Device $($device.Value) available"
			}
			else {
				$device_name = $game_controllers[$device]
				BulletRed "ERROR: Device $($device.Value) unavailable"
				BulletRed "Closing in 10 seconds..."
				Start-Sleep -s 10
				Stop-Process -Id $PID
			}
		}
	}
	
	if ($trackir_enabled -and !$vr_enabled){
		if (Get-PnpDevice -PresentOnly -Status "OK" | Where-Object { $_.instanceId -match "VID_131D&PID_0158" }) {
			BulletController "TrackIR camera available"
		}
		else {
			BulletRed "ERROR: TrackIR camera unavailable"
			BulletRed "Closing in 10 seconds..."
			Start-Sleep -s 10
			Stop-Process -Id $PID
		}
    }
	
	if ($vr_enabled){
		if (Get-PnpDevice -PresentOnly -Status "OK" | Where-Object { $_.instanceId -match "VID_0483&PID_0101" }) {
			BulletController "VR HMD available"
		}
		else {
			BulletRed "ERROR: VR HMD unavailable"
			BulletRed "Closing in 10 seconds..."
			Start-Sleep -s 10
			Stop-Process -Id $PID
		}
    }

BulletMisc -Text "Disabling dynamic ticks..."
bcdedit /set disabledynamictick yes | Out-Null

    if ($mfds_enabled){
BulletMisc -Text "Enabling secondary displays..."
Start-Process -FilePath $displaychanger_exe -ArgumentList '-quiet -monitor="\\.\DISPLAY2" -attach -lx=122 -ty=2160'
Start-Process -FilePath $displaychanger_exe -ArgumentList '-quiet -monitor="\\.\DISPLAY3" -attach -lx=122 -ty=2160'

BulletMisc -Text "Enabling Thrustmaster MFD panels..."
Get-PnpDevice | Where -property InstanceID -like "USB\VID_044F&PID_B351\7&16AFF6A1&0&3" | Enable-PnpDevice -confirm:$false
Get-PnpDevice | Where -property InstanceID -like "USB\VID_044F&PID_B352\7&16AFF6A1&0&1" | Enable-PnpDevice -confirm:$false
Get-PnpDevice | Where -property InstanceID -like "USB\VID_044F&PID_B353\7&16AFF6A1&0&4" | Enable-PnpDevice -confirm:$false
    }

BulletMisc -Text "Setting power plan to $dcs_profile_desc..."
Start-Process -FilePath $powercfg_exe -ArgumentList "/setactive $dcs_profile_uuid"

	if ($vr_enabled){
		BulletSound -Text "Setting default playback device to $vr_playback_device..."
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$vr_playback_device"" 1"
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$vr_playback_device"" 2"

		BulletSound -Text "Setting default recording device to $vr_recording_device..."
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$vr_recording_device"" 1"
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$vr_recording_device"" 2"
	}

	else {
		BulletSound -Text "Setting default playback device to $default_playback_device..."
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$default_playback_device"" 1"
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$default_playback_device"" 2"

		BulletSound -Text "Setting default recording device to $default_recording_device..."
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$default_recording_device"" 1"
		Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$default_recording_device"" 2"
	}

BulletMisc -Text "Setting GPU clocks & voltage..."
BulletMisc -Text "GPU Clock: ${gpu_bclk_oset}Mhz Memory Clock: ${gpu_memclk_oset}Mhz GPU Voltage: ${gpu_lock_voltage}V"
Start-Process -FilePath $nvidiainspector_exe -ArgumentList "-setBaseClockOffset:0,0,$gpu_bclk_oset -setMemoryClockOffset:0,0,$gpu_memclk_oset -lockVoltagePoint:0,$gpu_lock_voltage -setPowerTarget:0,$gpu_pwr_tgt -setTempTarget:0,0,$gpu_temp_tgt"

    if ($kill_bloatware){
        Bullet -Text "Killing bloatware..."
		Stop-Process -Name 'iCUE' -ErrorAction SilentlyContinue	# Corsair iCUE
		Start-Sleep -s 1
		Stop-Service -Name 'CorsairService'				# Corsair Service
		Stop-Service -Name 'CorsairLLAService'			# Corsair LLA Service
		Stop-Service -Name 'CorsairGamingAudioConfig'	# Corsair Gaming Audio Configuration Service
		Stop-Service -Name 'LightingService'			# LightingService
		Stop-Service -Name 'asComSvc'					# ASUS Com Service
		Start-Sleep -s 1
		Start-Process -FilePath $refreshtray_exe
    }

	if ($vr_enabled -and $lhb_control_enabled){
		foreach ( $device in $valve_lhb.GetEnumerator() ){
			Bullet -Text "Turning on lighthouse $($device.Value)..."
			Start-Process $lighthouse_manager_exe -WindowStyle Minimized -ArgumentList "on $($device.Name)"
		}
	}

	if (!$voiceattack_proc -and $voiceattack_enabled){
		Bullet -Text "Starting VoiceAttack..."
		Start-Process $voiceattack_exe
		Start-Sleep -s 1
	}

	if (!$trackir_proc -and $trackir_enabled -and !$vr_enabled){
		Bullet -Text "Starting TrackIR 5..."
		Start-Process $trackir_exe -WindowStyle Minimized
		Start-Sleep -s 1
	}

	if (!$simshaker_proc -and $simshaker_enabled){
        Bullet -Text "Starting SimShaker For Aviators..."
        Start-Process $simshaker_appref -WindowStyle Minimized
        Start-Sleep -s 2
	}
	
    if (!$pitool_proc -and $pitool_enabled -and $vr_enabled){
		Bullet -Text "Starting PiTool..."
		Start-Process $pitool_exe -WindowStyle Minimized -ArgumentList 'hide'
        Start-Sleep -s 15
	}

    if ($pitool_proc -and !$pitool_enabled -and $vr_enabled){
		Bullet -Text "PiTool already running..."
		Start-Process $pitool_exe -WindowStyle Minimized -ArgumentList 'hide'		
		[bool]$pitool_running = 1
	}

    if (!$pitool_proc -and !$pitool_enabled -and $vr_enabled){
		Bullet -Text "Starting PiServiceLauncher Service..."
		Start-Service -Name "PiServiceLauncher"
        Start-Sleep -s 8
	}

    if (!$vrmonitor_proc -and $steamvr_enabled -and $vr_enabled -and !$pitool_running){
        Bullet -Text "Starting SteamVR..."
        Start-Process $steamvr_server_exe -WindowStyle Minimized
        Start-Sleep -s 1
        Start-Process $steamvr_monitor_exe -WindowStyle Minimized
        Start-Sleep -s 2
    }

    if ($vr_enabled){
		Bullet -Text "Starting DCS World (VR Mode)..."
		Start-Process -FilePath $dcs_exe -ArgumentList '-w "DCS VR"'
	}
	else {
		Bullet -Text "Starting DCS World..."
		Start-Process -FilePath $dcs_exe
	}

BulletInfinity -Text "Waiting for DCS World to start..."
Start-Sleep -s 3
    if ($simshaker_enabled){
		Bullet -Text "Minimizing SimShaker for Aviators..."
		Start-Process -WindowStyle Minimized -FilePath $cmdow_exe -ArgumentList '"Seat*" /hid'
		Start-Process -WindowStyle Minimized -FilePath $cmdow_exe -ArgumentList '"SimShaker*" /hid'
	}

do {
    $status = Get-Process | where {$_.MainWindowTitle -like "Digital*Combat*Simulator*"} -ErrorAction SilentlyContinue
    if (!($status)) { Start-Sleep -Seconds 1 }
    else { Bullet -Text "DCS World has started..." ; $started = $true }
}
until ($started)
$dcs_proc = Get-Process "DCS" -ErrorAction SilentlyContinue
    if ($dcs_proc){

    if ($steamvr_enabled -and $vr_enabled){
        Start-Process -WindowStyle Minimized -FilePath $cmdow_exe -ArgumentList '"SteamVR*" /mov 2778 30'
		Start-Process -WindowStyle Minimized -FilePath $cmdow_exe -ArgumentList '"Digital*" /mov 1112 184'
        Start-Sleep -s 2
    }
        BulletInfinity -Text "Waiting for DCS World to close..."
        Wait-Process -name 'DCS'
    }
    else {
        BulletRed -Text "ERROR: DCS process failed to start" -Color Red
    }

############
# DCS STOP #
############

$voiceattack_proc = Get-Process "VoiceAttack" -ErrorAction SilentlyContinue
$simshaker_proc = Get-Process "SimShaker for Aviators" -ErrorAction SilentlyContinue
$srs_proc = Get-Process "SR-ClientRadio" -ErrorAction SilentlyContinue
$iba_proc = Get-Process "ibaJetseatHandler" -ErrorAction SilentlyContinue
$trackir_proc = Get-Process "TrackIR5" -ErrorAction SilentlyContinue

    if ($simshaker_proc){
        Bullet -Text "Stopping SimShaker For Aviators..."
        Stop-Process -Name 'SimShaker for Aviators'
        Wait-Process -Name 'SimShaker for Aviators' -ErrorAction SilentlyContinue
        if ($iba_proc){
            Stop-Process -Name 'ibaJetseatHandler'
            Wait-Process -Name 'ibaJetseatHandler' -ErrorAction SilentlyContinue
        }
    }

    if ($trackir_proc){
        Bullet -Text "Stopping TrackIR 5..."
        Stop-Process -Name 'TrackIR5'
        Wait-Process -Name 'TrackIR5' -ErrorAction SilentlyContinue
    }

    if ($voiceattack_proc){
        Bullet -Text "Stopping VoiceAttack..."
        Stop-Process -Name 'VoiceAttack'
        Wait-Process -Name 'VoiceAttack' -ErrorAction SilentlyContinue
    }

	if ($srs_proc){
        Bullet -Text "Stopping SimpleRadio..."
        Stop-Process -Name 'SR-ClientRadio'
        Wait-Process -Name 'SR-ClientRadio' -ErrorAction SilentlyContinue
    }

Start-Sleep -s 1

	if ($vr_enabled){
		Bullet -Text "Stopping SteamVR..."
		Get-Process vrmonitor | Foreach-Object { $_.CloseMainWindow() | Out-Null }
		Stop-Process -Name 'vrserver'
		Wait-Process -Name 'vrserver' -ErrorAction SilentlyContinue
		Start-Sleep -s 0.5

		$pitool_proc = Get-Process "PiTool" -ErrorAction SilentlyContinue
		if ($pitool_proc -and !$pitool_running){

			Bullet -Text "Closing PiTool..."
			Start-Process $pitool_exe -WindowStyle Minimized -ArgumentList 'hide'
			$wshell = New-Object -ComObject wscript.shell
			for ($i = 1; $i -lt 5; $i++)
			{
				$wshell.AppActivate("PiTool") | Out-Null
			}
			$pitool_proc.CloseMainWindow() | Out-Null
			sleep -s 0.6
			$wshell.SendKeys("{ENTER}")
		}

    if (!$pitool_enabled -and !$pitool_running){
		Bullet -Text "Stopping PiServiceLauncher Service..."
		Stop-Service -Name "PiServiceLauncher"
        Start-Sleep -s 2
		Stop-Process -Name 'pi_server' -ErrorAction SilentlyContinue
		Stop-Process -Name 'piService' -ErrorAction SilentlyContinue
        Start-Sleep -s 8
		}
	}

	if ($vr_enabled -and $lhb_control_enabled){
		foreach ( $device in $valve_lhb.GetEnumerator() ){
			Bullet -Text "Turning off lighthouse $($device.Value)..."
			Start-Process $lighthouse_manager_exe -WindowStyle Minimized -ArgumentList "off $($device.Name)"
		}
	}

BulletSound -Text "Setting default recording device to $default_recording_device..."
Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$default_recording_device"" 1"
Start-Process -FilePath $nircmd_exe -ArgumentList "setdefaultsounddevice ""$default_recording_device"" 2"

    if ($mfds_enabled){
		Bullet -Text "Disabling secondary displays..."
		Start-Process -FilePath $displaychanger_exe -ArgumentList '-monitor="\\.\DISPLAY2" -detach'
		Start-Process -FilePath $displaychanger_exe -ArgumentList '-monitor="\\.\DISPLAY3" -detach'

		Bullet -Text "Disabling Thrustmaster MFD panels..."
		Get-PnpDevice | Where -property InstanceID -like "USB\VID_044F&PID_B351\7&16AFF6A1&0&3" | Disable-PnpDevice -confirm:$false
		Get-PnpDevice | Where -property InstanceID -like "USB\VID_044F&PID_B352\7&16AFF6A1&0&1" | Disable-PnpDevice -confirm:$false
		Get-PnpDevice | Where -property InstanceID -like "USB\VID_044F&PID_B353\7&16AFF6A1&0&4" | Disable-PnpDevice -confirm:$false
    }

BulletMisc -Text "Resetting tray icons..."
Start-Process -FilePath $refreshtray_exe

BulletMisc -Text "Enabling dynamic ticks..."
bcdedit /set disabledynamictick no | Out-Null

BulletMisc -Text "Resetting GPU clocks & voltage to defaults..."
Start-Process -FilePath $nvidiainspector_exe -ArgumentList "-setBaseClockOffset:0,0,0 -setMemoryClockOffset:0,0,0000 -lockVoltagePoint:0,0 -setPowerTarget:0,0 -setTempTarget:0,0,0"

    if ($kill_bloatware){
        Bullet -Text "Restarting bloatware..."
		Start-Service -Name 'asComSvc'					# ASUS Com Service
		Start-Service -Name 'CorsairService'			# Corsair Service
		Start-Service -Name 'CorsairLLAService'			# Corsair LLA Service
		Start-Service -Name 'CorsairGamingAudioConfig'	# Corsair Gaming Audio Configuration Service
		Start-Service -Name 'LightingService'			# LightingService
		Start-Sleep -s 1
		Start-Process $icue_exe -WindowStyle Minimized -ArgumentList "--autorun"
    }

BulletMisc -Text "Setting power plan to $std_profile_desc..."
Start-Process -FilePath $powercfg_exe -ArgumentList "/setactive $std_profile_uuid"

BulletDone -Text "Closing in 5 seconds..."
Start-Sleep -s 5
Stop-Process -Id $PID