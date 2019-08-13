#!/bin/bash
histchars=

#-------------------------------------------------------------------------------
# Skript-Name  : flashdumper.sh
# Beschreibung : Halbautomatisierte abarbeitung der Befehlsfolgen aus dem c't Artikel
#                "Organspende - TP-Link WR841N: RAM und Flash aufrüsten" c't 14/2019 S. 128
#                -> https://www.heise.de/select/ct/2019/14/1561986310067151
#                Basis für die verwendeten HW-IDs ist folgender Patch für Gluon:
#                -> https://github.com/freifunkh/site/blob/stable/patches/0003-added-TP-Link-TL-WR841ND-N-Devices-for-8M-and-16M-Va.patch
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# "flashrom"-Tool Parameter
#-------------------------------------------------------------------------------
FLASHROM_PROGRAMMER_PARAMETER="linux_spi:dev=/dev/spidev0.0,spispeed=1000"
FLASHROM_PROGRAMMER="linux_spi"
SUDO_CMD="sudo -S"

#-------------------------------------------------------------------------------
# Ordner und Dateinamen
#-------------------------------------------------------------------------------
WORKINGDIRECTORY=$(pwd)
UBOOTDIRECTORY="uboot-images"
FIRMWAREDIRECTORY="basis-firmware"
FLASHDUMPDIRECTORY="router-flash-dumps"
NEWFLASHDIRECTORY="flash-modified"
DUMPFILENAME="flashdump.bin"
INTERFACECONFIGFILENAME="$WORKINGDIRECTORY/interface.cfg"

#-------------------------------------------------------------------------------
# UI Dialog Defaults
#-------------------------------------------------------------------------------
TITEL="TL-WR841N Flash Dumper"
UI_ITEM_HM="setup"
UI_ITEM_SM="programmer"
MAC_ADR="tbd"
MAC_FORMAT1="tbd"
MAC_FORMAT2="tbd"
ROUTER="tbd"
FLASHSIZE="tbd"
FIRMWARE="tbd"
HWID="tbd"

#-------------------------------------------------------------------------------
# Informationstext und Anlegen der Ordnerstruktur
#-------------------------------------------------------------------------------
dialog --title "\Z1Hinweis zur Ordnerstruktur" --colors \
       --msgbox "\n\Zb./$UBOOTDIRECTORY\Zn:\nHier werden U-Boot-Images erwartet.\n(Automatischer Download unter Menüpunkt 'Setup' möglich.)\
                \n\n\Zb./$FIRMWAREDIRECTORY\Zn:\nHier werden Basis-Firmware-Images (Sysupgrade) erwartet.\
                \n\n\Zb./$FLASHDUMPDIRECTORY\Zn:\nHier werden ausgelesene Router-Flash-Dumps abgespeichert.\
                \n\n\Zb./$NEWFLASHDIRECTORY\Zn:\nHier werden neu generierte Flash-Speicherabbilder abgespeichert.\
                \n\nDie Ordner werden automatisch im aktuellen Arbeitsverzeichnis angelegt.\
                " 19 78 3>&1 1>&2 2>&3

if [[ ! -d "$FIRMWAREDIRECTORY" ]]; then
  mkdir "$FIRMWAREDIRECTORY"
fi

if [[ ! -d "$UBOOTDIRECTORY" ]]; then
  mkdir "$UBOOTDIRECTORY"
fi

if [[ ! -d "$FLASHDUMPDIRECTORY" ]]; then
  mkdir "$FLASHDUMPDIRECTORY"
fi

if [[ ! -d "$NEWFLASHDIRECTORY" ]]; then
  mkdir "$NEWFLASHDIRECTORY"
fi

if [[ -f "$INTERFACECONFIGFILENAME" ]]; then
  FLASHROM_PROGRAMMER=$(sed -n '1p' "$INTERFACECONFIGFILENAME")
  FLASHROM_PROGRAMMER_PARAMETER=$(sed -n '2p' "$INTERFACECONFIGFILENAME")
  SUDO_CMD=$(sed -n '3p' "$INTERFACECONFIGFILENAME")
fi  

