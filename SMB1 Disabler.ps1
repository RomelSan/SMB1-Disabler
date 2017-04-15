# SMB1 Disabler
# By Romel Vera (https://www.github.com/RomelSan)
# This tool checks and can disable the insecure SMB v1 protocol
# License: MIT

#===========================================================================
# Check Admin
#===========================================================================
function Test-IsAdmin {

([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

}

if (!(Test-IsAdmin)){

throw "Please run this script with admin priviliges"

}
else {

Write-Host "Got admin"
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
        <Button x:Name="disable_SMB1" Content="Disable SMB1" HorizontalAlignment="Left" Margin="265,283,0,0" VerticalAlignment="Top" Width="259" Height="66" FontSize="36"/>
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
 
#===========================================================================
# Store Form Objects In PowerShell
#===========================================================================
 
$xaml.SelectNodes("//*[@Name]") | %{Set-Variable -Name "WPF$($_.Name)" -Value $Form.FindName($_.Name)}
 
Function Get-FormVariables{
if ($global:ReadmeDisplay -ne $true){Write-host "If you need to reference this display again, run Get-FormVariables" -ForegroundColor Yellow;$global:ReadmeDisplay=$true}
write-host "Found the following interactable elements from our form" -ForegroundColor Cyan
get-variable WPF*
}
 
Get-FormVariables
 
#===========================================================================
# Actually make the objects work
#===========================================================================
$WPFdisable_SMB1.IsEnabled=$false
$global:client_info="OK"
$global:server_info="OK"

Function check-server {
$server_status=Get-SmbServerConfiguration
    if ($server_status.EnableSMB1Protocol -eq $false)
        { 
            $WPFlabel_server_result.Content="Disabled"
            $global:server_info="OK"
        }
    if ($server_status.EnableSMB1Protocol -eq $true)
        { 
            $WPFlabel_server_result.Content="Enabled"
            $global:server_info="danger"
            $WPFlabel_notice.Content="SMB v1 is insecure, disable it now!"
            $WPFdisable_SMB1.IsEnabled=$true
        }
}
Function check-client {
$client_status=Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    if ($client_status.State -eq "Disabled")
        { 
            $WPFlabel_client_result.Content="Disabled"
            $global:client_info="OK"
        }
    if ($client_status.EnableSMB1Protocol -eq "Enabled")
        { 
            $WPFlabel_client_resut.Content="Enabled"
            $global:client_info="danger"
            $WPFlabel_notice.Content="SMB v1 is insecure, disable it now!"
            $WPFdisable_SMB1.IsEnabled=$true
        }
}
Function make-correction {
    if ($global:server_info="danger")
        {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false
        }
    if ($global:client_info="danger")
        {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
        }
check-server
check-client
    if ($global:server_info -eq "OK" -and $global:client_info -eq "OK")
        {
            $WPFdisable_SMB1.Content="You are OK" 
            $WPFlabel_notice.Content="SMB v1 is disabled"
        }
}

# Main Run
check-server
check-client
if ($global:server_info -eq "OK" -and $global:client_info -eq "OK"){$WPFdisable_SMB1.Content="You are OK"; $WPFlabel_notice.Content="SMB v1 is disabled"}

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

#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
$Form.ShowDialog() | out-null
