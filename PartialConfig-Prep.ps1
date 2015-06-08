$secpasswd = ConvertTo-SecureString 'IveGot$kills!' -AsPlainText -Force
$localuser = New-Object System.Management.Automation.PSCredential ('guest', $secpasswd)
 
 
configuration TestLab 
{ 
     param
    ( 
        [string[]]$NodeName ='localhost', 
        [Parameter(Mandatory)][string]$MachineName,
        [Parameter()][string]$UserName,
        [Parameter()]$Password
    ) 


    Import-DscResource -Module xComputerManagement 

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
 
 
TestLab -MachineName DSCDC01 -Password $localuser -UserName 'FoxDeploy' -ConfigurationData $configData
    #-firstDomainAdmin (Get-Credential -UserName 'FoxDeploy' -Message 'Specify Credentials for first domain admin') 
    
  
Start-DscConfiguration -ComputerName localhost -Wait -Force -Verbose -path .\TestLab -Debug