Import-Module Azure

$cred = Get-Credential

Login-AzureRmAccount -Credential $cred

$Subscriptions = Get-AzureRmsubscription

if ($SubscriptionName) {
	$Subscriptions = $Subscriptions | where { $_.SubscriptionName -EQ $SubscriptionName }
}
elseif ($SubscriptionId) {
	$Subscriptions = $Subscriptions | where { $_.SubscriptionId -EQ $SubscriptionId }
}

function Send-HTML($body) {
	$username = "user@email.com"
	$password = "Password"
	$smtpserver = "SMTP Server"
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

	Login-AzureRmAccount -Credential $cred -subscriptionid $SubscriptionId

	(Select-AzureSubscription -current -SubscriptionId $SubscriptionId)

    $i++

    Write-Progress -activity $subscription.SubscriptionName -PercentComplete ($i/$Subscriptions.Count*100)

    $rcvaults=Get-AzureRmRecoveryServicesVault

    foreach ($rcvault in $rcvaults) {
		Write-Host $rcvault.Name
		
		
		get-azurermrecoveryservicesvault -name $rcvault.Name | set-azurermrecoveryservicesvaultcontext;
		$JobStatus = Get-AzureRmRecoveryServicesBackupJob -From (Get-Date).AddDays(-1).ToUniversalTime() | Select WorkloadName,Operation,Status,StartTime,EndTime;
		
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
Write-Host "No of jobs Completed" $CompletedJobs.Count 
Write-Host "No of jobs In Progress" $InprogressJobs.count 
Write-Host "No of jobs Failed" $FailedJobs.Count 

$body += "</table>"

$body += "<br>Vaults without backup jobs: " + $emptyJob.Substring(0,$emptyJob.Length-2) + "<br>"

$body += "<br>Number of jobs Completed: " + $CompletedJobs.Count
$body += "<br>Number of jobs In Progress: " + $InprogressJobs.count
$body += "<br>Number of jobs Failed: " + $FailedJobs.Count

$body += "</table>" `
	   + "</body>" `
	   + "</html>"

Send-HTML($body)