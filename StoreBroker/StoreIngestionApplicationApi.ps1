# Copyright (C) Microsoft Corporation.  All rights reserved.

function Get-Applications
{
<#
    .SYNOPSIS
        Retrieves all of the applications associated with this developer account.

    .DESCRIPTION
        Retrieves all of the applications associated with this developer account.
        For formatted output of this result, consider piping the result into Format-Applications.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER MaxResults
        The number of applications that should be returned in the query.
        Defaults to 100.

    .PARAMETER StartAt
        The 0-based index (of all apps within your account) that the returned
        results should start returning from.
        Defaults to 0.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER GetAll
        If this switch is specified, the cmdlet will automatically loop in batches
        to get all of the applications in this account.  Using this will ignore
        the provided value for -StartAt, but will use the value provided for
        -MaxResults as its per-query limit.
        WARNING: This might take a while depending on how many applications are in
        your developer account.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-Applications
        Gets the first 100 applications associated with this developer account,
        with the console window showing progress while awaiting for the response
        from the REST request.

    .EXAMPLE
        Get-Applications -NoStatus
        Gets the first 100 applications associated with this developer account,
        but the request happens in the foreground and there is no additional status
        shown to the user until a response is returned from the REST request.

    .EXAMPLE
        Get-Applications 500
        Gets the first 500 applications associated with this developer account,
        with the console window showing progress while awaiting for the response
        from the REST request.

    .EXAMPLE
        Get-Applications 10 -StartAt 50
        Gets the next 10 apps in the developer account starting with the 51st app
        (since it's a 0-based index) with the console window showing progress while
        awaiting for the response from the REST request.

    .EXAMPLE
        $apps = Get-Applications
        Retrieves the first 100 applications associated with this developer account,
        and saves the results in a variable called $apps that can be used for
        further processing.

    .EXAMPLE
        Get-Applications -NoStatus | Format-Applications
        Pretty-print the results by piping them into Format-Applications.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Designed to mimic the actual API.")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [ValidateScript({if ($_ -gt 0) { $true } else { throw "Must be greater than 0." }})]
        [int] $MaxResults = 100,

        [ValidateScript({if ($_ -ge 0) { $true } else { throw "Must be greater than or equal to 0." }})]
        [int] $StartAt = 0,

        [string] $AccessToken = "",

        [switch] $GetAll,

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    $params = @{
        "UriFragment" = "applications"
        "Description" = "Getting applications"
        "MaxResults" = $MaxResults
        "StartAt" = $StartAt
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-Applications"
        "GetAll" = $GetAll
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethodMultipleResult @params)
}

function Format-Applications
{
<#
    .SYNOPSIS
        Pretty-prints the results of Get-Applications

    .DESCRIPTION
        This method is intended to be used by callers of Get-Applications.
        It takes the result from Get-Applications and presents it in a more easily
        viewable manner.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER ApplicationsData
        The output returned from Get-Applications.
        Supports Pipeline input.

    .EXAMPLE
        Format-Applications $(Get-Applications)
        Explicitly gets the result from Get-Applications and passes that in as the input
        to Format-Applications for pretty-printing.

    .EXAMPLE
        Get-Applications | Format-Applications
        Pipes the result of Get-Applications directly into Format-Applications for pretty-printing.
#>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseSingularNouns", "", Justification="Formatting method designed to mimic the actual API method.")]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject] $ApplicationsData
    )

    Begin
    {
        Set-TelemetryEvent -EventName Format-Applications

        Write-Log "Displaying Applications..." -Level Verbose

        $publishedDateField = @{ label="firstPublishedDate"; Expression={ Get-Date -Date $_.firstPublishedDate -Format G }; }
        $publishedSubmissionField = @{ label="lastPublishedSubmission"; Expression={ $_.lastPublishedApplicationSubmission.id }; }
        $pendingSubmissionField = @{ label="pendingSubmission"; Expression={ if ($null -eq $_.pendingApplicationSubmission.id) { "---" } else { $_.pendingApplicationSubmission.id } }; }

        $apps = @()
    }

    Process
    {
        $apps += $ApplicationsData
    }

    End
    {
        Write-Log $($apps | Sort-Object primaryName | Format-Table primaryName, id, packagefamilyname, $publishedDateField, $publishedSubmissionField, $pendingSubmissionField | Out-String)
    }
}

function Get-Application
{
<#
    .SYNOPSIS
        Retrieves the detail for the specified application associated with this
        developer account.

    .DESCRIPTION
        Retrieves the detail for the specified application associated with this
        developer account.  This information is almost identical to the information
        you would see by just calling Get-Applications.
        Pipe the result of this command into Format-Application for a pretty-printed display
        of the result.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that you want to retrieve the information
        about.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-Application 0ABCDEF12345
        Gets all of the applications associated with this developer account,
        with the console window showing progress while awaiting for the response
        from the REST request.

    .EXAMPLE
        Get-Application 0ABCDEF12345 -NoStatus
        Gets all of the applications associated with this developer account,
        but the request happens in the foreground and there is no additional status
        shown to the user until a response is returned from the REST request.

    .EXAMPLE
        $app = Get-Application 0ABCDEF12345
        Retrieves all of the applications associated with this developer account,
        and saves the results in a variable called $apps that can be used for
        further processing.

    .EXAMPLE
        Get-Application 0ABCDEF12345 | Format-Application
        Gets all of the applications associated with this developer account, and then
        displays it in a pretty-printed, formatted result.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory=$true)]
        [string] $AppId,
        
        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{ [StoreBrokerTelemetryProperty]::AppId = $AppId }

    $params = @{
        "UriFragment" = "applications/$AppId"
        "Method" = "Get"
        "Description" = "Getting data for AppId: $AppId"
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-Application"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Format-Application
{
<#
    .SYNOPSIS
        Pretty-prints the results of Get-Application

    .DESCRIPTION
        This method is intended to be used by callers of Get-Application.
        It takes the result from Get-Application and presents it in a more easily
        viewable manner.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER ApplicationData
        The output returned from Get-Application.
        Supports Pipeline input.

    .EXAMPLE
        Format-Application $(Get-Application 0ABCDEF12345)
        Explicitly gets the result from Get-Application and passes that in as the input
        to Format-Application for pretty-printing.

    .EXAMPLE
        Get-Application 0ABCDEF12345 | Format-Application
        Pipes the result of Get-Application directly into Format-Application for pretty-printing.
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject] $ApplicationData
    )

    Begin
    {
        Set-TelemetryEvent -EventName Format-Application

        Write-Log "Displaying Application..." -Level Verbose

        $output = @()
    }

    Process
    {
        $output += ""
        $output += "Primary Name              : $($ApplicationData.primaryName)"
        $output += "Id                        : $($ApplicationData.id)"
        $output += "Package Family Name       : $($ApplicationData.packageFamilyName)"
        $output += "First Published Date      : $(Get-Date -Date $ApplicationData.firstPublishedDate -Format R)"
        $output += "Last Published Submission : $($ApplicationData.lastPublishedApplicationSubmission.id)"
        $output += "Pending Submission        : $(if ($null -eq $ApplicationData.pendingApplicationSubmission.id) { "---" } else { $ApplicationData.pendingApplicationSubmission.id } )"
    }

    End
    {
       Write-Log $($output -join [Environment]::NewLine)
    }
}

