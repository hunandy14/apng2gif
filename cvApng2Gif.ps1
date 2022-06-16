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
    if (!(Test-Path -PathType:Container $AppDir)) { (mkdir $AppDir -Force)|Out-Null }
    # 下載
    if (!(Test-Path -PathType:Leaf $AppPath) -or $Force) {
        Start-BitsTransfer $AppSource $AppPath
        # Invoke-WebRequest $AppSource -OutFile:$env:TEMP\$FileName
        # Expand-Archive "$env:TEMP\$FileName" $AppPath -Force
        # explorer.exe $AppDir
    } # explorer.exe $AppDir
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
        [switch] $Explore,
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
        $Explore = $true
    }
    
    # 下載程式並設置到臨時環境變數
    (Install-apng2gif -Add2EnvPath)|Out-Null
    
    # 建立目標路徑
    if (!(Test-Path $OutPath -PathType:Container)) { (mkdir $OutPath)|Out-Null }
    $OutPath = [System.IO.Path]::GetFullPath($OutPath)

    # 開始轉換
    Get-ChildItem $ApngPath -Recurse -File|ForEach-Object{
        $F1 = $_.FullName
        $F2 = "$OutPath\$($_.BaseName).gif"
        (apng2gif $F1 $F2)|Out-Null
        if ($Log) {
            Write-Host "$F1"
            Write-Host "    ---> $F2" -ForegroundColor:Yellow
        }
        
    }
    # 開啟目錄資料夾
    if ($Explore) { explorer.exe $OutPath }
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
        [switch] $Explore,
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
            $Explore = $true
        } else {
            Write-Host "檔案不是 zip 檔案"
        }
    }
    # 執行轉換
    cvApng2Gif_core -ApngPath:$ApngPath -OutPath:$OutPath -Explore:$Explore -Log:$Log
}
# cvApng2Gif 'Z:\work\stickerpack.zip'
# cvApng2Gif 'animation' 'gif'
# cvApng2Gif 'animation' 'gif' -Log
# cvApng2Gif 'Z:\work\animation' 'Z:\work\gif' -Log

function DLLSticker {
    param (
        [Parameter(Position = 0, ParameterSetName = "", Mandatory)]
        [string] $ID,
        [Parameter(Position = 1, ParameterSetName = "")]
        [string] $Path,
        [switch] $Explore,
        [switch] $ClearTemp
    )
    # 貼圖網址
    $Animation = "https://stickershop.line-scdn.net/stickershop/v1/product/$ID/PC/stickerpack.zip"
    $Sticker   = "https://stickershop.line-scdn.net/stickershop/v1/product/$ID/PC/stickers.zip"
    # 設定
    $URL = $Animation
    $BaseName = "stickerpack"
    # 確認網址有效性
    try { Invoke-WebRequest -Uri:$Animation -ErrorAction:Stop|Out-Null } catch {
        $Is_Static = $true
        $URL = $Sticker
        $BaseName = 'stickers'
        # 非動態貼圖
        try { Invoke-WebRequest -Uri:$Sticker -ErrorAction:Stop|Out-Null } catch { 
            Write-Host "貼圖代碼無效:: 貼圖代碼錯誤" -ForegroundColor:Yellow;return
        }
    }
    $AppDir = $env:TEMP + "\DownloadLineSticker"
    
    # 下載位置
    if (!(Test-Path $AppDir)) { (mkdir $AppDir -Force)|Out-Null }
    # 檔案名稱
    $FileName = "$BaseName.zip"
    $FullName = "$AppDir\$FileName"
    # 解縮位置
    $ExpPath = "$AppDir\temp\$ID"
    # 下載
    Start-BitsTransfer $URL $FullName
    Expand-Archive $FullName $ExpPath -Force
    
    # 輸出檔案
    if ($Is_Static) {
        # 靜態貼圖移動到新位置
        if (!$Path) { $Path = "$AppDir\$ID"; $Explore = $true }
        if (!(Test-Path $Path)) {(mkdir $Path -Force)|Out-Null }
        $Items = ((Get-ChildItem $ExpPath -Filter:'*.png') -notmatch('key|tab_o'))
        Move-Item $Items.FullName $Path -Force
        Write-Host "檔案已輸出到: " -NoNewline
        Write-Host $Path -ForegroundColor:Yellow
        if ($Explore) { explorer.exe $Path }
    } else {
        # 動態貼圖轉換檔案
        if (!$Path) { $Path = "$AppDir\$ID"; $Explore = $true }
        cvApng2Gif "$ExpPath\animation" $Path -Explore:$Explore
    }
    # 移除多於檔案
    if ($ClearTemp) { (Get-ChildItem "$AppDir\temp" -Recurse -File -Include:'*.png')|Remove-Item }
} 
# DLLSticker -ID:13607322 # 動態
# DLLSticker -ID:24468 # 靜態
# DLLSticker -ID:26033 # 靜態
# DLLSticker -ID:6342813 # 靜態