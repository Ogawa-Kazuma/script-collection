# LMStudio API URL and model
$apiUrl = "http://192.168.1.127:1234/v1/chat/completions"
$model = "qwen/qwen3-coder-30b"

# Initialize message history
$messages = @(@{ role = "system"; content = "You are a helpful assistant." })

Write-Host "LMStudio Chat with $model. Type 'exit' to quit.`n"

while ($true) {
    # Get user input
    $userInput = Read-Host "You"
    if ($userInput -eq "exit") { break }

    # Add user message to history
    $messages += @{ role = "user"; content = $userInput }

    # Build request body
    $body = @{
        model = $model
        messages = $messages
        max_tokens = 300
        temperature = 0.7
    } | ConvertTo-Json -Depth 3

    # Send POST request
    $response = curl -Method POST $apiUrl -ContentType "application/json" -Body $body | ConvertFrom-Json

    # Get model reply
    $reply = $response.choices[0].message.content
    Write-Host "`nLMStudio:" $reply "`n"

    # Add model reply to history
    $messages += @{ role = "assistant"; content = $reply }
}
