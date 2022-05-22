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

> 備註: 實測 Powershell5.1 啟動不能使用相對路徑

```ps1
irm bit.ly/3KUdrvH|iex; cvApng2Gif 'animation' 'gif'
```
