function Install-apng2gif {
    param (
        [switch] $Force
    )
    $AppSource = "https://github.com/hunandy14/apng2gif/raw/master/bin/apng2gif.exe"
    # $AppDir     = $([Environment]::GetFolderPath('Desktop'))
    $AppDir     = "$env:TEMP" + "\apng2gif"
    $FileName   = "apng2gif.exe"
    $AppPath    = "$AppDir\$FileName"

    # 檢測命令是否已經存在
    if (Get-Command $FileName -CommandType:Application -ErrorAction:0) { return }

    # 創建資料夾
    if (!(Test-Path -PathType:Container $AppDir)) { mkdir $AppDir -Force }
    # 下載
    if (!(Test-Path -PathType:Leaf $AppPath) -or $Force) {
        Start-BitsTransfer $AppSource $AppPath
        # Invoke-WebRequest $AppSource -OutFile:$env:TEMP\$FileName
        # Expand-Archive "$env:TEMP\$FileName" $AppPath -Force
        # explorer $AppDir
    } # explorer $AppDir
    # 加到臨時變數
    if (($env:Path).IndexOf($AppDir) -eq -1) {
        if ($env:Path[-1] -ne ';') { $env:Path = $env:Path+';' }
        $env:Path = $env:Path + "$AppDir"
    }
    # 輸出
    if (Test-Path -PathType:Leaf $AppPath) { return $AppDir }
} # Install-apng2gif -Add2EnvPath

function cvApng2Gif_core {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $ApngPath,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $OutPath,
        [switch] $ShowFolder,
        [switch] $Log
    )
    # 設定值
    $Path = "$env:TEMP\cvApng2Gif"
    
    # 檢測路徑
    if (!(Test-Path -Type:Container $ApngPath)){
        Write-Error "ApngPath 路徑有誤無法讀取[$ApngPath]"; return
    } else {
        $ApngPath = [System.IO.Path]::GetFullPath($ApngPath)
    }
    
    # 輸出路徑為空
    if (!$OutPath) {
        $OutPath  = "$Path\gif"
        $ShowFolder = $true
    }
    
    # 下載程式並設置到臨時環境變數
    Install-apng2gif -Add2EnvPath
    
    # 建立目標路徑
    if (!(Test-Path $OutPath -PathType:Container)) { mkdir $OutPath }
    $OutPath = [System.IO.Path]::GetFullPath($OutPath)

    # 開始轉換
    Get-ChildItem $ApngPath -Recurse -File|ForEach-Object{
        $F1 = $_.FullName
        $F2 = "$OutPath\$($_.BaseName).gif"
        (apng2gif $F1 $F2) | Out-Null
        if ($Log) {
            Write-Host "$F1"
            Write-Host "    ---> $F2" -ForegroundColor:Yellow
        }
        
    }
    # 開啟目錄資料夾
    if ($ShowFolder) { explorer $OutPath }
    Write-Host "檔案已輸出到: " -NoNewline
    Write-Host $OutPath -ForegroundColor:Yellow
}
# cvApng2Gif_core 'animation' 'gif'
# cvApng2Gif_core 'animation' 'gif' -Log
# cvApng2Gif_core 'Z:\work\animation' 'Z:\work\gif' -Log

function cvApng2Gif {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $ApngPath,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $OutPath,
        [switch] $ShowFolder,
        [switch] $Log
    )
    # 設定值
    $Path = "$env:TEMP\cvApng2Gif"
    
    # 檢測
    if (!(Test-Path -Type:Any $ApngPath)){
        Write-Error "ApngPath 路徑有誤無法讀取[$ApngPath]"; return
    } else {
        $ApngPath = [System.IO.Path]::GetFullPath($ApngPath)
    }
    # 輸入為zip檔案先解壓縮到Temp目錄
    if (Test-Path -Type:Leaf $ApngPath){
        if ($ApngPath -match '(.zip)$') {
            $BaseName = (Get-ChildItem $ApngPath).BaseName
            $FullName = (Get-ChildItem $ApngPath).FullName
            Expand-Archive $FullName "$Path\$BaseName" -Force
            # 重定位輸入輸出路徑
            $ApngPath = "$Path\$BaseName\animation"
            $OutPath  = "$Path\gif"
            $ShowFolder = $true
        } else {
            Write-Host "檔案不是 zip 檔案"
        }
    }
    # 執行轉換
    cvApng2Gif_core -ApngPath:$ApngPath -OutPath:$OutPath -ShowFolder:$ShowFolder -Log:$Log
}
# cvApng2Gif 'Z:\work\stickerpack.zip'
# cvApng2Gif 'animation' 'gif'
# cvApng2Gif 'animation' 'gif' -Log
# cvApng2Gif 'Z:\work\animation' 'Z:\work\gif' -Log



# 廢棄代碼
# function Run_gif2apng {
#     param (
#         [string] $ApngPath,
#         [string] $dstDir
#     )
#     if (!(Test-Path $dstDir -PathType:Container)) { New-Item -ItemType:Directory $dstDir }
#     Get-ChildItem $ApngPath -Recurse -File|ForEach-Object{
#         (gif2apng $_.FullName "$dstDir\$($_.BaseName).png")|Out-Null
#     }
# }
# Run_gif2apng 'gif' 'png'

# 轉換的最簡短代碼
# dir 'animation' -R -File|%{
#     (cvApng2Gif $_.FullName "gif\$($_.BaseName).gif")|Out-Null
# }