#-------------------------------------------------------------------------------
# UI: Hauptmenü
#-------------------------------------------------------------------------------
UI_hauptmenue() {
exec 3>&1
while [ 1 ]
do
  UI_ITEM_HM=$( dialog --title "$TITEL" --cancel-button "Beenden" --no-tags --default-item "$UI_ITEM_HM" \
                --menu "Hauptmenü" 20 78 13 \
                "setup"             "Setup" \
                "linktest"          "Elektrische Verbindung zum Flash-Baustein testen" \
                "router"            "Auswahl des Router-Modells" \
                "mac_manuell"       "MAC-Adresse des Routers" \
                "flashsize"         "Speicherkapazität des neuen Flash-Bausteins" \
                "firmware"          "Zu verwendende Basis-Firmware (OpenWrt/Gluon Sysupgrade-Firmware)" \
                "auflistung"        "Zusammenfassung der Einstellungen" \
                "auslesen"          "Alten 4MB Flash-Baustein auslesen (inkl. Verify) und Inhalt speichern" \
                "erstellen"         "Neues Flash-Speicherabbild generieren" \
                "beschreiben"       "Neuen Flash-Baustein mit aktuell generiertem Speicherabbild beschreiben" \
                "reset"             "Router-Angaben zurücksetzen" \
                "beschreiben_liste" "Optional einen Flash-Baustein mit Speicherabbild aus Ordner beschreiben" \
                3>&1 1>&2 2>&3)

response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then
  exit
fi


  case "$UI_ITEM_HM" in
    setup)
                UI_setup
                ;;
    router)
                UI_router_hardware
                ;;
    mac_manuell)
                UI_mac_adr
                ;;
    flashsize)
                UI_flash_size
                ;;
    linktest)
                linktest
                ;;
    firmware)
                UI_firmware
                ;;
    auflistung)
                UI_auflistung
                ;;
    auslesen)
                auslesen
                ;;
    erstellen)
                erstellen
                ;;
    beschreiben)
                beschreiben
                ;;
    beschreiben_liste)
                UI_beschreiben
                ;;
    reset)
                reset_param
                ;;
  esac
done
}

#-------------------------------------------------------------------------------
# UI: Tool-Setup
#-------------------------------------------------------------------------------
UI_setup() {
exec 3>&1
while [ 1 ]
do

  UI_ITEM_SM=$( dialog --title "$TITEL" --notags --cancel-button "Zurück" --default-item "$UI_ITEM_SM" \
                --menu "Setup" 19 78 11 \
                "programmer" "Auswahl des Programmer-Interfaces" \
                "linktest"   "Elektrische Verbindung zum Flash-Baustein testen" \
                "download"   "Download aller TL-WR841N U-Boot Bootloader (Internet notwendig)" \
                "passwort"   "Eingabe 'sudo'-Passwort (nur notwendig bei Raspberry Pi SPI)" \
                "zurueck"    "<-- Zurück" \
                3>&1 1>&2 2>&3)

response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then 
  break
fi

  case "$UI_ITEM_SM" in
    programmer)
                UI_programmer
                ;;
    linktest)
                linktest
                ;;
    download)
                download
                ;;
    passwort)
                UI_passwort
                ;;
    zurueck)
                break
  esac
done
}

#-------------------------------------------------------------------------------
# UI: Passworteingabe
#-------------------------------------------------------------------------------
exec 3>&1
UI_passwort() {
PASSWORD=$(dialog --title "$TITEL" --cancel-button "Zurück" --insecure \
           --passwordbox "Das Tool 'flashrom' muss aktuell mit Root-Rechten ausgeführt werden. Dafür wird das sudo-Passwort benötigt." 9 78 $PASSWORD \
           3>&1 1>&2 2>&3)

response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then
  PASSWORD=""
fi

}

