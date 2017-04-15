$inputXML = @"
<Window x:Class="SMB1_GUI.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:SMB1_GUI"
        mc:Ignorable="d"
        Title="SMB1 Disabler" Height="384.211" Width="781.579" ResizeMode="NoResize" WindowStyle="SingleBorderWindow">
    <Grid>
        <Label x:Name="label_status_server" Content="SMB1 Server: Checking..." HorizontalAlignment="Left" Margin="65,30,0,0" VerticalAlignment="Top" FontSize="36"/>
        <Label x:Name="label_status_client" Content="SMB1 Client: Checking..." HorizontalAlignment="Left" Margin="65,109,0,0" VerticalAlignment="Top" FontSize="36"/>
        <Button x:Name="disable_SMB1" Content="Disable SMB1" HorizontalAlignment="Left" Margin="265,221,0,0" VerticalAlignment="Top" Width="259" Height="66" FontSize="36"/>

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
$client_info="OK"
$server_info="OK"

Function check-server {
$server_status=Get-SmbServerConfiguration
    if ($server_status.EnableSMB1Protocol -eq $false)
        { 
            $WPFlabel_status_server.Content="SMB1 Server: Disabled"
        }
    if ($server_status.EnableSMB1Protocol -eq $true)
        { 
            $WPFlabel_status_server.Content="SMB1 Server: Enabled"
            $server_info="danger"
            $WPFdisable_SMB1.IsEnabled=$true
        }
}
Function check-client {
$client_status=Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
    if ($client_status.State -eq "Disabled")
        { 
            $WPFlabel_status_client.Content="SMB1 Client: Disabled"
        }
    if ($client_status.EnableSMB1Protocol -eq "Enabled")
        { 
            $WPFlabel_status_client.Content="SMB1 Client: Enabled"
            $client_info="danger"
            $WPFdisable_SMB1.IsEnabled=$true
        }
}
Function make-correction {
    if ($server_info="danger")
        {
            Set-SmbServerConfiguration -EnableSMB1Protocol $false
        }
    if ($client_info="danger")
        {
            Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol
        }
check-server
check-client
}

$WPFdisable_SMB1.Add_Click({
make-correction
$WPFdisable_SMB1.IsEnabled=$false
})
#===========================================================================
# Shows the form
#===========================================================================
write-host "To show the form, run the following" -ForegroundColor Cyan
check-server
check-client
$Form.ShowDialog() | out-null
