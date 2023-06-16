function Is-Admin() {
    $current_principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $current_principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Toggle-Task($task, $enable) {
    $toggle = if ($switch) { "/enable" } else { "/disable" }

    $user_task_result = (Start-Process "schtasks.exe" -ArgumentList "/change $toggle /tn `"$task`"" -PassThru -Wait -WindowStyle Hidden).ExitCode
    $trustedinstaller_task_result = [int](C:\bin\MinSudo.exe --NoLogo --TrustedInstaller --Privileged cmd /c "schtasks.exe /change $toggle /tn `"$task`" > nul 2>&1 && echo 0 || echo 1")

    return $user_task_result -band $trustedinstaller_task_result
}

function main() {
    if (-not (Is-Admin)) {
        Write-Host "error: administrator privileges required"
        exit 1
    }

    $wildcards = @(
        "update",
        "maps",
        "helloface",
        "customer experience improvement program",
        "microsoft compatibility appraiser",
        "startupapptask",
        "dssvccleanup",
        "bitlocker",
        "chkdsk",
        "data integrity scan",
        "defrag",
        "diskcleanup",
        "diskfootprint",
        "languagecomponentsinstaller",
        "memorydiagnostic",
        "registry",
        "time synchronization",
        "time zone",
        "upnp",
        "windows filtering platform",
        "tpm",
        "systemrestore",
        "speech",
        "spaceport",
        "power efficiency",
        "cloudexperiencehost",
        "diagnosis",
        "file history",
        "bgtaskregistrationmaintenancetask",
        "autochk\\proxy",
        "siuf",
        "device information",
        "edp policy manager",
        "defender"
    )

    Write-Host "info: this may take a while..."

    $scheduled_tasks = schtasks /query /fo list
    $task_names = [System.Collections.ArrayList]@()

    foreach ($line in $scheduled_tasks) {
        if ($line.contains("TaskName:")) {
        ($task_names.Add($line.Split(":")[1].Trim().ToLower())) 2>&1 > $null
        }
    }

    foreach ($wildcard in $wildcards) {
        Write-Host "info: searching for $wildcard"
        foreach ($task in $task_names) {
            if ($task.contains($wildcard)) {
                if ((Toggle-Task -task $task -enable $false) -ne 0) {
                    Write-Host "error: failed toggling one or more scheduled tasks"
                    exit 1
                }
            }
        }
    }

    exit 0
}

main
