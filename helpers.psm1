
$monthArray = @('Januar','Februar','März','April','Mai','Juni','Juli','August', 'September', 'Oktober', 'November', 'Dezember')


function Get-AllCSVDataClassified {
    param (
        [string]$folderPath,
        [string]$headerLine,
        [string]$patternFile
    )

    $JsonPattern = Get-Content -Path $patternFile -Encoding utf8 | ConvertFrom-Json

    $folderPath = Join-Path -Path $PSScriptRoot -ChildPath $folderPath

    if (-not (Test-Path $folderPath -PathType Container)) {
        Write-Host "Der Ordner '$folderPath' wurde nicht gefunden."
        return
    }

    $csvFiles = Get-ChildItem -Path $folderPath -Filter *.csv

    $allCSVData = @()

    # Get data of all files in the folder
    foreach ($csvFile in $csvFiles) {
        $csvData = Get-Content -Path $csvFile.FullName -Encoding utf8 | ConvertFrom-Csv -Header ($headerLine -split ',')
        $allCSVData += $csvData
    }

    # Create a data object
    $allCSVDataClassified = @()
    Foreach ($data in $allCSVData ){

        $data |  Add-Member -MemberType NoteProperty -Name "Kategorie" -Value (Get-Class -Text $data.Buchungstext -JsonPattern $JsonPattern )

        $allCSVDataClassified += $data
    }

    # return all data
    return $allCSVDataClassified 
}


# return number of categories in the pattern file
function Get-AvailableCategories{
    param (
        [string]$patternFile
    )
    $jsonPattern = Get-Content -Path $patternFile -Encoding utf8 | ConvertFrom-Json

    $categories = ($jsonPattern.patterns | Get-Member -MemberType NoteProperty) |  Measure-Object

    return $categories.Count
}

# Validate the category of a string
function Get-Class {
    param (
        [string]$Text,
        $jsonPattern
    )

    # get through the pattern file and compare the "Buchungstext" with the pattern key words.
    foreach ($pattern in $jsonPattern.patterns.PSObject.Properties) {
        $category = $pattern.Name
        $keywords = $pattern.Value 

        foreach ($keyword in $keywords.keywords) {
            if ($Text -match $keyword) {
                return $category
            }
        }
    }

    # If no pattern found, return unkown
    return "Unknown"
}

# returns an object with all data and its categories
function Get-ClassifiedObject{ 
    param (
        [array]$TransactionData
    )

    $result = @()
    $datePattern = '^\d{2}\.\d{2}\.\d{4}$'

    # check every transacton and create the sum for every month per year
    foreach ($transaction in $TransactionData) {
        if ($transaction.Buchungstag -match $datePattern) {
            $month = Get-Date $transaction.Buchungstag -Format "MM"
            $year = Get-Date $transaction.Buchungstag -Format "yyyy"
            $category = $transaction.Kategorie
    
            
            $value = [decimal]$transaction.'Umsatz in EUR'
    
            $result += [pscustomobject]@{year=$year;month=$month;category=$category;value=$value}
        }
       
    }

    return $result
}

# Creates the sum per month and year for a category and returns an object with the results
function Get-SumPerMonthYearCategory {
    param (
        [array]$data,
        $patternFile
    )

    $sums = @()

    $jsonPattern = Get-Content -Path $patternFile -Encoding utf8 | ConvertFrom-Json 

    # get data from every object, store it in a new one and create a sum per year, month and category
    foreach ($entry in $data) {
        $year = $entry.year
        $month = $entry.month
        $category = $entry.category
        $value = $entry.value

        
        $existingEntry = $sums | Where-Object { $_.year -eq $year -and $_.month -eq $month -and $_.category -eq $category }

        if ($existingEntry) {
            $existingEntry.value += $value
        }
        else {
            $sums +=  [pscustomobject]@{year=$year;month=$month;category=$category;value=$value}
        }
    }


    # create a new object for the html report
    $result = @()
    foreach ($entry in $sums){
        $year = $entry.year
        $month = $entry.month  
        $category = $entry.category
        $value = $entry.value


        $existingEntry = $result | Where-Object { $_.year -eq $year -and $_.month -eq $month }

        
        if($existingEntry){
            $existingEntry.categories +=[pscustomobject]@{name=$category;value= [Math]::Abs($value)}
        }
        else {
            $result += [pscustomobject]@{year=$year;month=$month;categories=@()}
            $existingFirstEntry = $result | Where-Object { $_.year -eq $year -and $_.month -eq $month }
            $existingFirstEntry.categories += [pscustomobject]@{name=$category;value= [Math]::Abs($value)}
        }

    }

   
    foreach($entry in $result){
        
        # check if all categories are in the array
        
        $missingCategory = @()
        foreach($pattern in $jsonPattern.patterns.PSObject.Properties){
            $findingFlag = $false
            foreach($category in $entry.categories){
                
                
                    if($pattern.Name -eq $category.Name){
                        $findingFlag = $true
                    }
                
            }
            
            if(-NOT $findingFlag){
                $missingCategory += $pattern.Name
            }
        }
        
        if($missingCategory){

            foreach($cat in $missingCategory){
                $result[$result.IndexOf($entry)].categories +=[pscustomobject]@{name=$cat ;value=0}
            }

        }

    }
    

    return $result
}



