function GetActivityNameFromReferenceId {
    param (
        [string]$apiKey,
        [string]$referenceId
    )

    $url = "https://www.bungie.net/Platform/Destiny2/Manifest/DestinyActivityDefinition/$referenceId/"
    $headers = @{ "X-API-Key" = $apiKey }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    if ($response.ErrorCode -eq 1) {
        $activityName = $response.Response.originalDisplayProperties.name
        return $activityName
    } else {
        Write-Host "Fehler beim Abrufen des Activity-Namens. ErrorCode: $($response.ErrorCode)"
        return "N/A"
    }
}

function GetPlayerNameFromMembershipID {
    param (
        [string]$apiKey,
        [string]$membershipId
    )

    $url = "https://www.bungie.net/Platform/User/GetMembershipsById/$membershipId/-1/"
    $headers = @{ "X-API-Key" = $apiKey }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    if ($response.ErrorCode -eq 1) {
        $uniqueName = $response.Response.bungieNetUser.uniqueName
        return $uniqueName
    } else {
        Write-Host "Error. ErrorCode: $($response.ErrorCode)"
        return "N/A"
    }
}

function GetPostGameCarnageReport {
    param (
        [string]$apiKey,
        [string]$activityId
    )

    $url = "https://stats.bungie.net/Platform/Destiny2/Stats/PostGameCarnageReport/$activityId/"
    $headers = @{ "X-API-Key" = $apiKey }

    $response = Invoke-RestMethod -Uri $url -Headers $headers -Method Get

    if ($response.ErrorCode -eq 1) {
        $playerStats = $response.Response.entries | Select-Object -Property Player, CharacterId, Values
        $Response = $response.Response
        $activity = $Response.activityDetails.referenceId
        $activityName = GetActivityNameFromReferenceId -apiKey $apiKey -referenceId $activity
        $table = @()
        $playerFound = $false  # Eine Variable, um zu überprüfen, ob ein Spieler gefunden wurde.
        foreach ($player in $playerStats) {
            $completed = $player.Values.completed.basic.displayValue
            if ($completed -eq "Yes") {
                $playerFound = $true  # Einen Spieler gefunden.
                $membershipId = $player.Player.destinyUserInfo.membershipId
                $kills = [int]$player.Values.kills.basic.value
                $deaths = [int]$player.Values.deaths.basic.displayValue
                $duration = $player.Values.activityDurationSeconds.basic.displayValue
                $date = $Response.period

                $row = New-Object PSObject -Property @{
                    "PlayerName" = GetPlayerNameFromMembershipID -apiKey $apiKey -membershipId $membershipId
                    "MembershipID" = "https://b.moons.bio/" + $membershipId
                    "Kills" = $kills 
                    "Deaths" = $deaths 
                    "Completed" = "✅"
                }

                $table += $row
            }
        }

        if (-not $playerFound) {
            $divider = ("_" * 90)

            Write-Host $divider -ForegroundColor Blue
            Write-Host -ForegroundColor Green "The activity was not completed."
            Write-Host $divider -ForegroundColor Blue
        } else {
            $table = $table | Sort-Object -Property @{Expression={[int]$_.Kills}; Descending=$true}

            $divider = ("_" * 90)

            Write-Host $divider -ForegroundColor Blue
            Write-Host -ForegroundColor Green "Activity ID:" $activityID "|" "Timestamp:" $date
            Write-Host -ForegroundColor Green "Activity:" $activityName "|" "Activity Duration:" $duration
            $table | Format-Table -AutoSize @{Label="Player Name"; Expression={$_.PlayerName}}, 
                                            @{Label="URL"; Expression={$_.MembershipID}}, 
                                            @{Label="Kills"; Expression={$_.Kills}}, 
                                            @{Label="Deaths"; Expression={$_.Deaths}}, 
                                            @{Label="Completed"; Expression={$_.Completed}} -Wrap
            Write-Host $divider -ForegroundColor Blue
        }
    } else {
        Write-Host "Fehler beim Abrufen der Daten. ErrorCode: $($response.ErrorCode)"
    }
}


$apiKey = "<INSERT_API_KEY_HERE>"

Write-Host "Insert the Activity ID:"
$activityId = Read-Host

GetPostGameCarnageReport -apiKey $apiKey -activityId $activityId 
Pause