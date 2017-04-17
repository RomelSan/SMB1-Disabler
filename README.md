# SMB1 Disabler PS
### Description
This tool checks and can disable the insecure SMB v1 protocol.  
By default SMB version 1.0 is enabled in Windows 10 and Windows Server 2016.  
SMB 1.0 was needed in Windows XP and Windows Server 2003, but now newer versions of SMB are more secure and have additional features.  
It’s a good idea to disable or remove SMB version 1.0 as a number of recent vulnerabilities specifically affect SMB version 1, like [MS17-010](https://technet.microsoft.com/library/security/MS17-010)  

### Usage:
Open Powershell as Administrator and run the script.  
If you have problems you should check your execution policies.  
```Powershell
Get-ExecutionPolicy
Set-ExecutionPolicy RemoteSigned
```

If "RemoteSigned" didn't work set temporally "Unrestricted".
```Powershell
Set-ExecutionPolicy Unrestricted
```
### Built on:
- Powershell 5.1
- XAML

### Required:
If you have Windows 10 or Windows Server 2016 you are good to go.
- Powershell 5.1 : [Powershell Link](https://msdn.microsoft.com/en-us/powershell/)
- Windows Management Framework 5.1 : [WMF Download Link](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

### Do it manually:
1) Open PowerShell as Administrator

2) Check SMB1
```Powershell
Get-SmbServerConfiguration | Select-Object -Property "EnableSMB1Protocol"
Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol | Select-Object -Property "State"
```

2) Disable SMB1
```Powershell
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
```

3) Disable SMB1 Feature
```Powershell
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
```
4) Restart computer

You can propagate this via GPO:   
You need to create and edit the policy, navigate to:  
Computer Configuration > Windows Settings > Scripts  
And add these lines as PowerShell script.  
```Powershell
Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force  
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
```

### Important:
If you have Active Directory you should also disable LM and NTLM v1 in GPO.  
Navigate to Computer Configuration\Windows\Settings\Security Settings\Local Policies\Security Options  
and set the "Network security: LAN Manager authentication level" field to "Send NTLMv2 response only/refuse LM & NTLM"

### Contact
Twitter: [@RomelSan](http://www.twitter.com/RomelSan)    
Date: April 15, 2017

### License
MIT
