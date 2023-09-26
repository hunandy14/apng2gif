# 檢查鏈接是否有效
function Test-URI {
    param (
        [Parameter(Position=0, Mandatory)]
        [string] $Uri
    )
    try {
        # 嘗試發送 HEAD 請求
        $response = Invoke-WebRequest -Uri $Uri -Method Head -TimeoutSec 10
        # 檢查 HTTP 狀態碼是否為 200
        if ($response -and $response.StatusCode -eq 200) {
            return $true
        } else {
            # Write-Warning "Received HTTP status code $($response.StatusCode). The link might not be valid."
            return $false
        }
    } catch {
        # Write-Warning "Error checking the link: $_"
        return $null
    }
} # Test-URI "https://github.com/hunandy14/apng2gif/raw/master/bin/apng2gif.exe"



# 安裝apng2gif
function Install-apng2gif {
    param (
        [switch] $Force
    )
    $AppSource = "https://github.com/hunandy14/apng2gif/raw/master/bin/apng2gif.exe"
    # $AppDir     = $([Environment]::GetFolderPath('Desktop'))
    $AppDir     = "$env:TEMP" + "\apng2gif"
    $FileName   = "apng2gif.exe"
    $AppPath    = "$AppDir\$FileName"
    
    # 檢測命令是否已經存在 (別重載汙染環境變數)
    if (Get-Command $FileName -CommandType:Application -ErrorAction:0) { return }
    
    # 下載
    if (!(Test-Path -PathType:Leaf $AppPath) -or $Force) {
        try {
            if (!(Test-Path -PathType:Container $AppDir)) { (mkdir $AppDir -Force)|Out-Null }
            (New-Object Net.WebClient).DownloadFile($AppSource, $AppPath)
        } catch {
            Write-Error $_.Exception.Message -ErrorAction Stop
        }
    }
    
    # 加到臨時變數
    if (($env:Path).IndexOf($AppDir) -eq -1) {
        if ($env:Path[-1] -ne ';') { $env:Path = "$env:Path;" }
        $env:Path = $env:Path+ "$AppDir"
    }
    
    # 輸出
    if (Test-Path -PathType:Leaf $AppPath) {
        return $AppDir
    }
} # Install-apng2gif -Add2EnvPath -Force




# 轉換png到gif的核心函式
function cvApng2Gif {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $Path,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $OutPath,
        [switch] $OutNull
    )
    # 同步化C#的工作路徑
    [IO.Directory]::SetCurrentDirectory(((Get-Location -PSProvider FileSystem).ProviderPath))
    # 檢測路徑
    if (!(Test-Path -Type:Container $Path)){ Write-Error "錯誤:: 路徑 '$Path' 可能有誤" -ErrorAction Stop } 
    $Path = [System.IO.Path]::GetFullPath($Path)
    # 輸出路徑為空
    if (!$OutPath) { $OutPath  = "$env:TEMP\cvApng2Gif\gif" }
    # 下載程式並設置到臨時環境變數
    (Install-apng2gif -Add2EnvPath)|Out-Null
    # 建立目標路徑
    if (!(Test-Path $OutPath -PathType:Container)) { (mkdir $OutPath)|Out-Null }
    $OutPath = [System.IO.Path]::GetFullPath($OutPath)
    # 開始轉換
    Get-ChildItem $Path -Recurse -File|ForEach-Object{
        $F1 = $_.FullName; $F2 = "$OutPath\$($_.BaseName).gif"
        (apng2gif $F1 $F2)|Out-Null
        # Write-Host "$F1"; Write-Host "    ---> $F2" -ForegroundColor:Yellow
    }
    # 輸出
    if (!$OutNull) { Write-Host "檔案已輸出到: " -NoNewline; Write-Host $OutPath -ForegroundColor:Yellow }
}
# cvApng2Gif 'animation' 'gif'
# cvApng2Gif 'animation2' 'gif'





