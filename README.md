## TL-WR841N Flash Dumper
Mit dem Skript `flashdumper.sh` können die Befehlsfolgen aus dem c't Artkile ["Organspende -
TP-Link WR841N: RAM und Flash aufrüsten"](https://www.heise.de/select/ct/2019/14/1561986310067151) halbautomatisiert abgearbeitet werden.

Das Skript ist z.Z. nur für die Verwendung auf einem Raspberry Pi, in Kombination mit der im c't Artikel beschriebenen SPI-Kontaktierung, vorgesehen.


- Das Skript fragt für die Benutzung des Tools ˚flashrom˚ das Sudo-Passwort ab. Das Passwort wird nicht gespeichert.
- Das Skript ermöglicht automatisierte das Herunterladen von U-Boot-Bootloader-Images aus dem Internet.
- Zu verwendene Freifunk-Sysupgrade-Images müssen vorab manuell in einen Ordnern abgelegt werden.
- Das Skript speichert die ausgelesenen Router-Flash-Dumps und die generierten Speicherabbilder in separaten Ordnern.
- Bereits abgespeicherte Speicherabbilder können nachträglich zum Flashen verwendet werden.

---

# Abhängigkeiten
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
