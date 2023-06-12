function Format-ShareGateLogFile {
        <#
    .SYNOPSIS
    Formats a ShareGate log file in Excel format.

    .DESCRIPTION
    This function opens a ShareGate log file in Excel format and formats it for readability. It adds a table to the first worksheet, formats the first column as "Date-Time", calculates the duration of the log file, and formats the duration as "[h]:mm:ss" in the last row. The function saves the changes to the Excel file and closes it.

    .PARAMETER Path
    The path to the Excel file to format. This parameter is mandatory.

    .PARAMETER Open
    Pass the Open parameter if you want the file to open up in Excel automatically after it has been formatted.

    .EXAMPLE
    PS C:\> Format-ShareGateLogFile -Path "C:\path\to\ShareGateLogFile.xlsx"
    Formats the Excel file located at "C:\path\to\ShareGateLogFile.xlsx" for readability.

    .EXAMPLE
    PS C:\> Format-ShareGateLogFile -Path "C:\path\to\ShareGateLogFile.xlsx" -Open
    Formats the Excel file located at "C:\path\to\ShareGateLogFile.xlsx" for readability and opens the Excel file automatically after it has been formatted.
    
    .EXAMPLE
    PS C:\> Format-ShareGateLogFile -Path "C:\path\to\ShareGateLogFile.xlsx" -HideColumns -Open
    Formats the Excel file located at "C:\path\to\ShareGateLogFile.xlsx" for readability, hides the specified columns (E-U, W-AR, AT-BA), and opens the Excel file automatically after it has been formatted.

    .EXAMPLE
    PS C:\> Get-ChildItem -Path "C:\path\to\folder" -Filter "*.xlsx" | Format-ShareGateLogFile -HideColumns -Open
    This will get all the Excel (.xlsx) files in the specified folder, and for each one, it will be formatted for readability, with specified columns (E-U, W-AR, AT-BA) hidden, and the Excel file opened automatically after it has been formatted.

    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$Path,
        [switch]$HideColumns,
        [switch]$Open
    )

    Begin {
        # Verify that ImportExcel module is installed
        if (-not(Get-Module -Name ImportExcel -ListAvailable)) {
            throw "ImportExcel module is not installed. Please install the module and try again."
        }
    }

    Process {

        # Open Excel file
        Write-Verbose "Processing $Path..."
        try {
            $excel = Open-ExcelPackage $Path
            $ws = $excel.Workbook.Worksheets[1]
        }
        catch {
            throw "Unable to open $Path. Please make sure the file is not open in another program and try again."
        }

        # Test to see it has already been worked on
        if ($ws.Tables.Count-ne 0) {
            Write-Host "The file $Path already has a Table. Skipping"
            Return
        } else {
            Write-Verbose "Formattting $Path..."
        }
        # Add table and format columns
        Add-ExcelTable -Range $ws.Cells[$($ws.Dimension.Address)] -TableName Table1 -TableStyle Medium2
        Set-ExcelColumn -Worksheet $ws -Column 1 -NumberFormat 'Date-Time'

        # Set format for last row
        $NumRows = $excel.Workbook.Worksheets.Dimension.Rows
        Set-Format -Range $excel.Workbook.Worksheets[1].Cells["A$($NumRows + 2):AA$($NumRows + 2)"] -NumberFormat '[h]:mm:ss'

        # Calculate duration and add formula to last row
        $cell = $ws.Cells["A$($NumRows + 2):A$($NumRows + 2)"]
        $cell.Formula = "=A2-A$($NumRows)"

        if ($HideColumns) {
            Write-Verbose "Hiding Columns"

            # Define the columns 
            $ColumnsToHideList = 5..21 + 23..44 + 46..53  # Columns E-U, W-AR, AT-BA

            # Iterate through the columns and set the 'Hidden' property to $true
            foreach ($i in $ColumnsToHideList) {
                $ws.Column($i).Hidden = $true
            }

        }
        # Close Excel file
        if ($Open) {
            Write-Verbose "Opening $Path"
            Close-ExcelPackage $excel -Show
        } else {
            Write-Verbose "Not opening $Path"
            Close-ExcelPackage $excel
        }
        
    }

    End {
        # Nothing needed here
    }
}