function Get-ApplicationSubmission
{
<#
    .SYNOPSIS
        Retrieves the details of a specific application submission.

    .DESCRIPTION
        Gets the details of a specific application submission.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that you want to retrieve the information
        about.

    .PARAMETER SubmissionId
        The specific submission that you want to retrieve the information about.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789
        Gets all of the detail known for this application submission,
        with the console window showing progress while awaiting for the response
        from the REST request.

    .EXAMPLE
        Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789 -NoStatus
        Gets all of the detail known for this application submission,
        but the request happens in the foreground and there is no additional status
        shown to the user until a response is returned from the REST request.

    .EXAMPLE
        $submission = Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789
        Retrieves all of the applications submission detail, and saves the results in
        a variable called $submission that can be used for further processing.

    .EXAMPLE
        Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789 | Format-ApplicationSubmission
        Pretty-print the results by piping them into Format-ApplicationSubmission.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [Parameter(Mandatory)]
        [string] $SubmissionId,
        
        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::AppId = $AppId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
    }

    $params = @{
        "UriFragment" = "applications/$AppId/submissions/$SubmissionId"
        "Method" = "Get"
        "Description" = "Getting data for AppId: $AppId SubmissionId: $SubmissionId"
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-ApplicationSubmission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Format-ApplicationSubmission
{
<#
    .SYNOPSIS
        Pretty-prints the results of Get-ApplicationSubmission

    .DESCRIPTION
        This method is intended to be used by callers of Get-ApplicationSubmission.
        It takes the result from Get-ApplicationSubmission and presents it in a more easily
        viewable manner.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER ApplicationSubmissionData
        The output returned from Get-ApplicationSubmission.
        Supports Pipeline input.

    .EXAMPLE
        Format-ApplicationSubmission $(Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789)
        Explicitly gets the result from Get-ApplicationSubmission and passes that in as the input
        to Format-ApplicationSubmission for pretty-printing.

    .EXAMPLE
        Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789 | Format-ApplicationSubmission
        Pipes the result of Get-ApplicationSubission directly into Format-ApplicationSubmuission for pretty-printing.
#>
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory,
            ValueFromPipeline)]
        [PSCustomObject] $ApplicationSubmissionData
    )

    Begin
    {
        Set-TelemetryEvent -EventName Format-ApplicationSubmission

        Write-Log "Displaying Application Submission..." -Level Verbose

        $indentLength = 5
        $output = @()
    }

    Process
    {
        $output += ""
        $output += "Submission Id                       : $($ApplicationSubmissionData.id)"
        $output += "Friendly Name                       : $($ApplicationSubmissionData.friendlyName)"
        $output += "Application Category                : $($ApplicationSubmissionData.applicationCategory)"
        $output += "Visibility                          : $($ApplicationSubmissionData.visibility)"
        $output += "Publish Mode                        : $($ApplicationSubmissionData.targetPublishMode)"
        if ($null -ne $ApplicationSubmissionData.targetPublishDate)
        {
            $output += "Publish Date                        : $(Get-Date -Date $ApplicationSubmissionData.targetPublishDate -Format R)"
        }

        $output += "Automatic Backup Enabled            : $($ApplicationSubmissionData.automaticBackupEnabled)"
        $output += "Can Install On Removable Media      : $($ApplicationSubmissionData.canInstallOnRemovableMedia)"
        $output += "Has External InApp Products         : $($ApplicationSubmissionData.hasExternalInAppProducts)"
        $output += "Meets Accessibility Guidelines      : $($ApplicationSubmissionData.meetAccessibilityGuidelines)"
        $output += "Notes For Certification             : $($ApplicationSubmissionData.notesForCertification)"
        $output += "Enterprise Licensing                : $($ApplicationSubmissionData.enterpriseLicensing)"
        $output += "Available To Future Device Families : $($ApplicationSubmissionData.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies)"
        $output += ""

        $output += "Pricing                             :"
        $output += $ApplicationSubmissionData.pricing | Format-SimpleTableString -IndentationLevel $indentLength
        $output += ""

        $output += "Hardware Preferences                :"
        $output += $ApplicationSubmissionData.hardwarePreferences | Format-SimpleTableString -IndentationLevel $indentLength
        $output += ""

        $output += "Allow Target Future Device Families :"
        $output += $ApplicationSubmissionData.allowTargetFutureDeviceFamilies | Format-SimpleTableString -IndentationLevel $indentLength
        $output += ""

        $output += "File Upload Url                     : {0}" -f $(if ($ApplicationSubmissionData.fileUploadUrl) { $ApplicationSubmissionData.fileUploadUrl } else { "<None>" })
        $output += ""

        $output += "Application Packages                : {0}" -f $(if ($ApplicationSubmissionData.applicationPackages.count -eq 0) { "<None>" } else { "" })
        $output += $ApplicationSubmissionData.applicationPackages | Format-SimpleTableString -IndentationLevel $indentLength
        $output += ""

        $output += "Listings                            : {0}" -f $(if ($ApplicationSubmissionData.listings.count -eq 0) { "<None>" } else { "" })
        $listings = $ApplicationSubmissionData.listings
        foreach ($listing in ($listings | Get-Member -type NoteProperty))
        {
            $lang = $listing.Name
            $output += ""
            $output += "$(" " * $indentLength)$lang"
            $output += "$(" " * $indentLength)----------"
            $output += "$(" " * $indentLength)Description         : $($listings.$lang.baseListing.description)"
            $output += "$(" " * $indentLength)Copyright/Trademark : $($listings.$lang.baseListing.copyrightAndTrademarkInfo)"
            $output += "$(" " * $indentLength)Keywords            : $($listings.$lang.baseListing.keywords -join "; ")"
            $output += "$(" " * $indentLength)License Terms       : $($listings.$lang.baseListing.licenseTerms)"
            $output += "$(" " * $indentLength)Privacy Policy      : $($listings.$langbaseListing.privacyPolicy)"
            $output += "$(" " * $indentLength)Support Contact     : $($listings.$lang.baseListing.supportContact)"
            $output += "$(" " * $indentLength)Website Url         : $($listings.$lang.baseListing.websiteUrl)"
            $output += "$(" " * $indentLength)Features            : $($listings.$lang.baseListing.features -join "; ")"
            $output += "$(" " * $indentLength)Release Notes       : $($listings.$lang.baseListing.releaseNotes)"
            $output += "$(" " * $indentLength)Images              : {0}" -f $(if ($listings.$lang.baseListing.images.count -eq 0) { "<None>" } else { "" })
            $output += $listings.$lang.baseListing.images | Format-SimpleTableString -IndentationLevel $($indentLength * 2)
            $output += ""
            $output += "$(" " * $indentLength)Platform Overrides  : {0}" -f $(if ($listings.$lang.platformOverrides) { "<None>" } else { "" })
            $output += $listings.$lang.platformOverrides | Format-SimpleTableString -IndentationLevel $indentLength
            $output += ""
        }

        $output += "Status                                 : $($ApplicationSubmissionData.status)"
        $output += "Status Details [Errors]                : {0}" -f $(if ($ApplicationSubmissionData.statusDetails.errors.count -eq 0) { "<None>" } else { "" })
        $output += $ApplicationSubmissionData.statusDetails.errors | Format-SimpleTableString -IndentationLevel $indentLength
        $output += ""

        $output += "Status Details [Warnings]              : {0}" -f $(if ($ApplicationSubmissionData.statusDetails.warnings.count -eq 0) { "<None>" } else { "" })
        $output += $ApplicationSubmissionData.statusDetails.warnings | Format-SimpleTableString -IndentationLevel $indentLength
        $output += ""

        $output += "Status Details [Certification Reports] : {0}" -f $(if ($ApplicationSubmissionData.statusDetails.certificationReports.count -eq 0) { "<None>" } else { "" })
        foreach ($report in $ApplicationSubmissionData.statusDetails.certificationReports)
        {
            $output += $(" " * $indentLength) + $(Get-Date -Date $report.date -Format R) + ": $($report.reportUrl)"
        }
    }

    End
    {
        Write-Log $($output -join [Environment]::NewLine)
    }
}

