# Azure Vault Status Report
### by Cory Burns

Powershell scripts designed to be run in Powershell or as a Azure Automation Runbook that will 
grab the backup status for last night's Recovery Vault jobs

The CSV will will simply output a plain table report.  The Email (either through Powershell or through 
an Azure Automation Runbook) will email an HTML table that is nicely formated with color codes for 
Success, Backups In Progress, and Failures or Warnings.  It also will provide a count of Successes, 
Failures, etc and output any Vaults that do not have any backups running.

## Getting Started

### Powershell
#### CSV
* backup_report_csv.ps1

Run from a Powershell window. This will output a simple CSV that will include all jobs.

#### Email
* backup_report_html.ps1

Edit the SMTP information in the Send-HTML function to utilize your preferred email server.  Run from a Powershell window. 

### Runbook
#### Email
* backup_report_html_automation.ps1

This runs in Azure Automation.  Use a daily schedule to get status reports on backups.

## Runbook Requirements
This requires the following modules to be imported into your Azure Automation Account:
* Azure.RecoveryServices
* AzureRM.RecoveryServices.Backup

This also requires Azure RunAs credentials set up, as well as SMTP credentials.

You will need to edit the Send-HTML function accordingly:

Line 32 - Change to match the Automation Credentials you set up for your SMTP account <br />
Line 35 - Modify to match your SMTP server if not using Gmail  <br />
Line 36 - Modify to match your SMTP server's port if not using Gmail <br />
Line 38 - Modify your subject <br />
Line 39 - Modify your FROM address to match your SMTP account <br />
Line 40 - Modify your TO address, use commas to separate recipients