#-------------------------------------------------------------------------------
# UI: Auswahl Programmer-Interface
#-------------------------------------------------------------------------------
UI_programmer() {
exec 3>&1
AUSWAHL=$(dialog --title "$TITEL" --notags --nocancel --default-item "$FLASHROM_PROGRAMMER"\
           --menu "Flash-Programmer-Interface" 19 78 10 \
           "linux_spi"      "Raspberry Pi GPIO (default)" \
           "ch341a_spi"     "USB-Programmer mit CH341A-Baustein" \
           "ft2232_spi"     "USB-Programmer mit ft2232-Baustein" \
           "dediprog"       "USB-Programmer Dediprog SF100" \
           "usbblaster_spi" "USB-Programmer Altera USB-Blaster" \
           "pickit2_spi"    "USB-Programmer Microchip PICkit2" \
           "digilent_spi"   "USB-Programmer iCEblink40 development boards" \
           "dummy_4MB"      "Virtueller Programmer mit simuliertem 4MByte Flash-Baustein" \
           "dummy_8MB"      "Virtueller Programmer mit simuliertem 8MByte Flash-Baustein" \
           3>&1 1>&2 2>&3)

response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then
  return
fi

FLASHROM_PROGRAMMER=$AUSWAHL
FLASHROM_PROGRAMMER_PARAMETER="$FLASHROM_PROGRAMMER"
SUDO_CMD=""

if [[ $FLASHROM_PROGRAMMER == "linux_spi" ]]; then
  FLASHROM_PROGRAMMER_PARAMETER="linux_spi:dev=/dev/spidev0.0,spispeed=1000"
  SUDO_CMD="sudo -S"

elif [[ $FLASHROM_PROGRAMMER == "dummy_4MB" ]]; then
  FLASHROM_PROGRAMMER_PARAMETER="dummy:emulate=SST25VF032B"

elif [[ $FLASHROM_PROGRAMMER == "dummy_8MB" ]]; then
  FLASHROM_PROGRAMMER_PARAMETER="dummy:emulate=MX25L6436 -c MX25L6405"

fi

echo "$FLASHROM_PROGRAMMER" > "$INTERFACECONFIGFILENAME"
echo "$FLASHROM_PROGRAMMER_PARAMETER" >> "$INTERFACECONFIGFILENAME"
echo "$SUDO_CMD" >> "$INTERFACECONFIGFILENAME"

}


#-------------------------------------------------------------------------------
# UI: Routerauswahl
#-------------------------------------------------------------------------------
UI_router_hardware() {
exec 3>&1
AUSWAHL=$(dialog --title "$TITEL" --notags --nocancel --default-item "$ROUTER" \
         --menu "Router-Modell\n" 19 78 10 \
         "tbd" "Keine Auswahl" \
         "wr841n-v8" "Tl-WR841N/ND v8 " \
         "wr841n-v9" "Tl-WR841N/ND v9 " \
         "wr841n-v10" "Tl-WR841N/ND v10 " \
         "wr841n-v11" "Tl-WR841N/ND v11 " \
         3>&1 1>&2 2>&3)
response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then
  return
fi

ROUTER=$AUSWAHL
}

#-------------------------------------------------------------------------------
# UI: Einstellen der Flash-Bausteingröße
#-------------------------------------------------------------------------------
UI_flash_size() {
AUSWAHL=$(dialog --title "$TITEL" --notags --nocancel --default-item "$FLASHSIZE" \
            --menu "Speichergröße Flash-Baustein\n" 19 78 10 \
            "tbd" "Keine Auswahl" \
            "8MB" "8 MByte / 64 Mbit " \
            "16MB" "16 MByte / 128 Mbit " \
            3>&1 1>&2 2>&3)
response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then
  return
fi

FLASHSIZE=$AUSWAHL
}