function Get-ApplicationSubmissionStatus
{
<#
    .SYNOPSIS
        Retrieves just the status of a specific application submission.

    .DESCRIPTION
        Gets just the status of a specific application submission.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that you want to retrieve the information
        about.

    .PARAMETER SubmissionId
        The specific submission that you want to retrieve the information about.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Get-ApplicationSubmissionStatus 0ABCDEF12345 1234567890123456789

        Gets the status for this application submission, with the console window showing
        progress while awaiting for the response from the REST request.

    .EXAMPLE
        Get-ApplicationSubmissionStatus 0ABCDEF12345 1234567890123456789 -NoStatus

        Gets the status for this application submission,  but the request happens in the
        foreground and there is no additional status shown to the user until a response
        is returned from the REST request.

    .EXAMPLE
        $submission = Get-ApplicationSubmission 0ABCDEF12345 1234567890123456789

        Retrieves the status of the applications submission, and saves the results in
        a variable called $submission that can be used for further processing.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [Parameter(Mandatory)]
        [string] $SubmissionId,
        
        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::AppId = $AppId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
    }

    $params = @{
        "UriFragment" = "applications/$AppId/submissions/$SubmissionId/status"
        "Method" = "Get"
        "Description" = "Getting status for AppId: $AppId SubmissionId: $SubmissionId"
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Get-ApplicationSubmissionStatus"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params)
}

