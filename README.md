# TL-WR841N Flash Dumper (für Linux/macOS)
Mit dem Skript `'flashdumper.sh'` können die Befehlsfolgen aus dem c't Artkile ["Organspende -
TP-Link WR841N: RAM und Flash aufrüsten"](https://www.heise.de/select/ct/2019/14/1561986310067151) halbautomatisiert abgearbeitet werden.

### Skript-Eigenschaften

- **Unterschiedlicheste Flash-Programmer können verwendet werden.**
- Das Skript ermöglicht automatisiert das Herunterladen von U-Boot-Bootloader-Images aus dem Internet.
- Das Skript speichert die ausgelesenen Router-Flash-Dumps und die generierten Speicherabbilder in separat benannten Ordner.
- Bereits abgespeicherte Speicherabbilder können nachträglich zum Flashen verwendet werden.
- Zu verwendene Freifunk-Sysupgrade-Images müssen vorab manuell in einen Ordner abgelegt werden.

Das im Skript verwendete Tool `'flashrom'` unterstützt unterschiedlichste Flash-Programmer.  
Neben einem Raspberry Pi, in Kombination mit der im c't Artikel beschriebenen GPIO-Kontaktierung, können weiterhin viele kostengünstige USB-Programmer verwendet werden (wie z.B. CH341a-basierte Programmer). Dieses ermöglicht das einfache Programmieren von Flash-Bausteinen mit einem Linux oder macOS Computer. Das Skript ist in Bezug auf die Programmer-Hardware leicht erweiterbar.

![](https://user-images.githubusercontent.com/1434390/62817023-34ca2c80-bb30-11e9-90f4-fe63b43a94e4.png)
![](https://user-images.githubusercontent.com/1434390/62817024-372c8680-bb30-11e9-8d0b-a8d952e17b32.png)

---

## Abhängigkeiten
### Debian
`'dialog'` muß installiert sein.
```
sudo apt update && sudo apt install dialog
```

Das Tool `'flashrom'` muss nach der Anleitung des c't Artikels installiert sein.
```
sudo apt update &&  sudo apt install git libpci-dev libusb-1.0 libusb-dev
cd
git clone https://github.com/flashrom/flashrom
cd flashrom
make && sudo make install
```

### macOS (Homebrew) 
`'dialog'` muß installiert sein.
```
brew install dialog
```

Das Tool `'flashrom'` muss installiert sein.
```
brew install flashrom
```