# create the html data set for every table (monthly)
function Get-HtmlForDataset {
    param(
        $dataset
    )

    $html = @"
  <!-- Header und Tabelle -->
  <div class="container">
    <div class="data-table" data-year="$($dataset.year)" data-month="$($dataset.month)">
        <div class="table-container">
        <h2 class="mt-4 mb-3">$($dataset.year) - $($monthArray[$($($dataset.month)-1)])</h2>
        <table class="table table-bordered">
            <thead class="thead-light">
            <tr>
                <th scope="col">Kategorie</th>
                <th scope="col">Wert</th>
            </tr>
            </thead>
            <tbody>
"@

    foreach ($categorie in $dataset.categories) {
        $html += @"
          <tr>
            <td>$($categorie.name)</td>
            <td>$($categorie.value) €</td>
          </tr>
"@
    }

    $html += @"
                </tbody>
            </table>
            </div>
            <!-- Diagramm -->
            <div class="chart-container">
            <canvas id="chart-$($dataset.year)-$($dataset.month)"></canvas>
            </div>
        </div>
    </div>

    <div class="border-top my-3"></div>
    
"@

    return $html
}


function Get-HtmlForDatasetUnclassified {
    param(
        $allCSVDataClassified
    )

    $html = @"
  <!-- Header und Tabelle -->
  <div class="container">
    <div class="data-table">
        <div class="table-container">
        <h2 class="mt-4 mb-3">Unbekannte Klassen</h2>
        <table class="table table-bordered">
            <thead class="thead-light">
            <tr>
                <th scope="col">Buchungstext</th>
                <th scope="col">Wert</th>
            </tr>
            </thead>
            <tbody>
"@

    foreach ($entry in $allCSVDataClassified) {
        if($entry.Kategorie -eq "Unknown" -and $entry."Umsatz in EUR"){

            $html += @"
            <tr>
                <td>$($entry.Buchungstext)</td>
                <td>$($entry."Umsatz in EUR") €</td>
            </tr>
"@
            

        }
 
    }

    $html += @"
                </tbody>
            </table>
            </div>
        </div>
    </div>

    <div class="border-top my-3"></div>
    
"@

    return $html
}


function Get-JavaChartDataset {
    param(
        $dataset
    )

    $jsonDataset = $dataset | ConvertTo-Json -Depth 3

    $jsCode = @"
    var dataJson = $jsonDataset;
"@

    return $jsCode
    
}

# Get the Java Script code for the pie charts
function Get-JavaScriptForDataset{
    param(
        $dataset,
        $jsonPattern
    )
    
    $tmpCategories = $($dataset.categories | Where-Object { $_.name -ne "Einkommen" } | ForEach-Object { $_.name })


    foreach($cat in $tmpCategories){


        if($cat -ne "Unknown"){
            foreach($pattern in  $jsonPattern.patterns.PSObject.Properties)
            {
                if($pattern.Name -eq $cat){
                    $color = $pattern.Value.color
                }
            }
        }
        else {
            $color = "#ff6384"
       }

        if($categories){
            $categories += ", " + "'$cat'"     
            $colors += ", " + "'$color'"
        }
        else {
            $categories += "'$cat'"
            $colors += "'$color'"
        }
    }

    $tmpValue = $($dataset.categories | Where-Object { $_.name -ne "Einkommen" } | ForEach-Object { $_.value })

    # make sure there is no negative value
    $total = ($tmpValue | ForEach-Object { [Math]::Abs($_) } | Measure-Object -Sum).Sum
    $values = ""
    
    foreach ($val in $tmpValue) {
        $percentage = [math]::Round(([Math]::Abs($val) / $total) * 100, 2)
        if ($values) {
            $values += ", " + "$percentage"
        } else {
            $values += "$percentage"
        }
    }

    


    $jsCode = @"
    var ctx = document.getElementById('chart-$($dataset.year)-$($dataset.month)').getContext('2d');
    var myChart = new Chart(ctx, {
      type: 'pie',
      data: {
        labels: [$categories],
        datasets: [{
          data: [$values],
          backgroundColor: [$colors],
        }]
      },
      options: {
        legend: {
          position: 'bottom',
        },
      }
    });
"@

    return $jsCode
}


function Add-NewDatasetToReport{
param(
    $datasets,
    $allCSVDataClassified ,
    [string]$patternFile
)
# template html
$existingHtml = Get-Content -Path ".\result_template.html" -Raw -Encoding utf8
$jsonPattern = Get-Content -Path $patternFile -Encoding utf8 | ConvertFrom-Json 

# Table
$newHtml = ""
foreach ($dataset in $datasets) {
    $newHtml += Get-HtmlForDataset $dataset
}

$bodyEndIndex = $existingHtml.IndexOf("</body>") - 1

$existingHtml = $existingHtml.Insert($bodyEndIndex, $newHtml)

# Pie Chart

$newJavaScript = ""
foreach ($dataset in $datasets) {
    $newJavaScript += Get-JavaScriptForDataset -dataset $dataset -jsonPattern $jsonPattern 
}

$scriptEndIndex = $existingHtml.IndexOf("//Script End") - 1

$existingHtml = $existingHtml.Insert($scriptEndIndex, $newJavaScript)


# Chart

$newChartData = Get-JavaChartDataset -dataset $datasets

$scriptEndIndex = $existingHtml.IndexOf("// add your data") - 1

$existingHtml = $existingHtml.Insert($scriptEndIndex, $newChartData )


# unclassified table
$unclassifiedTableDate = Get-HtmlForDatasetUnclassified -allCSVDataClassified $allCSVDataClassified 

$scriptEndIndex = $existingHtml.IndexOf("</body>") - 1

$existingHtml = $existingHtml.Insert($scriptEndIndex, $unclassifiedTableDate  )

# export as html
$existingHtml | Out-File -FilePath ".\Auswertung.html"

}