function Remove-ApplicationSubmission
{
    <#
    .SYNOPSIS
        Deletes the specified application submission from a developer account.

    .DESCRIPTION
        Deletes the specified application submission from a developer account.
        An app can only have a single "pending" submission at any given time,
        and submissions cannot be modified via the REST API once started.
        Therefore, before a new application submission can be submitted,
        this method must be called to remove any existing pending submission.

    .PARAMETER AppId
        The Application ID for the application that has the pending submission to be removed.

    .PARAMETER SubmissionId
        The ID of the pending submission that should be removed.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Remove-ApplicationSubmission 0ABCDEF12345 1234567890123456789
        Removes the specified application submission from the developer account,
        with the console window showing progress while awaiting for the response
        from the REST request.

    .EXAMPLE
        Remove-ApplicationSubmission 0ABCDEF12345 1234567890123456789 -NoStatus
        Removes the specified application submission from the developer account,
        but the request happens in the foreground and there is no additional status
        shown to the user until a response is returned from the REST request.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [Parameter(Mandatory)]
        [string] $SubmissionId,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    $telemetryProperties = @{
        [StoreBrokerTelemetryProperty]::AppId = $AppId
        [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
    }
    
    $params = @{
        "UriFragment" = "applications/$AppId/submissions/$SubmissionId"
        "Method" = "Delete"
        "Description" = "Deleting submission: $SubmissionId for App: $AppId"
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Remove-ApplicationSubmission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    $null = Invoke-SBRestMethod @params
}

function New-ApplicationSubmission
{
<#
    .SYNOPSIS
        Creates a submission for an existing application on the developer account.

    .DESCRIPTION
        Creates a submission for an existing application on the developer account.
        This app must already have at least one *published* submission completed via
        the website in order for this function to work.
        You cannot submit a new application submission if there is an existing pending
        application submission for $AppId already.  You can use -Force to work around
        this.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that the new submission is for.

    .PARAMETER Force
        If this switch is specified, any existing pending submission for AppId
        will be removed before continuing with creation of the new submission.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        New-ApplicationSubmission 0ABCDEF12345 -NoStatus

        Creates a new application submission for app 0ABCDEF12345 that is an exact clone of the currently
        published application submission, but the request happens in the foreground
        and there is no additional status shown to the user until a response is returned from the
        REST request.
        If successful, will return back the PSCustomObject representing the newly created
        application submission.

    .EXAMPLE
        New-ApplicationSubmission 0ABCDEF12345 -Force

        First checks for any existing pending submission for the app with ID 0ABCDEF12345.
        If one is found, it will be removed.  After that check has completed, this will create
        a new application submission for app 0ABCDEF12345 that is an exact clone of the currently
        published application submission, with the console window showing progress while awaiting
        for the response from the REST request.
        If successful, will return back the PSCustomObject representing the newly created
        application submission.

    .OUTPUTS
        PSCustomObject representing the newly created application submission.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [switch] $Force,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    if ([System.String]::IsNullOrEmpty($AccessToken))
    {
        $AccessToken = Get-AccessToken -NoStatus:$NoStatus
    }

    try
    {
        # The Force switch tells us that we need to remove any pending submission
        if ($Force)
        {
            Write-Log "Force creation requested.  Ensuring that there is no existing pending submission." -Level Verbose

            $application = Get-Application -AppId $AppId -AccessToken $AccessToken -NoStatus:$NoStatus
            $pendingSubmissionId = $application.pendingApplicationSubmission.id

            if ($null -ne $pendingSubmissionId)
            {
                Remove-ApplicationSubmission -AppId $AppId -SubmissionId $pendingSubmissionId -AccessToken $AccessToken -NoStatus:$NoStatus
            }
        }

        # Finally, we can POST with a null body to create a clone of the currently published submission
        $telemetryProperties = @{ [StoreBrokerTelemetryProperty]::AppId = $AppId }

        $params = @{
            "UriFragment" = "applications/$AppId/submissions"
            "Method" = "Post"
            "Description" = "Cloning current submission for App: $AppId"
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "New-ApplicationSubmission"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        return (Invoke-SBRestMethod @params)
    }
    catch
    {
        throw
    }
}

function Update-ApplicationSubmission
{
<#
    .SYNOPSIS
        Creates a new submission for an existing application on the developer account
        by cloning the existing submission and modifying specific parts of it.

    .DESCRIPTION
        Creates a new submission for an existing application on the developer account
        by cloning the existing submission and modifying specific parts of it. The
        parts that will be modified depend solely on the switches that are passed in.

        This app must already have at least one *published* submission completed via
        the website in order for this function to work.
        You cannot submit a new application submission if there is an existing pending
        application submission for $AppId already.  You can use -Force to work around
        this.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that the new submission is for.

    .PARAMETER SubmissionDataPath
        The file containing the JSON payload for the application submission.

    .PARAMETER PackagePath
        If provided, this package will be uploaded after the submission has been successfully
        created.

    .PARAMETER TargetPublishMode
        Indicates how the submission will be published once it has passed certification.
        The value specified here takes precendence over the value from SubmissionDataPath if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER TargetPublishDate
        Indicates when the submission will be published once it has passed certification.
        Specifying a value here is only valid when TargetPublishMode is set to 'SpecificDate'.
        The value specified here takes precendence over the value from SubmissionDataPath if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER Visibility
        Indicates the store visibility of the app once the submission has been published.
        The value specified here takes precendence over the value from SubmissionDataPath if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER AutoCommit
        If this switch is specified, will automatically commit the submission
        (which starts the certification process) once the Package has been uploaded
        (if PackagePath was specified), or immediately after the submission has been modified.

    .PARAMETER SubmissionId
        If a submissionId is provided, instead of trying to clone the currently published
        submission and operating against that clone, this will operate against an already
        existing pending submission (that was likely cloned previously).

    .PARAMETER Force
        If this switch is specified, any existing pending submission for AppId
        will be removed before continuing with creation of the new submission.

    .PARAMETER AddPackages
        Causes the packages that are listed in SubmissionDataPath to be added to the package listing
        in the final, patched submission.  This switch is mutually exclusive with ReplacePackages.

    .PARAMETER ReplacePackages
        Causes any existing packages in the cloned submission to be removed and only the packages
        that are listed in SubmissionDataPath will be in the final, patched submission.
        This switch is mutually exclusive with AddPackages.

    .PARAMETER UpdateListings
        Replaces the listings array in the final, patched submission with the listings array
        from SubmissionDataPath.  Ensures that the images originally part of each listing in the
        cloned submission are marked as "PendingDelete" in the final, patched submission.

    .PARAMETER UpdatePublishModeAndVisibility
        Updates fields under the "Publish Mode and Visibility" category in the PackageTool config file.
        Updates the following fields using values from SubmissionDataPath: targetPublishMode,
        targetPublishDate, and visibility.

    .PARAMETER UpdatePricingAndAvailability
        Updates fields under the "Pricing and Availability" category in the PackageTool config file.
        Updates the following fields using values from SubmissionDataPath:  pricing,
        allowTargetFutureDeviceFamilies, allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies,
        and enterpriseLicensing.

    .PARAMETER UpdateAppProperties
        Updates fields under the "App Properties" category in the PackageTool config file.
        Updates the following fields using values from SubmissionDataPath: applicationCategory,
        hardwarePreferences, hasExternalInAppProducts, meetAccessibilityGuidelines,
        canInstallOnRemovableMedia, automaticBackupEnabled, and isGameDvrEnabled.

    .PARAMETER UpdateNotesForCertification
        Updates the notesForCertification field using the value from SubmissionDataPath.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Update-ApplicationSubmission 0ABCDEF12345 "c:\foo.json"
        Creates a new application submission for app 0ABCDEF12345 that is a clone of the currently
        published submission.  Even though "c:\foo.json" was provided, because no switches
        were specified to indicate what to copy from it, the cloned submission was not further
        modified, and is thus still an exact copy of the currently published submission.
        If successful, will return back the pending submission id and url that should be
        used with Upload-SubmissionPackage.

    .EXAMPLE
        Update-ApplicationSubmission 0ABCDEF12345 "c:\foo.json" -AddPackages -NoStatus
        Creates a new application submission for app 0ABCDEF12345 that is a clone of the currently
        published submission.  The packages listed in "c:\foo.json" will be added to the list
        of packages that should be used by the submission.  The request happens in the foreground
        and there is no additional status shown to the user until a response is returned from the
        REST request.  If successful, will return back the pending submission id and url that
        should be used with Upload-SubmissionPackage.

    .EXAMPLE
        Update-ApplicationSubmission 0ABCDEF12345 "c:\foo.json" -Force -UpdateListings -UpdatePricingAndAvailability
        First checks for any existing pending submission for the app with ID 0ABCDEF12345.
        If one is found, it will be removed.  After that check has completed, this will create
        a new application submission for app 0ABCDEF12345 that is a clone of the currently published
        submission.  The "Pricing and Availability" fields of that cloned submission will be modified to
        reflect the values that are in "c:\foo.json".
        If successful, will return back the pending submission id and url that should be
        used with Upload-SubmissionPackage.

    .EXAMPLE
        Update-ApplicationSubmission 0ABCDEF12345 "c:\foo.json" "c:\foo.zip" -AutoCommit -SubmissionId 1234567890123456789 -AddPackages
        Retrieves submission 1234567890123456789 from app 0ABCDEF12345, updates the package listing
        to include the packages that are contained in "c:\foo.json."  If successful, this then
        attempts to upload "c:\foo.zip" as the package content for the submission.  If that
        is also successful, it then goes ahead and commits the submission so that the certification
        process can start. The pending submission id and url that were used with with
        Upload-SubmissionPackage are still returned in this scenario, even though the
        upload url can no longer actively be used.

    .OUTPUTS
        An array of the following two objects:
            System.String - The id for the new pending submission
            System.String - The URL that the package needs to be uploaded to.
#>
    [CmdletBinding(
        SupportsShouldProcess,
        DefaultParametersetName="AddPackages")]
    [OutputType([Object[]])]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [Parameter(Mandatory)]
        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $SubmissionDataPath,

        [ValidateScript({if (Test-Path -Path $_ -PathType Leaf) { $true } else { throw "$_ cannot be found." }})]
        [string] $PackagePath = $null,

        [switch] $AutoCommit,
        
        [string] $SubmissionId = "",

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [ValidateSet('Default', 'Public', 'Private', 'Hidden')]
        [string] $Visibility = $script:keywordDefault,

        [ValidateScript({if ([System.String]::IsNullOrEmpty($SubmissionId) -or !$_) { $true } else { throw "Can't use -Force and supply a SubmissionId." }})]
        [switch] $Force,

        [Parameter(ParameterSetName="AddPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [switch] $UpdateListings,

        [switch] $UpdatePublishModeAndVisibility,

        [switch] $UpdatePricingAndAvailability,

        [switch] $UpdateAppProperties,

        [switch] $UpdateNotesForCertification,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose

    Write-Log "Reading in the submission content from: $SubmissionDataPath" -Level Verbose
    if ($PSCmdlet.ShouldProcess($SubmissionDataPath, "Get-Content"))
    {
        $submission = [string](Get-Content $SubmissionDataPath -Encoding UTF8) | ConvertFrom-Json
    }

    # Extra layer of validation to protect users from trying to submit a payload to the wrong application
    if ([String]::IsNullOrWhiteSpace($submission.appId))
    {
        $output = @()
        $output += "The config file used to generate this submission did not have an AppId defined in it."
        $output += "The AppId entry in the config helps ensure that payloads are not submitted to the wrong application."
        $output += "Please update your app's StoreBroker config file by adding an ""appId"" property with"
        $output += "your app's AppId to the ""appSubmission"" section.  If you're unclear on what change"
        $output += "needs to be done, you can re-generate your config file using"
        $output += "   ""New-StoreBrokerConfigFile -AppId $AppId"" -Path ""`$home\desktop\newconfig.json"""
        $output += "and then diff the new config file against your current one to see the requested appId change."
        Write-Log $($output -join [Environment]::NewLine) -Level Warning
    }
    else
    {
        if ($AppId -ne $submission.appId)
        {
            $output = @()
            $output += "The AppId [$($submission.appId)] in the submission content [$SubmissionDataPath] does not match the intended AppId [$AppId]."
            $output += "You either entered the wrong AppId at the commandline, or you're referencing the wrong submission content to upload."
            Write-Log $($output -join [Environment]::NewLine) -Level Error
            throw $($output -join [Environment]::NewLine)
        }
    }

    # Now, we'll remove the appId property since it's not really valid in submission content.
    # We can safely call this method without validating that the property actually exists.
    $submission.PSObject.Properties.Remove('appId')

    # Identify potentially incorrect usage of this method by checking to see if no modification
    # switch was provided by the user
    if ((-not $AddPackages) -and
        (-not $ReplacePackages) -and
        (-not $UpdateListings) -and
        (-not $UpdatePublishModeAndVisibility) -and
        (-not $UpdatePricingAndAvailability) -and
        (-not $UpdateAppProperties) -and
        (-not $UpdateNotesForCertification))
    {
        $output = @()
        $output += "You have not specified any `"modification`" switch for updating the submission."
        $output += "This means that the new submission will be identical to the current one."
        $output += "If this was not your intention, please read-up on the documentation for this command:"
        $output += "     Get-Help Update-ApplicationSubmission -ShowWindow"
        Write-Log $($output -join [Environment]::NewLine) -Level Warning
    }

    if ([System.String]::IsNullOrEmpty($AccessToken))
    {
        $AccessToken = Get-AccessToken -NoStatus:$NoStatus
    }

    try
    {
        if ([System.String]::IsNullOrEmpty($SubmissionId))
        {
            $submissionToUpdate = New-ApplicationSubmission -AppId $AppId -Force:$Force -AccessToken $AccessToken -NoStatus:$NoStatus
        }
        else
        {
            $submissionToUpdate = Get-ApplicationSubmission -AppId $AppId -SubmissionId $SubmissionId -AccessToken $AccessToken -NoStatus:$NoStatus
            if ($submissionToUpdate.status -ne $script:keywordPendingCommit)
            {
                $output = @()
                $output += "We can only modify a submission that is in the '$script:keywordPendingCommit' state."
                $output += "The submission that you requested to modify ($SubmissionId) is in '$(submissionToUpdate.status)' state."
                Write-Log $($output -join [Environment]::NewLine) -Level Error
                throw "Halt Execution"
            }
        }

        if ($PSCmdlet.ShouldProcess("Patch-ApplicationSubmission"))
        {
            $params = @{}
            $params.Add("ClonedSubmission", $submissionToUpdate)
            $params.Add("NewSubmission", $submission)
            $params.Add("TargetPublishMode", $TargetPublishMode)
            if ($null -ne $TargetPublishDate) { $params.Add("TargetPublishDate", $TargetPublishDate) }
            $params.Add("Visibility", $Visibility)
            $params.Add("UpdateListings", $UpdateListings)
            $params.Add("UpdatePublishModeAndVisibility", $UpdatePublishModeAndVisibility)
            $params.Add("UpdatePricingAndAvailability", $UpdatePricingAndAvailability)
            $params.Add("UpdateAppProperties", $UpdateAppProperties)
            $params.Add("UpdateNotesForCertification", $UpdateNotesForCertification)

            # Because these are mutually exclusive and tagged as such, we have to be sure to *only*
            # add them to the parameter set if they're true.
            if ($AddPackages) { $params.Add("AddPackages", $AddPackages) }
            if ($ReplacePackages) { $params.Add("ReplacePackages", $ReplacePackages) }

            $patchedSubmission = Patch-ApplicationSubmission @params
        }

        if ($PSCmdlet.ShouldProcess("Set-ApplicationSubmission"))
        {
            $params = @{}
            $params.Add("AppId", $AppId)
            $params.Add("UpdatedSubmission", $patchedSubmission)
            $params.Add("AccessToken", $AccessToken)
            $params.Add("NoStatus", $NoStatus)
            $replacedSubmission = Set-ApplicationSubmission @params
        }

        $submissionId = $replacedSubmission.id
        $uploadUrl = $replacedSubmission.fileUploadUrl

        $output = @()
        $output += "Successfully cloned the existing submission and modified its content."
        $output += "You can view it on the Dev portal here:"
        $output += "    https://dev.windows.com/en-us/dashboard/apps/$AppId/submissions/$submissionId/"
        $output += "or by running this command:"
        $output += "    Get-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId | Format-ApplicationSubmission"
        Write-Log $($output -join [Environment]::NewLine)

        if (![System.String]::IsNullOrEmpty($PackagePath))
        {
            Write-Log "Uploading the package [$PackagePath] since it was provided." -Level Verbose
            Set-SubmissionPackage -PackagePath $PackagePath -UploadUrl $uploadUrl -NoStatus:$NoStatus
        }
        elseif (!$AutoCommit)
        {
            $output = @()
            $output += "Your next step is to upload the package using:"
            $output += "  Upload-SubmissionPackage -PackagePath <package> -UploadUrl `"$uploadUrl`""
            Write-Log $($output -join [Environment]::NewLine)
        }

        if ($AutoCommit)
        {
            if ($stopwatch.Elapsed.TotalSeconds -gt $script:accessTokenTimeoutSeconds)
            {
                # The package upload probably took a long time.
                # There's a high likelihood that the token will be considered expired when we call
                # into Complete-ApplicationSubmission ... so, we'll send in a $null value and
                # let it acquire a new one.
                $AccessToken = $null
            }

            Write-Log "Commiting the submission since -AutoCommit was requested." -Level Verbose
            Complete-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId -AccessToken $AccessToken -NoStatus:$NoStatus
        }
        else
        {
            $output = @()
            $output += "When you're ready to commit, run this command:"
            $output += "  Commit-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId"
            Write-Log $($output -join [Environment]::NewLine)
        }

        # Record the telemetry for this event.
        $stopwatch.Stop()
        $telemetryMetrics = @{ [StoreBrokerTelemetryMetric]::Duration = $stopwatch.Elapsed.TotalSeconds }
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
            [StoreBrokerTelemetryProperty]::PackagePath = (Get-PiiSafeString -PlainText $PackagePath)
            [StoreBrokerTelemetryProperty]::AutoCommit = $AutoCommit
            [StoreBrokerTelemetryProperty]::Force = $Force
            [StoreBrokerTelemetryProperty]::AddPackages = $AddPackages
            [StoreBrokerTelemetryProperty]::UpdateListings = $UpdateListings
            [StoreBrokerTelemetryProperty]::UpdatePublishModeAndVisibility = $UpdatePublishModeAndVisibility
            [StoreBrokerTelemetryProperty]::UpdatePricingAndAvailability = $UpdatePricingAndAvailability
            [StoreBrokerTelemetryProperty]::UpdateAppProperties = $UpdateAppProperties
            [StoreBrokerTelemetryProperty]::UpdateNotesForCertification = $UpdateNotesForCertification
        }

        Set-TelemetryEvent -EventName Update-ApplicationSubmission -Properties $telemetryProperties -Metrics $telemetryMetrics

        return $submissionId, $uploadUrl
    }
    catch
    {
        Write-Log $_ -Level Error 
        throw "Halt Execution"
    }
}

function Patch-ApplicationSubmission
{
<#
    .SYNOPSIS
        Modifies a cloned application submission by copying the specified data from the
        provided "new" submission.  Returns the final, patched submission JSON.

    .DESCRIPTION
        Modifies a cloned application submission by copying the specified data from the
        provided "new" submission.  Returns the final, patched submission JSON.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER ClonedSubmisson
        The JSON that was returned by the Store API when the application submission was cloned.

    .PARAMETER NewSubmission
        The JSON for the new/updated application submission.  The only parts from this submission
        that will be copied to the final, patched submission will be those specified by the
        switches.

    .PARAMETER TargetPublishMode
        Indicates how the submission will be published once it has passed certification.
        The value specified here takes precendence over the value from NewSubmission if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER TargetPublishDate
        Indicates when the submission will be published once it has passed certification.
        Specifying a value here is only valid when TargetPublishMode is set to 'SpecificDate'.
        The value specified here takes precendence over the value from NewSubmission if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER Visibility
        Indicates the store visibility of the app once the submission has been published.
        The value specified here takes precendence over the value from NewSubmission if
        -UpdatePublishModeAndVisibility is specified.  If -UpdatePublishModeAndVisibility
        is not specified and the value 'Default' is used, this submission will simply use the
        value from the previous submission.

    .PARAMETER AddPackages
        Causes the packages that are listed in SubmissionDataPath to be added to the package listing
        in the final, patched submission.  This switch is mutually exclusive with ReplacePackages.

    .PARAMETER ReplacePackages
        Causes any existing packages in the cloned submission to be removed and only the packages
        that are listed in SubmissionDataPath will be in the final, patched submission.
        This switch is mutually exclusive with AddPackages.

    .PARAMETER UpdateListings
        Replaces the listings array in the final, patched submission with the listings array
        from NewSubmission.  Ensures that the images originally part of each listing in the
        ClonedSubmission are marked as "PendingDelete" in the final, patched submission.

    .PARAMETER UpdatePublishModeAndVisibility
        Updates fields under the "Publish Mode and Visibility" category in the PackageTool config file.
        Updates the following fields using values from SubmissionDataPath: targetPublishMode,
        targetPublishDate, and visibility.

    .PARAMETER UpdatePricingAndAvailability
        Updates fields under the "Pricing and Availability" category in the PackageTool config file.
        Updates the following fields using values from SubmissionDataPath: targetPublishMode,
        targetPublishDate, visibility, pricing, allowTargetFutureDeviceFamilies,
        allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies, and enterpriseLicensing.

    .PARAMETER UpdateAppProperties
        Updates fields under the "App Properties" category in the PackageTool config file.
        Updates the following fields using values from SubmissionDataPath: applicationCategory,
        hardwarePreferences, hasExternalInAppProducts, meetAccessibilityGuidelines,
        canInstallOnRemovableMedia, automaticBackupEnabled, and isGameDvrEnabled.

    .PARAMETER UpdateNotesForCertification
        Updates the notesForCertification field using the value from SubmissionDataPath.

    .EXAMPLE
        $patchedSubmission = Prepare-ApplicationSubmission $clonedSubmission $jsonContent
        Because no switches were specified, ($patchedSubmission -eq $clonedSubmission).

    .EXAMPLE
        $patchedSubmission = Prepare-ApplicationSubmission $clonedSubmission $jsonContent -AddPackages
        $patchedSubmission will be identical to $clonedSubmission, however all of the packages that
        were contained in $jsonContent will have also been added to the package array.

    .EXAMPLE
        $patchedSubmission = Prepare-ApplicationSubmission $clonedSubmission $jsonContent -AddPackages -UpdateListings
        $patchedSubmission will be contain the listings and packages that were part of $jsonContent,
        but the rest of the submission content will be identical to what had been in $clonedSubmission.
        Additionally, any images that were part of listings from $clonedSubmission will still be
        listed in $patchedSubmission, but their file status will have been changed to "PendingDelete".

    .NOTES
        This is an internal-only helper method.
#>

    [CmdletBinding(DefaultParametersetName="AddPackages")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseApprovedVerbs", "", Justification="Internal-only helper method.  Best description for purpose.")]
    param(
        [Parameter(Mandatory)]
        [PSCustomObject] $ClonedSubmission,
        
        [Parameter(Mandatory)]
        [PSCustomObject] $NewSubmission,

        [ValidateSet('Default', 'Immediate', 'Manual', 'SpecificDate')]
        [string] $TargetPublishMode = $script:keywordDefault,

        [DateTime] $TargetPublishDate,

        [ValidateSet('Default', 'Public', 'Private', 'Hidden')]
        [string] $Visibility = $script:keywordDefault,

        [Parameter(ParameterSetName="AppPackages")]
        [switch] $AddPackages,

        [Parameter(ParameterSetName="ReplacePackages")]
        [switch] $ReplacePackages,

        [switch] $UpdateListings,

        [switch] $UpdatePublishModeAndVisibility,

        [switch] $UpdatePricingAndAvailability,

        [switch] $UpdateAppProperties,

        [switch] $UpdateNotesForCertification
    )
    
    Write-Log "Patching the content of the submission." -Level Verbose 

    # Our method should have zero side-effects -- we don't want to modify any parameter
    # that was passed-in to us.  To that end, we'll create a deep copy of the ClonedSubmisison,
    # and we'll modify that throughout this function and that will be the value that we return
    # at the end.
    $PatchedSubmission = DeepCopy-Object $ClonedSubmission

    # When updating packages, we'll simply add the new packages to the list of existing packages.
    # At some point when the API provides more signals to us with regard to what platform/OS
    # an existing package is for, we may want to mark "older" packages for the same platform
    # as "PendingDelete" so as to not overly clutter the dev account with old packages.  For now,
    # we'll leave any package maintenance to uses of the web portal.
    if ($AddPackages)
    {
        $PatchedSubmission.applicationPackages += $NewSubmission.applicationPackages
    }

    # Caller wants to remove any existing packages in the cloned submission and only have the
    # packages that are defined in the new submission.
    if ($ReplacePackages)
    {
        $PatchedSubmission.applicationPackages | ForEach-Object { $_.fileStatus = $script:keywordPendingDelete }
        $PatchedSubmission.applicationPackages += $NewSubmission.applicationPackages
    }

    # When updating the listings metadata, what we really want to do is just blindly replace
    # the existing listings array with the new one.  We can't do that unfortunately though,
    # as we need to mark the existing screenshots as "PendingDelete" so that they'll be deleted
    # during the upload.  Otherwise, even though we don't include them in the updated JSON, they
    # will still remain there in the dev portal.
    if ($UpdateListings)
    {
        # Save off the original listings so that we can make changes to them without affecting
        # other references
        $existingListings = DeepCopy-Object $PatchedSubmission.listings

        # Then we'll replace the patched submission's listings array (which had the old,
        # cloned metadata), with the metadata from the new submission.
        $PatchedSubmission.listings = DeepCopy-Object $NewSubmission.listings

        # Now we'll update the screenshots in the existing listings
        # to indicate that they should all be deleted. We'll also add 
        # all of these deleted images to the corresponding listing
        # in the patched submission.
        #
        # Unless the Store team indicates otherwise, we assume that the server will handle
        # deleting the images in regions that were part of the cloned submission, but aren't part
        # of the patched submission that we provide. Otherwise, we'd have to create empty listing
        # objects that would likely fail validation.
        $existingListings |
            Get-Member -type NoteProperty |
                ForEach-Object {
                    $lang = $_.Name
                    if ($null -ne $PatchedSubmission.listings.$lang.baseListing.images)
                    {
                        $existingListings.$lang.baseListing.images |
                            ForEach-Object {
                                $_.FileStatus = $script:keywordPendingDelete
                                $PatchedSubmission.listings.$lang.baseListing.images += $_
                            }
                    }
                }

        # We also have to be sure to carry forward any "platform overrides" that the cloned
        # submission had.  These platform overrides have listing information for previous OS
        # releases like Windows 8.0/8.1 and Windows Phone 8.0/8.1.
        #
        # This has slightly different logic from the normal listings as we don't expect users
        # to use StoreBroker to modify these values.  We will copy any platform override that
        # exists from the cloned submission to the patched submission, provided that the patched
        # submission has that language.  If a platform override entry already exists for a specific
        # platform in the patched submission, we will just carry forward the previous images for
        # that platformOverride and mark them as PendingDelete, just like we do for normal listings.
        $existingListings |
            Get-Member -type NoteProperty |
                ForEach-Object {
                    $lang = $_.Name

                    # We're only bringing over platformOverrides for languages that we still have
                    # in the patched submission.
                    if ($null -ne $PatchedSubmission.listings.$lang.baseListing)
                    {
                        $existingListings.$lang.platformOverrides |
                            Get-Member -type NoteProperty |
                                ForEach-Object {
                                    $platform = $_.Name

                                    if ($null -eq $PatchedSubmission.listings.$lang.platformOverrides.$platform)
                                    {
                                        # If the override doesn't exist in the patched submission, just
                                        # bring the whole thing over.
                                        $PatchedSubmission.listings.$lang.platformOverrides |
                                            Add-Member -Type NoteProperty -Name $platform -Value $($existingListings.$lang.platformOverrides.$platform)
                                    }
                                    else
                                    {
                                        # The PatchedSubmission has an entry for this platform.
                                        # We'll only copy over the images from the cloned submission
                                        # and mark them all as PendingDelete.
                                        $existingListings.$lang.platformOverrides.$platform.images |
                                            ForEach-Object {
                                                $_.FileStatus = $script:keywordPendingDelete
                                                $PatchedSubmission.listings.$lang.platformOverrides.$platform.images += $_
                                            }
                                    }
                                }
                    }
                }

    }

    # For the last four switches, simply copy the field if it is a scalar, or
    # DeepCopy-Object if it is an object.

    if ($UpdatePublishModeAndVisibility)
    {
        $PatchedSubmission.targetPublishMode = Get-ProperEnumCasing -EnumValue ($NewSubmission.targetPublishMode)
        $PatchedSubmission.targetPublishDate = $NewSubmission.targetPublishDate
        $PatchedSubmission.visibility = Get-ProperEnumCasing -EnumValue ($NewSubmission.visibility)
    }
    
    # If users pass in a different value for any of the publish/visibility values at the commandline,
    # they override those coming from the config.
    if ($TargetPublishMode -ne $script:keywordDefault)
    {
        if (($TargetPublishMode -eq $script:keywordSpecificDate) -and ($null -eq $TargetPublishDate))
        {
            $output = "TargetPublishMode was set to '$script:keywordSpecificDate' but TargetPublishDate was not specified."
            Write-Log $output -Level Error 
            throw $output
        }

        $PatchedSubmission.targetPublishMode = Get-ProperEnumCasing -EnumValue $TargetPublishMode
    }

    if ($null -ne $TargetPublishDate)
    {
        if ($TargetPublishMode -ne $script:keywordSpecificDate)
        {
            $output = "A TargetPublishDate was specified, but the TargetPublishMode was [$TargetPublishMode],  not '$script:keywordSpecificDate'."
            Write-Log $output -Level Error 
            throw $output
        }

        $PatchedSubmission.targetPublishDate = $TargetPublishDate.ToString('o')
    }

    if ($Visibility -ne $script:keywordDefault)
    {
        $PatchedSubmission.visibility = Get-ProperEnumCasing -EnumValue $Visibility
    }

    if ($UpdatePricingAndAvailability)
    {
        $PatchedSubmission.pricing = DeepCopy-Object $NewSubmission.pricing
        $PatchedSubmission.allowTargetFutureDeviceFamilies = DeepCopy-Object $NewSubmission.allowTargetFutureDeviceFamilies
        $PatchedSubmission.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies = $NewSubmission.allowMicrosoftDecideAppAvailabilityToFutureDeviceFamilies
        $PatchedSubmission.enterpriseLicensing = $NewSubmission.enterpriseLicensing
    }

    if ($UpdateAppProperties)
    {
        $PatchedSubmission.applicationCategory = $NewSubmission.applicationCategory
        $PatchedSubmission.hardwarePreferences = $NewSubmission.hardwarePreferences
        $PatchedSubmission.hasExternalInAppProducts = $NewSubmission.hasExternalInAppProducts
        $PatchedSubmission.meetAccessibilityGuidelines = $NewSubmission.meetAccessibilityGuidelines
        $PatchedSubmission.canInstallOnRemovableMedia = $NewSubmission.canInstallOnRemovableMedia
        $PatchedSubmission.automaticBackupEnabled = $NewSubmission.automaticBackupEnabled
        $PatchedSubmission.isGameDvrEnabled = $NewSubmission.isGameDvrEnabled
    }

    if ($UpdateNotesForCertification)
    {
        $PatchedSubmission.notesForCertification = $NewSubmission.notesForCertification
    }

    # To better assist with debugging, we'll store exactly the original and modified JSON submission bodies.
    $tempFile = [System.IO.Path]::GetTempFileName() # New-TemporaryFile requires PS 5.0
    ($ClonedSubmission | ConvertTo-Json -Depth $script:jsonConversionDepth) | Set-Content -Path $tempFile -Encoding UTF8
    Write-Log "The original cloned JSON content can be found here: [$tempFile]" -Level Verbose 

    $tempFile = [System.IO.Path]::GetTempFileName() # New-TemporaryFile requires PS 5.0
    ($PatchedSubmission | ConvertTo-Json -Depth $script:jsonConversionDepth) | Set-Content -Path $tempFile -Encoding UTF8
    Write-Log "The patched JSON content can be found here: [$tempFile]" -Level Verbose 

    return $PatchedSubmission
}

function Set-ApplicationSubmission
{
<#
    .SYNOPSIS
        Replaces the content of an existing application submission with the supplied
        submission content.

    .DESCRIPTION
        Replaces the content of an existing application submission with the supplied
        submission content.

        This should be called after having cloned an application submission via
        New-ApplicationSubmission.

        The ID of the submission being updated/replaced will be inferred by the
        submissionId defined in UpdatedSubmission.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that the submission is for.

    .PARAMETER UpdatedSubmission
        The updated application submission content that should be used to replace the
        existing submission content.  The Submission ID will be determined from this.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER FlightId
        This optional parameter, if provided, will tream the submission being replaced as
        a flight submission as opposed to the regular app published submission.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Set-ApplicationSubmission 0ABCDEF12345 $submissionBody

        Inspects $submissionBody to retrieve the id of the submission in question, and then replaces
        the entire content of that existing submission with the content specified in $submissionBody.

    .EXAMPLE
        Set-ApplicationSubmission 0ABCDEF12345 $submissionBody -NoStatus

        Inspects $submissionBody to retrieve the id of the submission in question, and then replaces
        the entire content of that existing submission with the content specified in $submissionBody.
        The request happens in the foreground and there is no additional status shown to the user
        until a response is returned from the REST request.

    .OUTPUTS
        A PSCustomObject containing the JSON of the updated application submission.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Replace-ApplicationSubmission')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [Parameter(Mandatory)]
        [PSCustomObject] $UpdatedSubmission,

        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose 

    $submissionId = $UpdatedSubmission.id
    $body = [string]($UpdatedSubmission | ConvertTo-Json -Depth $script:jsonConversionDepth)
    $telemetryProperties = @{ [StoreBrokerTelemetryProperty]::AppId = $AppId }

    $params = @{
        "UriFragment" = "applications/$AppId/submissions/$submissionId"
        "Method" = "Put"
        "Description" = "Replacing the content of Submission: $submissionId for App: $AppId"
        "Body" = $body
        "AccessToken" = $AccessToken
        "TelemetryEventName" = "Set-ApplicationSubmission"
        "TelemetryProperties" = $telemetryProperties
        "NoStatus" = $NoStatus
    }

    return (Invoke-SBRestMethod @params )
}

function Complete-ApplicationSubmission
{
<#
    .SYNOPSIS
        Commits the specified application submission so that it can start the approval process.

    .DESCRIPTION
        Commits the specified application submission so that it can start the approval process.
        Once committed, it is necessary to wait for the submission to either complete or fail
        the approval process before a new application submission can be created/submitted.

        The Git repo for this module can be found here: http://aka.ms/StoreBroker

    .PARAMETER AppId
        The Application ID for the application that has the pending submission to be submitted.

    .PARAMETER SubmissionId
        The ID of the pending submission that should be submitted.

    .PARAMETER AccessToken
        If provided, this will be used as the AccessToken for authentication with the
        REST Api as opposed to requesting a new one.

    .PARAMETER NoStatus
        If this switch is specified, long-running commands will run on the main thread
        with no commandline status update.  When not specified, those commands run in
        the background, enabling the command prompt to provide status information.

    .EXAMPLE
        Commit-ApplicationSubmission 0ABCDEF12345 1234567890123456789
        Marks the pending submission 1234567890123456789 to start the approval process
        for publication, with the console window showing progress while awaiting
        for the response from the REST request.

    .EXAMPLE
        Commit-ApplicationSubmission 0ABCDEF12345 1234567890123456789 -NoStatus
        Marks the pending submission 1234567890123456789 to start the approval process
        for publication, but the request happens in the foreground and there is no
        additional status shown to the user until a response is returned from the REST
        request.

    .NOTES
        This uses the "Complete" verb to avoid Powershell import module warnings, but this
        actually only *commits* the submission.  The decision to publish or not is based
        entirely on the contents of the payload included when calling New-ApplicationSubmission.
#>
    [CmdletBinding(SupportsShouldProcess)]
    [Alias('Commit-ApplicationSubmission')]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSShouldProcess", "", Justification="Methods called within here make use of PSShouldProcess, and the switch is passed on to them inherently.")]
    param(
        [Parameter(Mandatory)]
        [string] $AppId,
        
        [Parameter(Mandatory)]
        [string] $SubmissionId,
        
        [string] $AccessToken = "",

        [switch] $NoStatus
    )

    Write-Log "Executing: $($MyInvocation.Line)" -Level Verbose 

    try
    {
        $telemetryProperties = @{
            [StoreBrokerTelemetryProperty]::AppId = $AppId
            [StoreBrokerTelemetryProperty]::SubmissionId = $SubmissionId
        }

        $params = @{
            "UriFragment" = "applications/$AppId/submissions/$SubmissionId/Commit"
            "Method" = "Post"
            "Description" = "Committing submission $SubmissionId for App: $AppId"
            "AccessToken" = $AccessToken
            "TelemetryEventName" = "Complete-ApplicationSubmission"
            "TelemetryProperties" = $telemetryProperties
            "NoStatus" = $NoStatus
        }

        $null = Invoke-SBRestMethod @params 

        $output = @()
        $output += "The submission has been successfully committed."
        $output += "This is just the beginning though."
        $output += "It still has multiple phases of validation to get through, and there's no telling how long that might take."
        $output += "You can view the progress of the submission validation on the Dev portal here:"
        $output += "    https://dev.windows.com/en-us/dashboard/apps/$AppId/submissions/$submissionId/"
        $output += "or by running this command:"
        $output += "    Get-ApplicationSubmission -AppId $AppId -SubmissionId $submissionId | Format-ApplicationSubmission"
        $output += "You can automatically monitor this submission with this command:"
        $output += "    Start-ApplicationSubmissionMonitor -AppId $AppId -SubmissionId $submissionId -EmailNotifyTo $env:username"
        $output += ""
        $output += "PLEASE NOTE: Due to the nature of how the Store API works, you won't see any of your changes in the"
        $output += "dev portal until your submission has entered into certification.  It doesn't have to *complete*"
        $output += "certification for you to see your changes, but it does have to enter certification first."
        $output += "If it's important for you to verify your changes in the dev portal prior to publishing,"
        $output += "consider publishing with the `"$script:keywordManual`" targetPublishMode by setting that value in your"
        $output += "config file and then additionally specifying the -UpdatePublishModeAndVisibility switch"
        $output += "when calling Update-ApplicationSubmission, or by specifying the"
        $output += "-TargetPublishMode $script:keywordManual parameter when calling Update-ApplicationSubmission."
        Write-Log $($output -join [Environment]::NewLine) 
    }
    catch [System.InvalidOperationException]
    {
        throw
    }
}