#-------------------------------------------------------------------------------
# UI: Eingabe und formatierung der MAC-Adresse
#-------------------------------------------------------------------------------
UI_mac_adr() {
exec 3>&1
EINGABE=$(dialog --title "$TITEL" --nocancel \
              --inputbox "12 stellige MAC-Adresse des Routers (mit oder ohne Separatoren)" 8 78 "${MAC_FORMAT2//tbd/}" \
              3>&1 1>&2 2>&3)
response=$?
if [[ $response == "255" ]] || [[ $response == "1" ]]; then
  # ESC-Taste führt zum löschen der MAC-Adresse. Ist ein mittelmäßiger Kompromiss.
  MAC_ADR="tbd"
  MAC_FORMAT1="tbd"
  MAC_FORMAT2="tbd"
  return
fi

# Ggf vorhandene Trennzeichen/Separatoren entfernen (':', '-' und ' ')
MAC_ADR="$EINGABE"
MAC_ADR=$(echo "${MAC_ADR//:/}")
MAC_ADR=$(echo "${MAC_ADR//-/}")
MAC_ADR=$(echo "${MAC_ADR// /}")

MAC_FORMAT2=$EINGABE   # Vorbereiten für neue Eingabe

if [[ ! $MAC_ADR =~ ^[a-fA-F0-9]+$ ]]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDie eingegebene MAC-Adresse enthält ungültige Zeichen." 8 78
  UI_mac_adr # Erneute Eingabeaufforderung
fi

if [ ${#MAC_ADR} -ne 12 ]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDie eingegebene MAC-Adresse ist zu lang oder zu kurz." 8 78

  UI_mac_adr  # Erneute Eingabeaufforderung
else

# MAC-Adresse in unterschiedlichen Formaten (':' '-') speichern.
  MAC_FORMAT1=""
  for((i=0;i<${#MAC_ADR};i+=2)); do MAC_FORMAT1=$MAC_FORMAT1\\x${MAC_ADR:$i:2}; done

  MAC_FORMAT2=""
  MAC_FORMAT2=${MAC_ADR:0:2}
  for((i=2;i<${#MAC_ADR};i+=2)); do MAC_FORMAT2=$MAC_FORMAT2\:${MAC_ADR:$i:2}; done
fi
}

#-------------------------------------------------------------------------------
# UI: Auswahl der zu verwendenen Freifunkfirmware aus Ordner
#-------------------------------------------------------------------------------
UI_firmware() {
cd "$WORKINGDIRECTORY"
cd "$FIRMWAREDIRECTORY"

FWFILES=$(i=0; for x in $(ls -1 *); do echo $x $x; ((i++)) ; done)
WC=$(echo $FWFILES | wc -w)

if [[ $WC -ne 0 ]]; then
  exec 3>&1
  AUSWAHL=$(dialog  --title "$TITEL" --nocancel --no-tags --default-item "$FIRMWARE"\
             --menu "Basis-Firmware (Sysupgrade)" 19 78 11 ${FWFILES[@]} \
             3>&1 1>&2 2>&3)
  response=$?
  if [[ $response == "255" ]] || [[ $response == "1" ]]; then
    return
  fi
  FIRMWARE=$AUSWAHL

else
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDer Ordner \Zb./$FIRMWAREDIRECTORY\Zn enthält keine Dateien." 8 78
fi
}

#-------------------------------------------------------------------------------
# UI: Zusammenfassung der Einstellungen
#-------------------------------------------------------------------------------
UI_auflistung() {
calc_hwid
dialog --title "$TITEL" --nocancel \
       --form  "Zusammenfassung der Einstellungen" 19 78 11 \
               "Router:"       2 2 "$ROUTER"            2 15 -10 0 \
               "MAC-Adresse:"  3 2 "$MAC_FORMAT2"       3 15 -17 0 \
               "Flash-Größe:"  4 2 "$FLASHSIZE"         4 15  -4 0 \
               "Basis-FW:"     5 2 "${FIRMWARE:0:57}"   5 15 -60 0 \
               ""              6 2 "${FIRMWARE:57:120}" 6 15 -60 0 \
               "Hardware-ID:"  8 2 "${HWID//x/}"        8 15 -32 0 \
               "(berechnet)"   9 2 ""                   9 15 0 0 \
               "Programmer":   11 2 "$FLASHROM_PROGRAMMER_PARAMETER" 11 15 -60 0 \
               3>&1 1>&2 2>&3
}

#-------------------------------------------------------------------------------
# UI: Neuen Flash-Baustein mit Speicherabbild aus Liste beschreiben
#-------------------------------------------------------------------------------
UI_beschreiben() {
cd "$WORKINGDIRECTORY"
cd "$NEWFLASHDIRECTORY"

FLASHFILES=$(i=0; for x in $(ls -1 *); do echo $x $x; ((i++)) ; done)
WC=$(echo $FLASHFILES | wc -w)

if [[ $WC -eq 0 ]]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDer Ordner \Zb./$NEWFLASHDIRECTORY\Zn enthält keine Dateien." 8 78
  return
else
  exec 3>&1
  ABBILD=$(dialog  --title "$TITEL" --cancel-button "Zurück" --no-tags --default-item "$ABBILD"\
                    --menu "Speicherabbilder in ./$NEWFLASHDIRECTORY" 19 78 11 ${FLASHFILES[@]} \
                    3>&1 1>&2 2>&3)

  response=$?
  if [[ $response == "255" ]] || [[ $response == "1" ]]; then
    return
  fi

  if [[ $SUDO_CMD != "" ]] && [[ $PASSWORD == "" ]]; then
    UI_passwort
  fi

  dialog --title "$TITEL" \
         --prgbox "
         echo
         echo Beschreiben des neuen $FLASHSIZE Flash-Bausteins mit dem Inhalt aus
         echo "./$NEWFLASHDIRECTORY/$ABBILD"
         echo
         echo Bitte ca. 5 Minuten warten...
         echo
         echo "$PASSWORD" | $SUDO_CMD flashrom -p $FLASHROM_PROGRAMMER_PARAMETER -w $ABBILD
         echo
         echo Abarbeitung abgeschlossen.
         echo Bitte obige Text-Ausgabe überprüfen!
         " 19 79

fi

}

#-------------------------------------------------------------------------------
# Funktion: Alten Flash-Baustein auslesen und Inhalt abspeichern
#-------------------------------------------------------------------------------
auslesen() {
cd "$WORKINGDIRECTORY"

if [[ $ROUTER == "tbd" ]] || [[ $MAC_ADR == "tbd" ]] || [[ $FLASHSIZE == "tbd" ]]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDas \ZbRoutermodell\Zn, die \ZbMAC-Adresse\Zn und/oder die \ZbFlash-Bausteingröße\Zn wurden noch nicht vorgegeben." 8 78
  return
fi

ROUTERFOLDER="$ROUTER-$MAC_ADR"

if [[ ! -d $FLASHDUMPDIRECTORY/$ROUTERFOLDER ]]; then
  mkdir -p $FLASHDUMPDIRECTORY/$ROUTERFOLDER
fi

cd "$FLASHDUMPDIRECTORY/$ROUTERFOLDER"

if [ -f "$DUMPFILENAME" ]; then
  dialog --title "\Z1Achtung" --yes-label "Ja" --no-label "Nein" --colors \
         --yesno "\nFür diesen Router (\Zb$ROUTER\Zn) mit dieser MAC-Adresse (\Zb$MAC_FORMAT2\Zn) existiert bereits eine Flash-Dump-Datei in \Zb./$FLASHDUMPDIRECTORY/$ROUTERFOLDER\Zn. \
         \n\nÜberschreiben? \
         "  10 78
  response=$?
  case $response in
    1)
        return
        ;;
    255)
        return
        ;;
  esac
fi

if [[ $SUDO_CMD != "" ]] && [[ $PASSWORD == "" ]]; then
 UI_passwort
fi

USER=$(whoami)
dialog --title "$TITEL" \
       --prgbox "
       echo 4MB Flash-Baustein auslesen.
       echo Bitte ca. 1-2 Minuten warten...
       echo
       echo Lesen:
       echo "$PASSWORD" | $SUDO_CMD flashrom -p $FLASHROM_PROGRAMMER_PARAMETER -r $DUMPFILENAME
       echo "$PASSWORD" | $SUDO_CMD chown $USER: "$DUMPFILENAME"
       echo
       echo Verify:
       echo "$PASSWORD" | $SUDO_CMD flashrom -p $FLASHROM_PROGRAMMER_PARAMETER -v $DUMPFILENAME
       echo
       echo Die Dump-Datei wurde abgespeichert als
       echo ./$FLASHDUMPDIRECTORY/$ROUTERFOLDER/$DUMPFILENAME
       echo
       echo Abarbeitung abgeschlossen.
       echo Bitte obige Text-Ausgabe überprüfen!
       " 19 79
}

#-------------------------------------------------------------------------------
# Funktion: Neues Speicherabbild generieren
#-------------------------------------------------------------------------------
erstellen() {
UBOOTFILE="uboot-$ROUTER.bin"
ROUTERFOLDER="$ROUTER-$MAC_ADR"
OUTFILE_MSGBOX="$NEWFLASHDIRECTORY/$ROUTER-$FLASHSIZE-$MAC_ADR.bin"
OUTFILE="$WORKINGDIRECTORY/$OUTFILE_MSGBOX"


cd "$WORKINGDIRECTORY"

if [[ $ROUTER == "tbd" ]] || [[ $MAC_ADR == "tbd" ]] || [[ $FLASHSIZE == "tbd" ]] || [[ $FIRMWARE == "tbd" ]] ; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDas \ZbRoutermodell\Zn, die \ZbMAC-Adresse\Zn, die \ZbFlash-Bausteingröße\Zn und/oder die \ZbBasis-Firmware\Zn wurden noch nicht vorgegeben." 8 78
  return
fi

if [[ ! -f $UBOOTDIRECTORY/$UBOOTFILE ]]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDas U-Boot-Image \Z1./$UBOOTDIRECTORY/$UBOOTFILE\Zn existiert nicht." 8 78
  return
fi

if [[ ! -f $FLASHDUMPDIRECTORY/$ROUTERFOLDER/$DUMPFILENAME ]]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDas Flash-Speicherabbild \Z1./$FLASHDUMPDIRECTORY/$ROUTERFOLDER/$DUMPFILENAME\Zn existiert nicht." 8 78
  return
fi


[[ $FLASHSIZE == "8MB" ]] && COUNT_ZERO=2048 || COUNT_ZERO=4096
[[ $FLASHSIZE == "8MB" ]] && SEEK_ART=2032 || SEEK_ART=4080

calc_hwid

cd $FLASHDUMPDIRECTORY/$ROUTERFOLDER
cp  ../../$UBOOTDIRECTORY/$UBOOTFILE uboot.bin
cp  ../../$FIRMWAREDIRECTORY/$FIRMWARE gluonsysupgrade.bin
dd ibs=4k skip=1008 if=$DUMPFILENAME of=artdump.bin
dd if=/dev/zero ibs=4k count=$COUNT_ZERO | LANG=C tr "\000" "\377" > "$OUTFILE"
dd conv=notrunc obs=4k seek=$SEEK_ART if=artdump.bin of="$OUTFILE"
dd conv=notrunc  if=uboot.bin of="$OUTFILE"
dd conv=notrunc obs=4k seek=32 if=gluonsysupgrade.bin of="$OUTFILE"
printf $MAC_FORMAT1 | dd conv=notrunc ibs=1 obs=256 seek=508 count=8 of="$OUTFILE"
printf $HWID | dd conv=notrunc ibs=1 obs=256 seek=509 count=8 of="$OUTFILE"
echo "sync"
echo "wait..."
sync
dialog --title "$TITEL" --colors\
       --msgbox "\nDas generierte $FLASHSIZE Flash-Speicherabbild wurde abgespeichert als\n\Zb./$OUTFILE_MSGBOX\Zn" 18 79

}

#-------------------------------------------------------------------------------
# Funktion: Neuen Flash-Baustein mit generiertem Speicherabbild beschreiben
#-------------------------------------------------------------------------------
beschreiben() {
cd "$WORKINGDIRECTORY"
cd "$NEWFLASHDIRECTORY"
INFILE_MSGBOX="$NEWFLASHDIRECTORY/$ROUTER-$FLASHSIZE-$MAC_ADR.bin"
INFILE="$WORKINGDIRECTORY/$INFILE_MSGBOX"

if [[ $ROUTER == "tbd" ]] || [[ $MAC_ADR == "tbd" ]] || [[ $FLASHSIZE == "tbd" ]]; then
  dialog --title "\Z1Fehler" --colors \
         --msgbox "\nDas \ZbRoutermodell\Zn, die \ZbMAC-Adresse\Zn und/oder die \ZbFlash-Bausteingröße\Zn wurden noch nicht vorgegeben." 8 78
  return
fi

if [ ! -f "$INFILE" ]; then
  dialog --title "\Z1Fehler" --yes-label "Ja" --no-label "Nein" --colors \
         --msgbox "\nFür diesen Router (\Zb$ROUTER\Zn) mit dieser MAC-Adresse (\Zb$MAC_FORMAT2\Zn) wurde kein \Zb$FLASHSIZE\Zn Speicherabbild gefunden (\Zb./$INFILE_MSGBOX\Zn)."  8 78
  return
fi

if [[ $SUDO_CMD != "" ]] && [[ $PASSWORD == "" ]]; then
  UI_passwort
fi

  dialog --title "$TITEL" \
         --prgbox "
         echo
         echo Beschreiben des neuen $FLASHSIZE Flash-Bausteins mit
         echo ./$INFILE_MSGBOX
         echo
         echo Bitte ca. 5 Minuten warten...
         echo
         echo "$PASSWORD" | $SUDO_CMD flashrom -p $FLASHROM_PROGRAMMER_PARAMETER -w $INFILE
         echo
         echo Abarbeitung abgeschlossen.
         echo Bitte obige Text-Ausgabe überprüfen!
         " 19 79
}


#-------------------------------------------------------------------------------
# Funktion:Download der U-Bootloader-Images von http://derowe.com
#-------------------------------------------------------------------------------
download() {
cd "$WORKINGDIRECTORY"
if [[ ! -d "$UBOOTDIRECTORY" ]]; then
  mkdir "$UBOOTDIRECTORY"
fi
cd "$UBOOTDIRECTORY"
   dialog --title "$TITEL" --colors\
          --prgbox '\
          echo tl-wr841n-v8:
          $(wget -nv -O uboot-wr841n-v8.bin http://derowe.com/u-boot/stable/tp-link-tl-wr841n-v8.bin;)
          echo tl-wr841n-v9:
          $(wget -nv -O uboot-wr841n-v9.bin http://derowe.com/u-boot/stable/tp-link-tl-wr841n-v9.bin;)
          echo tl-wr841n-v10:
          $(wget -nv -O uboot-wr841n-v10.bin http://derowe.com/u-boot/stable/tp-link-tl-wr841n-v10.bin;)
          echo tl-wr841n-v11:
          $(wget -nv -O uboot-wr841n-v11.bin http://derowe.com/u-boot/stable/tp-link-tl-wr841n-v11.bin;)
          echo
          echo Die U-Boot Bootloader wurden gespeichert in:
          echo $(pwd)
          ' 19 79 3>&1 1>&2 2>&3
}

#-------------------------------------------------------------------------------
# Funktion: Test, ob der Flashbaustein elektrisch korrekt kontaktiert ist
#-------------------------------------------------------------------------------
linktest() {
if [[ $SUDO_CMD != "" ]] && [[ $PASSWORD == "" ]]; then
  UI_passwort
fi

dialog --title "$TITEL" \
       --prgbox "
       echo Bitte warten...
       echo
       echo $PASSWORD | $SUDO_CMD flashrom -p $FLASHROM_PROGRAMMER_PARAMETER
       echo
       echo Abarbeitung abgeschlossen.
       echo Bitte obige Text-Ausgabe überprüfen!
       " 19 79
}

#-------------------------------------------------------------------------------
# Funktion: Bestimmung der HW-ID. Es werden die HWIDs vom Gluon-Patch verwendet
#-------------------------------------------------------------------------------
calc_hwid() {
if [[ $FLASHSIZE == "8MB" ]]; then
  [[ $ROUTER == "wr841n-v8" ]]  && HWID='\x08\x41\x08\x08\x00\x00\x00\x01'
  [[ $ROUTER == "wr841n-v9" ]]  && HWID='\x08\x41\x08\x09\x00\x00\x00\x01'
  [[ $ROUTER == "wr841n-v10" ]] && HWID='\x08\x41\x08\x10\x00\x00\x00\x01'
  [[ $ROUTER == "wr841n-v11" ]] && HWID='\x08\x41\x08\x11\x00\x00\x00\x01'
elif [[ $FLASHSIZE == "16MB" ]]; then
  [[ $ROUTER == "wr841n-v8" ]]  && HWID='\x08\x41\x16\x08\x00\x00\x00\x01'
  [[ $ROUTER == "wr841n-v9" ]]  && HWID='\x08\x41\x16\x09\x00\x00\x00\x01'
  [[ $ROUTER == "wr841n-v10" ]] && HWID='\x08\x41\x16\x10\x00\x00\x00\x01'
  [[ $ROUTER == "wr841n-v11" ]] && HWID='\x08\x41\x16\x11\x00\x00\x00\x01'
else
  HWID="tbd"
fi
}

#-------------------------------------------------------------------------------
# Funktion: Router-Parameter zurücksetzen.
#-------------------------------------------------------------------------------
reset_param() {
MAC_ADR="tbd"
MAC_FORMAT1="tbd"
MAC_FORMAT2="tbd"
ROUTER="tbd"
FLASHSIZE="tbd"
FIRMWARE="tbd"

dialog --title "\Z1Hinweis" --colors \
         --msgbox "\nAlle Router-spezifische Parameter wurden zurückgesetzt." 8 78
}

#-------------------------------------------------------------------------------
# Skript Abarbeitung
#-------------------------------------------------------------------------------
while [ 1 ]
do
  UI_hauptmenue
done
