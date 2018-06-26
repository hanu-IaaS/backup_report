Import-Module Azure
Import-Module AzureRM.RecoveryServices
Import-Module AzureRM.RecoveryServices.Backup

$connectionName = "AzureRunAsConnection"

try {
	# Get the connection "AzureRunAsConnection"
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint   $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection) {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    }
	else {
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
}

$Subscriptions = Get-AzureRmSubscription

function Send-HTML($body) {
	$creds = Get-AutomationPSCredential -Name "AutomationCredentials"
	$username = $creds.GetNetworkCredential().UserName
	$password = $creds.GetNetworkCredential().Password
	$smtpserver = "smtp.gmail.com"
	$port = "587"

	$subject = "Azure Backup Report"
	$from = "user@email.com" # Change this to the full email address you are using to relay SMTP
	$to = "recipient@email.com" # For multiple recipients, separate with commas
	
	$email = New-Object System.Net.Mail.MailMessage
	$email.From = $from
	$email.To.Add($to)
	$email.Subject = $subject
	$email.IsBodyHtml = $true
	$email.Body = $body

	$smtpClient = New-Object System.Net.Mail.SmtpClient($smtpserver, $port)
	$smtpClient.EnableSsl = $true
	$smtpClient.Credentials = New-Object System.Net.NetworkCredential($username, $password)
	$smtpClient.send($email)
}

$jobsAllArray = @()
 
$i = 0

$body = "<html>" `
	  + "<body>" `
	  + "<table>"

$emptyJob = ""
 
foreach ( $Subscription in $Subscriptions ) {
	$SubscriptionId = $Subscription.SubscriptionId
	
	#Login-AzureRmAccount -Credential $cred -subscriptionid $SubscriptionId

	(Select-AzureRMSubscription -SubscriptionId $SubscriptionId)

    $i++

    $rcvaults=Get-AzureRmRecoveryServicesVault

    foreach ($rcvault in $rcvaults) {	
		get-azurermrecoveryservicesvault -name $rcvault.Name | set-azurermrecoveryservicesvaultcontext;
		$JobStatus = Get-AzureRmRecoveryServicesBackupJob -From (Get-Date).AddDays(-1).ToUniversalTime() | `
				     Select WorkloadName,Operation,Status,StartTime,EndTime;

		if ([string]::IsNullorEmpty($JobStatus)) {
			$emptyJob += $rcvault.Name + ", "
		}
		else {
			$body += "<tr>" `
			      + "<th colspan='5' style='background-color:SteelBlue; color: white;'>" `
			      + $rcvault.Name `
			      + "</th>" `
			      + "</tr>" `
			      + "<tr>" `
			      + "<th style='background-color:LightSteelBlue; color: white; padding:5px;'>Server Name</th>" `
			      + "<th style='background-color:LightSteelBlue; color: white; padding:5px;'>Operation</th>" `
			      + "<th style='background-color:LightSteelBlue; color: white; padding:5px;'>Status</th>" `
			      + "<th style='background-color:LightSteelBlue; color: white; padding:5px;'>Start Time</th>" `
			      + "<th style='background-color:LightSteelBlue; color: white; padding:5px;'>End Time</th>" `
			      + "</tr>"

			$rowcount = 0
		
			foreach($job in $JobStatus) {
				if ($rowcount % 2 -eq 0 ) {
					$body += "<tr>" `
					      + "<td style='background-color:PaleTurquoise; color: black; padding:5px; text-align: center;'>" `
					      + $Job.WorkloadName `
					      + "</td>" `
					      + "<td style='background-color:PaleTurquoise; color: black; padding:5px; text-align: center;'>" `
					      + $Job.Operation `
					      + "</td>"
					if ($Job.Status -eq "Completed") {
					   $body += "<td style='background-color:Lime; color: black; padding:5px; text-align: center;'>" `
					         + $Job.Status `
					         + "</td>"
					}
					elseif ($Job.Status -eq "InProgress") {
						$body += "<td style='background-color:Moccasin; color: black; padding:5px; text-align: center;'>" `
					          + $Job.Status `
						      + "</td>"
					}
					else {
						$body += "<td style='background-color:Red; color: black; padding:5px; text-align: center;'>" `
					          + $Job.Status `
						      + "</td>"
					}
					$body += "<td style='background-color:PaleTurquoise; color: black; padding:5px; text-align: center;'>" `
					      + $Job.StartTime `
					      + "</td>" `
					      + "<td style='background-color:PaleTurquoise; color: black; padding:5px; text-align: center;'>" `
					      + $Job.EndTime `
					      + "</td>" `
					      + "</tr>"
					$rowcount++
				}
				else {
					$body += "<tr>" `
				     	  + "<td style='background-color:LightCyan; color: black; padding:5px; text-align: center;'>" `
					      + $Job.WorkloadName `
					      + "</td>" `
					      + "<td style='background-color:LightCyan; color: black; padding:5px; text-align: center;'>" `
					      + $Job.Operation `
					      + "</td>"
					if ($Job.Status -eq "Completed") {
						$body += "<td style='background-color:Lime; color: black; padding:5px; text-align: center;'>" `
					           + $Job.Status `
						       + "</td>"
					}
					elseif ($Job.Status -eq "InProgress") {
						$body += "<td style='background-color:Moccasin; color: black; padding:5px; text-align: center;'>" `
					           + $Job.Status `
						       + "</td>"
					}
					else {
						$body += "<td style='background-color:Red; color: black; padding:5px; text-align: center;'>" `
					           + $Job.Status `
						       + "</td>"
					}
					$body += "<td style='background-color:LightCyan; color: black; padding:5px; text-align: center;'>" `
					       + $Job.StartTime `
					       + "</td>" `
					       + "<td style='background-color:LightCyan; color: black; padding:5px; text-align: center;'>" `
					       + $Job.EndTime `
						   + "</td>" `
					       + "</tr>"
					$rowcount++
				}
				$jobsAllArray += New-Object PSObject -Property @{`
					BackupVault=$rcvault.Name; `
					ServerName=$Job.WorkloadName; `
					Operation=$Job.Operation; `
					Status=$Job.Status;`
					StartTime=$Job.StartTime;`
					EndTime=$Job.EndTime;
				}
			}
		}
		$CompletedJobs= $jobsAllArray.Where({$_.Status -eq 'Completed'})
		$InprogressJobs= $jobsAllArray.Where({$_.Status -eq 'InProgress'})
		$FailedJobs= $jobsAllArray.Where({$_.Status -eq 'Failed'})
	}
}

$body += "</table>"

$body += "<br>Vaults without backup jobs: " + $emptyJob.Substring(0,$emptyJob.Length-2) + "<br>"

$body += "<br>Number of jobs Completed: " + $CompletedJobs.Count
$body += "<br>Number of jobs In Progress: " + $InprogressJobs.count
$body += "<br>Number of jobs Failed: " + $FailedJobs.Count

$body += "</table>" `
	   + "</body>" `
	   + "</html>"

Send-HTML($body)