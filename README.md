# TL-WR841N Flash Dumper (für Linux/macOS)
Mit dem Skript `flashdumper.sh` können die Befehlsfolgen aus dem c't Artkile ["Organspende -
TP-Link WR841N: RAM und Flash aufrüsten"](https://www.heise.de/select/ct/2019/14/1561986310067151) halbautomatisiert abgearbeitet werden.

Das vom Skript genutzte Tool `flashrom` unterstützt unterschiedlichste Flash-Programmer.  
Neben einem Raspberry Pi, in Kombination mit der im c't Artikel beschriebenen GPIO-Kontaktierung, werden auch viele kostengünstige USB-Programmer unterstützt (wie z.B. ein CH341a-Programmer). Dieses ermöglicht das einfache Programmieren von Flash-Bausteinen mit einem Linux oder macOS Computer. Das Skript ist in Bezug auf die Programmer-Hardware leicht erweiterbar.

- Unterschiedlicheste Flash-Programmer können verwendet werden.
- Das Skript ermöglicht automatisiert das Herunterladen von U-Boot-Bootloader-Images aus dem Internet.
- Zu verwendene Freifunk-Sysupgrade-Images müssen vorab manuell in einen Ordner abgelegt werden.
- Das Skript speichert die ausgelesenen Router-Flash-Dumps und die generierten Speicherabbilder in separaten Ordner.
- Bereits abgespeicherte Speicherabbilder können nachträglich zum Flashen verwendet werden.

![](https://user-images.githubusercontent.com/1434390/62804067-746f2500-baec-11e9-8a98-f384d7116729.png)
![](https://user-images.githubusercontent.com/1434390/62804073-776a1580-baec-11e9-8e26-a88920ae27c5.png)
![](https://user-images.githubusercontent.com/1434390/62804083-7df88d00-baec-11e9-8b39-40353d07ba61.png)
![](https://user-images.githubusercontent.com/1434390/62417465-6e8ec500-b650-11e9-8e13-fa6db153b994.png)
---

## Abhängigkeiten
### Debian
`"dialog"` muß installiert sein.
```
sudo apt update && sudo apt install dialog
```

Das Tool `"flashrom"` muss nach der Anleitung des c't Artikels installiert sein.
```
sudo apt update &&  sudo apt install git libpci-dev libusb-1.0 libusb-dev
cd
git clone https://github.com/flashrom/flashrom
cd flashrom
make && sudo make install
```

### macOS (Homebrew) 
`"dialog"` muß installiert sein.
```
brew install dialog
```

Das Tool `"flashrom"` muss installiert sein.
```
brew install flashrom
```
