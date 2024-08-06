Set-Location -Path $env:localappdata\Android\Sdk\platform-tools\
.\adb disconnect localhost:5555
# change path
Set-Location -Path $env:C:\Users\artin\firealert\android\
.\gradlew --stop