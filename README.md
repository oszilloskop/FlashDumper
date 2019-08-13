# TL-WR841N Flash Dumper (für Linux/macOS)
Mit dem Skript `'flashdumper.sh'` können die Befehlsfolgen aus dem c't Artkile ["Organspende -
TP-Link WR841N: RAM und Flash aufrüsten"](https://www.heise.de/select/ct/2019/14/1561986310067151) halbautomatisiert abgearbeitet werden.

## Skript-Eigenschaften

- **Unterschiedlicheste Flash-Programmer können verwendet werden.**
- Das Skript ermöglicht automatisiert das Herunterladen von U-Boot-Bootloader-Images aus dem Internet.
- Das Skript speichert die ausgelesenen Router-Flash-Dumps und die generierten Speicherabbilder in separat benannte Ordner.
- Bereits abgespeicherte Speicherabbilder können nachträglich zum Flashen verwendet werden.
- Zu verwendene Freifunk-Sysupgrade-Images müssen vorab manuell in einen Ordner abgelegt werden.

Das im Skript verwendete Tool `'flashrom'` unterstützt unterschiedlichste Flash-Programmer.  
Neben einem Raspberry Pi, in Kombination mit der im c't Artikel beschriebenen GPIO-Kontaktierung, können weiterhin viele kostengünstige USB-Programmer verwendet werden (wie z.B. CH341a-basierte Programmer). Dieses ermöglicht das einfache Programmieren von Flash-Bausteinen mit einem Linux oder macOS Computer. Das Skript ist in Bezug auf die Programmer-Hardware leicht erweiterbar.

![](https://user-images.githubusercontent.com/1434390/62911018-1871fe00-bd83-11e9-8231-481d3d9cdc44.png)
![](https://user-images.githubusercontent.com/1434390/62911031-1f990c00-bd83-11e9-93f5-1c2494607440.png)

## Dateistruktur
In der Datei `interface.cfg` werden Informationen zum eingestellten Flash-Programmer abgelegt und bei jedem Neustart wieder eingelesen.


Das Skript legt eigenständig folgende Unterordner an:

| Unterordner                                 | Inhalt                                                            |
| ------------------------------------------- | ----------------------------------------------------------------- |
| ./uboot-images/                             | Hier werden U-boot-Images geladen/erwartet                        |
| ./basis-firmware/                           | Hier werden die Basis-Firmware-Images (Sysupgrades) erwartet      |
| ./router-flash-dumps/wr841n-vXY-MACAdresse/ | Hier werden u.a. ausgelesene Router-spezifische Dumps abgelegt    |
| ./flash-modified/                           | Hier werden neu generierte Router-Flash-Speicherabbilder abgelegt |


In den einzelnen Verzeichnissen unterhalb von `./router-flash-dumps/` werden folgende namentlich vereinheitlichte Router-spezifische Dateien abgelegt:

| Dateiname                                | Inhalt                                          |
| ------------------- | -------------------------------------------------------------------- |
| flashdump.bin       | Ausgelesener 4MB Flash-Dump                                          |
| artdump.bin         | Extrahierte ART-Partition mit Kalibierungsdaten                      |
| uboot.bin           | Router-spezifischer U-Boot-Loader                                    |
| gluonsysuograde.bin | Basis-Firmware (Sysupgrade der ausgewählten OpenWrt-/Gluon-Firmware) |

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
