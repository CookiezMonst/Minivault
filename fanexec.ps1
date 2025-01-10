# Define variables
$fanControlPath = "asusfancontrol.exe"
$highSpeedDuration = 30  # Duration to run high-speed fan in seconds (30 seconds)
$cycleInterval = 600      # Interval for auto cycle in seconds (10 minutes)
$tempThreshold = 50       # CPU temperature threshold in degrees Celsius (for normal ramp-up)
$criticalTempThreshold = 80  # Critical CPU temperature threshold (for immediate fan boost)
$resetCycle = $false       # Flag to reset the auto-cycle

# Function to apply dynamic fan curve
function Apply-FanCurve {
    param ([int]$currentRPM)
    if ($currentRPM -lt 500) { $global:fancurvespeed=10 }
    elseif ($currentRPM -lt 1300) { $global:fancurvespeed=20 }
    elseif ($currentRPM -lt 1800) { $global:fancurvespeed=30 }
    elseif ($currentRPM -lt 2500) { $global:fancurvespeed=40 }
    elseif ($currentRPM -lt 2900) { $global:fancurvespeed=50 }
    elseif ($currentRPM -lt 3400) { $global:fancurvespeed=60 }
    elseif ($currentRPM -lt 3800) { $global:fancurvespeed=70 }
    elseif ($currentRPM -lt 4300) { $global:fancurvespeed=80 }
    elseif ($currentRPM -lt 4900) { $global:fancurvespeed=90 }
    else { $global:fancurvespeed=100 }
    Write-Output "GLB $global:fancurvespeed"
}

# Function to set fan speed gradually (from 20% to 100%)
function Ramp-UpFan {
    param(
        [int]$startSpeed,
        [int]$targetSpeed
    )
    
    $currentSpeed = $startSpeed

    # Set the fan speed explicitly to 20% at the start
    Write-Output "$(Get-Date -Format 'HH:mm:ss') - Setting fan speed to $currentSpeed% (initial)."
    & $fanControlPath --set-fan-speeds=$currentSpeed
    Start-Sleep -Seconds 5  # Allow the fan speed to settle

    # Gradually increase fan speed to the target speed in steps of 10%
    while ($currentSpeed -lt $targetSpeed) {
        $currentSpeed += 10  # Increase by 10% at each step
        if ($currentSpeed -gt $targetSpeed) {
            $currentSpeed = $targetSpeed  # Ensure it doesn't exceed the target
        }
        
        Write-Output "$(Get-Date -Format 'HH:mm:ss') - Setting fan speed to $currentSpeed%."
        & $fanControlPath --set-fan-speeds=$currentSpeed
        Start-Sleep -Seconds 5  # Wait for 5 seconds before increasing speed
    }
}


# Function to set fan speed to 0% (letting system manage fan)
function Set-FanLow {
    Write-Output "$(Get-Date -Format 'HH:mm:ss') - Setting fan to system-controlled speed (0%)..."
    & $fanControlPath --set-fan-speeds=0  # Let the system manage the fan speed
}

# Function to set fan speed to 100% immediately
function Set-FanHighImmediately {
    Write-Output "$(Get-Date -Format 'HH:mm:ss') - CPU temperature exceeds critical threshold ($criticalTempThreshold°C). Boosting fan to 100% immediately!"
    & $fanControlPath --set-fan-speeds=100
}

# Function to check CPU temperature
function Check-CPUTemperature {
    $output1 = & $fanControlPath --get-cpu-temp
    if ($output1 -match "Current CPU temp:\s(\d+)") {
        return [int]$matches[1]
    } else {
        Write-Output "$(Get-Date -Format 'HH:mm:ss') - Unable to read CPU temperature."
        return $null
    }
}

# Function to check fan speeds
function Check-FANspeeds {
    $output2 = & $fanControlPath --get-fan-speeds
    if ($output2 -match "Current fan speeds:\s(\d+) RPM") {
        return [int]$matches[1]
    } else {
        Write-Output "$(Get-Date -Format 'HH:mm:ss') - Unable to read fan-speeds."
        return $null
    }
}

# Initialize the auto-cycle timer
$lastCycleTime = [datetime]::Now

# Main logic loop
while ($true) {
    # Step 1: Check CPU temperature
    $cpuTemp = Check-CPUTemperature
    $fanspeeds = Check-FANspeeds
    if ($cpuTemp -ne $null) {
        if ($cpuTemp -ge $criticalTempThreshold) {
            # Immediate fan boost if CPU temperature exceeds critical threshold (80°C)
            Set-FanHighImmediately
            Start-Sleep -Seconds $highSpeedDuration
            Set-FanLow  # After the high-speed duration, let the system manage the fan
            $resetCycle = $true  # Signal to reset the auto-cycle
        } elseif ($cpuTemp -gt $tempThreshold) {

            Write-Output "$(Get-Date -Format 'HH:mm:ss') - CPU temperature ($cpuTemp°C) exceeds normal threshold ($tempThreshold°C). Boosting fan speed."
            
            # Ramp up fan speed gradually from 20% to 100% if temperature is above the normal threshold
            Apply-FanCurve -currentRPM $fanspeeds
               Write-Output "$fanspeeds" "$global:fancurvespeed"
            Ramp-UpFan -startSpeed $global:fancurvespeed -targetSpeed 100
            
            Start-Sleep -Seconds $highSpeedDuration
            Set-FanLow  # Let the system control fan speed after boosting
            $resetCycle = $true  # Signal to reset the auto-cycle
        }
    }

    # Step 2: Handle auto-cycle logic
    $elapsedTime = ([datetime]::Now - $lastCycleTime).TotalSeconds
    if ($resetCycle) {
        Write-Output "$(Get-Date -Format 'HH:mm:ss') - CPU temp check triggered. Resetting auto-cycle timer."
        $lastCycleTime = [datetime]::Now
        $resetCycle = $false
    } elseif ($elapsedTime -ge $cycleInterval) {
        Write-Output "$(Get-Date -Format 'HH:mm:ss') - Running periodic fan boost (auto-cycle)..."
        
        # Ramp up fan speed gradually from 20% to 100% (auto-cycle)
        Apply-FanCurve -currentRPM $fanspeeds
            Write-Output "$fanspeeds" "$global:fancurvespeed"
        Ramp-UpFan -startSpeed $global:fancurvespeed -targetSpeed 100
        
        Start-Sleep -Seconds $highSpeedDuration
        Set-FanLow  # Let the system control fan speed after boosting
        $lastCycleTime = [datetime]::Now  # Reset the auto-cycle timer
    }

    # Step 3: Wait briefly before the next iteration
    Start-Sleep -Seconds 5
}
