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

function Out-Excel {
  param($Path = "$AzureBackupReport$(Get-Date -Format yyyyMMddHH).csv")

  $input | Export-CSV -Path $Path -UseCulture -Encoding UTF8 -NoTypeInformation

  Invoke-Item -Path $Path
}

$jobsAllArray = @()
 
$i = 0
 
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

		foreach($job in $JobStatus) {
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
	$CompletedJjobs= $jobsAllArray.Where({$_.Status -eq 'Completed'})
    $InprogressJobs= $jobsAllArray.Where({$_.Status -eq 'InProgress'})
    $FailedJobs= $jobsAllArray.Where({$_.Status -eq 'Failed'})
}  
Write-Host "No of jobs Completed" $CompletedJjobs.Count 
Write-Host "No of jobs In Progress" $InprogressJobs.count 
Write-Host "No of jobs Failed" $FailedJobs.Count 
$jobsAllArray | Select-Object "BackupVault", "ServerName", "Operation", "Status", "StartTime", "EndTime" | Out-Excel