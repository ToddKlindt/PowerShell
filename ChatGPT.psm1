function Format-ChatGPTConversation {
    <#
    .SYNOPSIS
    Formats ChatGPT conversations from a JSON file.

    .DESCRIPTION
    The Format-ChatGPTConversation function takes a JSON file containing ChatGPT conversations and formats the conversations into a structured output. It extracts relevant information such as conversation title, ID, create time, author, and content. System messages and messages without an author are skipped.

    To get the conversations.json file, go to https://chat.openai.com/. In the lower left corner click the three dots by your name and click Settings. In Settings, click the Data controls tab. There is an "Export" button in there. Clicking that will download a zip file. One of the files in that zip file is conversations.json.

    .PARAMETER filename
    Specifies the path to the JSON file containing the ChatGPT conversations.

    .EXAMPLE
    Format-ChatGPTConversation -filename "conversations.json"
    
    This example formats the ChatGPT conversations from the "conversations.json" file and displays the formatted output in the console.

    .EXAMPLE
    Format-ChatGPTConversation -filename "conversations.json" | Out-File -Filepath "formatted_conversations.txt"
    
    This example formats the ChatGPT conversations from the "conversations.json" file and saves the formatted output to a text file named "formatted_conversations.txt".

    .EXAMPLE
    Get-ChildItem -Path "conversations.json" | Format-ChatGPTConversation
    
    This example retrieves all the JSON files in the current directory with the "*.json" pattern and passes them through the pipeline to Format-ChatGPTConversation. The function formats the ChatGPT conversations from each JSON file and displays the formatted output in the console.

    .EXAMPLE
    Format-ChatGPTConversation -filename conversations.json | Group-Object -Property Title | Select-Object name, count
    
    This example gives you a list of each conversations and how many parts it has.

    .EXAMPLE
    Format-ChatGPTConversation -filename conversations.json | Where-Object { $_.title -eq "PowerShell Function Advice" } | select author, content | Format-List | more.com
    
    This gets only the messages in the "PowerShell Function Advice" conversation and displays them in a list format only given you the author and the content of the message. The more.com command is used to page the output.

    #>
    param (
        [cmdletbinding()]
        [OutputType('TKchatGPT')]   
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true, Position = 0)]
        [ValidateScript({ (Test-Path $_) -and ($_.EndsWith('.json')) })]
        [ArgumentCompleter({ param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameter)
            $path = $fakeBoundParameter[$parameterName]
            $files = Get-ChildItem -Path $path -Filter '*.json' -Name

            if ($files) {
                $files | Where-Object { $_ -like "$wordToComplete*" }
            }
        })]
        [string]$filename
    )

    Begin {
        # No explicit Begin block needed for this function
    }

    Process {
        # Resolve $filename to full path
        $filename = Resolve-Path -Path $filename
        $conversationFile = Get-Content -Raw -Path $filename | ConvertFrom-Json
        Write-Verbose "Found $($conversationFile.Count) ChatGPT Conversations" 

        foreach ($conversation in $conversationFile) {
            $title = $conversation.title
            $id = $conversation.id

            Write-Verbose "Processing Conversation: $title"
            foreach ($mapping in $conversation.mapping.PSObject.Properties) {
                $object = $mapping.Value

                $create_time_unix = $object.message.create_time
                $create_time_epoch = [DateTimeOffset]::FromUnixTimeSeconds($create_time_unix)
                $create_time = $create_time_epoch.LocalDateTime.ToString("MMMM dd, yyyy h:mm:ss tt")

                # Skip system messages or where the author is null
                $author = $object.message.author.role
                if ($author -eq "system" -or [string]::IsNullOrEmpty($author)) {
                    continue
                }

                $content_parts = $object.message.content.parts
                $content = if ($content_parts) { $content_parts[0] } else { $null }

                [PSCustomObject]@{
                    PSTypeName = "TKchatGPT"
                    title = $title
                    id = $id
                    create_time = $create_time
                    author = $author
                    content = $content
                }
            }
        }
    }   

    End {
        # No explicit End block needed for this function
    }
}


