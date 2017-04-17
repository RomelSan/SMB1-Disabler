# SMB1 Disabler
# By Romel Vera (https://www.github.com/RomelSan)
# This tool checks and can disable the insecure SMB v1 protocol
# License: MIT 
# Build: April 15, 2017

#===========================================================================
# Check Admin
#===========================================================================
function Test-IsAdmin {
([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
}

if (!(Test-IsAdmin)){
Write-Host "`r`nPlease run this script with admin priviliges`r`n" -ForegroundColor Green
exit
}
else {
Write-Host "`r`nAdmin Check: OK" -ForegroundColor Green
}

#===========================================================================
# Check PowerShell Version
#===========================================================================
$global:powershellVersion=$PSVersionTable.PSVersion.Major
if ($global:powershellVersion -gt 4)
    {
        Write-Host "PowerShell Version: OK" -ForegroundColor Green
    }
else
    {
        Write-Host "PowerShell Version: NOT OK" -ForegroundColor Yellow
    }

#===========================================================================
# XAML
#===========================================================================
$inputXML = @"
<Window x:Class="SMB1_GUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:SMB1_GUI"
        mc:Ignorable="d"
        Title="SMB1 Disabler" Height="409.987" Width="781.579" ResizeMode="NoResize" WindowStyle="SingleBorderWindow">
    <Grid>
        <Label x:Name="label_status_server" Content="SMB1 Server:" HorizontalAlignment="Left" Margin="65,122,0,0" VerticalAlignment="Top" FontSize="36"/>
        <Label x:Name="label_status_client" Content="SMB1 Client:" HorizontalAlignment="Left" Margin="65,201,0,0" VerticalAlignment="Top" FontSize="36"/>
        <Button x:Name="disable_SMB1" Content="Disable SMB1" HorizontalAlignment="Left" Margin="265,280,0,0" VerticalAlignment="Top" Width="259" Height="66" FontSize="36"/>
        <Label x:Name="label_server_result" Content="Checking..." HorizontalAlignment="Left" Margin="306,122,0,0" VerticalAlignment="Top" FontSize="36" Foreground="Red"/>
        <Label x:Name="label_client_result" Content="Checking..." HorizontalAlignment="Left" Margin="306,201,0,0" VerticalAlignment="Top" FontSize="36" Foreground="Red"/>
        <Label x:Name="label_notice" Content="SMB v1 is insecure" HorizontalAlignment="Left" Margin="65,28,0,0" VerticalAlignment="Top" FontSize="36"/>
        <Label x:Name="label_credits" Content="https://www.github.com/RomelSan" HorizontalAlignment="Left" VerticalAlignment="Top" FontSize="10"/>
    </Grid>
</Window>
"@
$inputXML = $inputXML -replace 'mc:Ignorable="d"','' -replace "x:N",'N'  -replace '^<Win.*', '<Window'
 
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
[xml]$XAML = $inputXML
#Read XAML
 
    $reader=(New-Object System.Xml.XmlNodeReader $xaml)
  try{$Form=[Windows.Markup.XamlReader]::Load( $reader )}
catch{Write-Host "Unable to load Windows.Markup.XamlReader. Double-check syntax and ensure .net is installed."}
Write-Host "Loaded XAML: OK" -ForegroundColor Green
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
Write-Host "Parsing Variables: OK" -ForegroundColor Green
write-host "`r`nDebug: found the following interactable XAML elements" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
 
#===========================================================================
# Functions for XAML objects
#===========================================================================
$WPFdisable_SMB1.IsEnabled=$false
$global:client_info="OK"
$global:server_info="OK"

Write-Host "`r`nChecking SMB1 Protocol" -ForegroundColor Green

Function check-server {
$server_status=Get-SmbServerConfiguration
    if ($server_status.EnableSMB1Protocol -eq $false)
        { 
            $WPFlabel_server_result.Content="Disabled"
            $global:server_info="OK"
			Write-Host "SMB1 Protocol is currently Disabled" -ForegroundColor White
        }
		
    if ($server_status.EnableSMB1Protocol -eq $true)
        { 
            $WPFlabel_server_result.Content="Enabled"
            $global:server_info="danger"
            $WPFlabel_notice.Content="SMB v1 is insecure, disable it now!"
            $WPFdisable_SMB1.IsEnabled=$true
			Write-Host "SMB1 Protocol is currently Enabled" -ForegroundColor Yellow
        }
}

Function check-client {
$client_status=Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    if ($client_status.State -eq "Disabled")
        { 
            $WPFlabel_client_result.Content="Disabled"
            $global:client_info="OK"
			Write-Host "SMB1 Protocol as a feature is currently Disabled" -ForegroundColor White
        }
    if ($client_status.State -eq "Enabled")
        { 
            $WPFlabel_client_result.Content="Enabled"
            $global:client_info="danger"
            $WPFlabel_notice.Content="SMB v1 is insecure, disable it now!"
            $WPFdisable_SMB1.IsEnabled=$true
			Write-Host "SMB1 Protocol as a feature is currently Enabled" -ForegroundColor Yellow
        }
}

# Function that disables SMB1 Protocol
Function make-correction {
    if ($global:server_info -eq "danger")
        {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
        }
    if ($global:client_info -eq "danger")
        {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
        }
check-server
check-client
    if ($global:server_info -eq "OK" -and $global:client_info -eq "OK")
        {
            $WPFdisable_SMB1.Content="You are OK" 
            $WPFlabel_notice.Content="SMB v1 is disabled"
        }
}

#===========================================================================
# Make Elements Clickable
#===========================================================================
$WPFdisable_SMB1.Add_Click({
$msgBoxInput =  [System.Windows.MessageBox]::Show('The computer may restart, Continue?','Warning','YesNoCancel','Warning')
  switch  ($msgBoxInput) 
    {
        'Yes' 
            {
                $WPFdisable_SMB1.IsEnabled=$false
                make-correction
            }

        'No' 
            {
                # Do Nothing
            }
    }
})

# Main (Runs before showing the form)
check-server
check-client
if ($global:server_info -eq "OK" -and $global:client_info -eq "OK"){$WPFdisable_SMB1.Content="You are OK"; $WPFlabel_notice.Content="SMB v1 is disabled"}

#===========================================================================
# Shows the form
#===========================================================================
write-host "`r`nShow GUI: OK" -ForegroundColor Green
$Form.ShowDialog() | out-null
