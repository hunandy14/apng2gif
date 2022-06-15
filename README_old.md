Line貼圖轉PNG轉GIF
===

## Line貼圖下載
1. 安裝Chrome套件  
https://chrome.google.com/webstore/detail/stickers-packer/bngfikljchleddkelnfgohdfcobkggin

2. 下載商店貼圖  
https://store.line.me/stickershop/product/13607322/?ref=Desktop

![](img/1.下載貼圖.png)


## 使用方法

- animation : png圖片路徑
- gif       : 轉換後的gif路徑


```ps1
# 用法1 (輸入下載的Line貼圖包zip檔案, 輸出在Temp目錄並自動打開)
irm bit.ly/3mBqlW1|iex; cvApng2Gif 'D:\stickerpack.zip'

# 用法2 (輸出在Temp目錄並自動打開)
irm bit.ly/3mBqlW1|iex; cvApng2Gif 'D:\animation'

# 用法3
irm bit.ly/3mBqlW1|iex; cvApng2Gif 'D:\animation' 'D:\animation\gif'

```

> 備註：Powershell 5 下不支援相對路徑




## 原始命令使用方法
```ps1
dir 'animation' -R -File|%{
    (cvApng2Gif $_.FullName "gif\$($_.BaseName).gif")|Out-Null
}
```
