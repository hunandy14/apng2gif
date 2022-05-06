function Download_apng2gif {
    param (
        [switch] $Force
    )
    $AppSource = "https://github.com/hunandy14/apng2gif/raw/master/bin/apng2gif.exe"
    # $AppDir     = $([Environment]::GetFolderPath('Desktop'))
    $AppDir     = "$env:TEMP" + "\apng2gif"
    $FileName   = "apng2gif.exe"
    $AppPath    = "$AppDir\$FileName"
    
    # 創建資料夾
    if (!(Test-Path -PathType:Container $AppDir)) {
        mkdir $AppDir -Force
    }
    # 下載
    if (!(Test-Path -PathType:Leaf $AppPath) -or $Force) {
        Start-BitsTransfer $AppSource $AppPath
        # Invoke-WebRequest $AppSource -OutFile:$env:TEMP\$FileName
        # Expand-Archive "$env:TEMP\$FileName" $AppPath -Force
        # explorer $AppDir
    } # explorer $AppPath
    
    # 輸出
    if (Test-Path -PathType:Leaf $AppPath) { return $AppDir }
} # Download_apng2gif|Out-Null


function cvApng2Gif {
    param (
        [string] $srcDir,
        [string] $dstDir
    )
    # 下載程式並設置到臨時環境變數
    [string] $App = Download_apng2gif
    if (($env:Path).IndexOf($App) -eq -1) { $env:Path = $env:Path + ";$App;" } 
    # 建立目標路徑
    if (!(Test-Path $dstDir -PathType:Container)) { mkdir $dstDir }
    $dstDir = [System.IO.Path]::GetFullPath($dstDir)
    
    # 開始轉換
    Get-ChildItem $srcDir -Recurse -File|ForEach-Object{
        $F1 = $_.FullName
        $F2 = "$dstDir\$($_.BaseName).gif"
        # Write-Host $F1 "--->" $F2
        (apng2gif $F1 $F2)|Out-Null
    }
    explorer $dstDir
} # cvApng2Gif 'animation' 'gif'
# cvApng2Gif 'png' 'gif2'

# dir 'animation' -R -File|%{
#     (cvApng2Gif $_.FullName "gif\$($_.BaseName).gif")|Out-Null
# }

function Run_gif2apng {
    param (
        [string] $srcDir,
        [string] $dstDir
    )
    if (!(Test-Path $dstDir -PathType:Container)) { New-Item -ItemType:Directory $dstDir }
    Get-ChildItem $srcDir -Recurse -File|ForEach-Object{
        (gif2apng $_.FullName "$dstDir\$($_.BaseName).png")|Out-Null
    }
}
# Run_gif2apng 'gif' 'png'