# 下載LINE貼圖的API
function DLLSticker {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $ID,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Path,
        [switch] $NotOpenExplore,
        [switch] $ClearTemp,
        [switch] $Desktop
    )
    # 貼圖網址列表
    $Urls = [ordered] @{
        "SticDyn" = "https://stickershop.line-scdn.net/stickershop/v1/product/$ID/PC/stickerpack.zip"
        "SticStc" = "https://stickershop.line-scdn.net/stickershop/v1/product/$ID/PC/stickers.zip"
        "EmojDyn" = "https://stickershop.line-scdn.net/sticonshop/v1/$ID/sticon/android/package_animation.zip"
        "EmojStc" = "https://stickershop.line-scdn.net/sticonshop/v1/$ID/sticon/android/package.zip"
    }

    # 以KeyValuePair的形式驗證網址
    $ValidEntry = $Urls.GetEnumerator() | Where-Object { Test-URI $_.Value } | Select-Object -First 1
    if ($ValidEntry) {
        $URL = $ValidEntry.Value
        $type = $ValidEntry.Name
        $BaseName = if ($URL -match '.*/(.*?).zip$') { $matches[1] }
        $Is_Static = $type -match "Stc$"
        $Dyn_Path = if ($type -eq 'SticDyn') {'\animation'} else { '' }
    } else {
        Write-Host "錯誤:: 無法獲取有效網址, 貼圖代碼 '$ID' 可能有誤" -ErrorAction Stop
    }
    
    
    # 下載位置
    $AppDir = $env:TEMP+"\DownloadLineSticker"
    if (!(Test-Path $AppDir)) { (mkdir $AppDir -Force)|Out-Null }
    # 輸出位置
    $OutPath = $null
    $DirName = 'Line貼圖下載區'
    if ($Desktop) {
        $userDsk = [Environment]::GetFolderPath("Desktop")+"\$DirName"
        $OutPath = "$userDsk\$ID"
    } else {
        $userDwn = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path+"\$DirName"
        $OutPath = "$userDwn\$ID"
    }
    # 下載
    $FullName = "$AppDir\$BaseName.zip"
    $ExpPath = "$AppDir\temp\$ID"
    (New-Object Net.WebClient).DownloadFile($URL, $FullName)
    Expand-Archive $FullName $ExpPath -Force
    
    # 輸出檔案
    if ($Is_Static) {
        # 靜態貼圖移動到新位置
        if (!$Path) { $Path = $OutPath}
        if (!(Test-Path $Path)) {(mkdir $Path -Force)|Out-Null }
        $Items = ((Get-ChildItem $ExpPath -Filter:'*.png') -notmatch('key|tab_o|\.json$'))
        Move-Item $Items.FullName $Path -Force
    } else {
        # 動態貼圖轉換檔案
        if (!$Path) { $Path = $OutPath}
        $pngPath = ($ExpPath+$Dyn_Path)
        cvApng2Gif $pngPath $Path -OutNull
    }
    # 輸出
    Write-Host "檔案已輸出到: " -NoNewline; Write-Host $Path -ForegroundColor:Yellow
    # 打開資料夾
    if (!$NotOpenExplore) { explorer.exe $Path }
    # 移除多於檔案
    if ($ClearTemp) { (Get-ChildItem "$AppDir\temp" -Recurse -File -Include:'*.png')|Remove-Item }
} # DLLSticker 13607322
# DLLSticker -Desktop -NotOpenExplore -ID:26033                      # 貼圖靜態(大圖)
# DLLSticker -Desktop -NotOpenExplore -ID:13607322                   # 貼圖動態
# DLLSticker -Desktop -NotOpenExplore -ID:24468                      # 貼圖靜態
# DLLSticker -Desktop -NotOpenExplore -ID 5ca9a963031a677a3a4a4832   # 表情靜態
# DLLSticker -Desktop -NotOpenExplore -ID 63be6d9785d52f7ff1258458   # 表情動態



# 下載DLLSticker
function Download_DLLSticker {
    param (
        [string] $Path = $([Environment]::GetFolderPath('Desktop')),
        [string] $Name = "下載Line貼圖.lnk",
        [switch] $Force
    )
    $Url      = "https://github.com/hunandy14/apng2gif/raw/master/soft/DLLSticker.lnk"
    $FullName = "$Path\$Name"
    if (!(Test-Path $FullName) -or $Force) {
        (New-Object Net.WebClient).DownloadFile($Url, $FullName)
    }
} # Download_DLLSticker
