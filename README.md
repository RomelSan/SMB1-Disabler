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
Set-ExecutionPolicy RemoteSigned
```
### Built on:
- Powershell 5.1
- XAML

### Required:
If you have Windows 10 or Windows Server 2016 you are good to go.
- Powershell 5.1 : [Powershell Link](https://msdn.microsoft.com/en-us/powershell/)
- Windows Management Framework 5.1 : [WMF Download Link](https://www.microsoft.com/en-us/download/details.aspx?id=54616)

### Important:
If you have Active Directory you should also disable LM and NTLM v1 in GPO.  
Navigate to Computer Configuration\Windows\Settings\Security Settings\Local Policies\Security Options  
and set the "Network security: LAN Manager authentication level" field to "Send NTLMv2 response only/refuse LM & NTLM"

### Contact
Twitter: [@RomelSan](http://www.twitter.com/RomelSan)    
Date: April 15, 2017

### License
MIT
