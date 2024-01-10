#load important files
$modulPath= Join-Path -Path $PSScriptRoot -ChildPath "helpers.psm1"
Import-Module $modulPath -Force
$patternFile = Join-Path -Path $PSScriptRoot -ChildPath "patterns.json"

# proceed data
$allCSVDataClassified = Get-AllCSVDataClassified -FolderPath "FinanzReports" -HeaderLine "Buchungstag,Wertstellung (Valuta),Vorgang,Buchungstext,Umsatz in EUR" -PatternFile $patternFile # use local path with the header of Comdirect CSV Export.
$classifiedObject = Get-ClassifiedObject -TransactionData $allCSVDataClassified 
$classifiedSum = Get-SumPerMonthYearCategory -data $classifiedObject -patternFile $patternFile

# create report
Add-NewDatasetToReport -datasets $classifiedSum -patternFile $patternFile -allCSVDataClassified $allCSVDataClassified
