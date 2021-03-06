param([string]$appxPathParam)

if (-not (Test-Path -Path $PSBoundParameters["appxPathParam"])) {
    Write-Error "The appxupload file does not exist. Double check that you have passed the file path as a parameter and the file exists." -ErrorAction Stop
}

Set-ExecutionPolicy RemoteSigned -Force

# Prepare materials from previous steps and runner environment variables
$appxUploadFilePath = $PSBoundParameters["appxPathParam"]
$username = $env:PartnerCenterClientId
$password = ConvertTo-SecureString $env:PartnerCenterClientSecret -AsPlainText -Force
$appStoreId = $env:PartnerCenterStoreId
$tenantId = $env:PartnerCenterTenantId

# ********* Create temporary directory for submission artifacts *********
$sbTempFolderPath = New-Item -Type Directory -Force -Path (Join-Path -Path 'D:\a\MediaFileManager\MediaFileManager\' -ChildPath 'SBTemp')

# ********* Install StoreBroker and import PowerShell Module *********
#git clone https://github.com/Microsoft/StoreBroker.git 'D:\a\MediaFileManager\MediaFileManager\SBGitRoot\'
#Import-Module -Force 'D:\a\MediaFileManager\MediaFileManager\SBGitRoot\StoreBroker'

Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
Install-Module -Name StoreBroker

# ********* Authenticate Store Broker *********
$cred = New-Object System.Management.Automation.PSCredential ($username, $password)
Set-StoreBrokerAuthentication -TenantId $tenantId -Credential $cred

# ********* Prepare Submission Package *********
$configFilePath = 'D:\a\MediaFileManager\MediaFileManager\.scripts\sbConfig.json'
New-SubmissionPackage -ConfigPath $configFilePath -AppxPath $appxUploadFilePath -OutPath $sbTempFolderPath -OutName 'submission'

# ********* UPDATE & COMMIT SUBMISSION *********
$submissionDataPath = Join-Path -Path $sbTempFolderPath -ChildPath 'submission.json'
$submissionPackagePath = Join-Path -Path $sbTempFolderPath -ChildPath 'submission.zip'

Update-ApplicationSubmission -Verbose -ReplacePackages -AppId $appStoreId -SubmissionDataPath $submissionDataPath -PackagePath $submissionPackagePath -AutoCommit -Force -NoStatus