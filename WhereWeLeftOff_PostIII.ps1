$secpasswd = ConvertTo-SecureString 'IWouldLiketoRecoverPlease1!' -AsPlainText -Force
$SafeModePW = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
$secpasswd = ConvertTo-SecureString 'IveGot$kills!' -AsPlainText -Force
$localuser = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
 
configuration TestLab 
{ 
     param
    ( 
        [string[]]$NodeName ='localhost', 
        [Parameter(Mandatory)][string]$MachineName, 
        [Parameter(Mandatory)][string]$DomainName,
        [Parameter()]$firstDomainAdmin,
        [Parameter()][string]$UserName,
        [Parameter()]$SafeModePW,
        [Parameter()]$Password
    ) 
        
    #Import the required DSC Resources  
    Import-DscResource -Module xComputerManagement 
    Import-DscResource -Module xActiveDirectory 
   
    Node $NodeName
    { #ConfigurationBlock 
        xComputer NewNameAndWorkgroup 
        { 
            Name          = $MachineName
            WorkgroupName = 'TESTLAB'
             
        }
          
          
        User LocalAdmin {
            UserName = $UserName
            Description = 'Our new local admin'
            Ensure = 'Present'
            FullName = 'Stephen FoxDeploy'
            Password = $Password
            PasswordChangeRequired = $false
            PasswordNeverExpires = $true
            DependsOn = '[xComputer]NewNameAndWorkGroup'
        }
  
        Group AddToAdmin{
            GroupName='Administrators'
            DependsOn= '[User]LocalAdmin'
            Ensure= 'Present'
            MembersToInclude=$UserName
  
        }
 
        WindowsFeature ADDSInstall 
        { 
            DependsOn= '[Group]AddToAdmin'
            Ensure = 'Present'
            Name = 'AD-Domain-Services'
            IncludeAllSubFeature = $true
        }
         
        WindowsFeature RSATTools 
        { 
            DependsOn= '[WindowsFeature]ADDSInstall'
            Ensure = 'Present'
            Name = 'RSAT-AD-Tools'
            IncludeAllSubFeature = $true
        }  
 
        xADDomain SetupDomain {
            DomainAdministratorCredential= $firstDomainAdmin
            DomainName= $DomainName
            SafemodeAdministratorPassword= $SafeModePW
            DependsOn='[WindowsFeature]RSATTools'
            DomainNetbiosName = $DomainName.Split('.')[0]
        }
    #End Configuration Block    
    } 
}
 
$configData = 'a'
 
$configData = @{
                AllNodes = @(
                              @{
                                 NodeName = 'localhost';
                                 PSDscAllowPlainTextPassword = $true
                                    }
                    )
               }
 
 
TestLab -MachineName DSCDC01 -DomainName Fox.test -Password $localuser `
    -UserName 'FoxDeploy' -SafeModePW $SafeModePW `
    -firstDomainAdmin (Get-Credential -UserName 'FoxDeploy' -Message 'Specify Credentials for first domain admin') -ConfigurationData $configData
  
Start-DscConfiguration -ComputerName localhost -Wait -Force -Verbose -path .\TestLab -Debug