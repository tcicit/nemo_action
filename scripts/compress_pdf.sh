#!/bin/bash

# Sprachsteuerung (i18n)
case "${LANG:0:2}" in
    de)
        STR_ERR_GS_TITLE="Fehler: Ghostscript fehlt"
        STR_ERR_GS_BODY="Ghostscript (gs) ist nicht installiert. Dieses Programm wird für die PDF-Kompression benötigt.\n\nInstallation:\nsudo apt update && sudo apt install ghostscript"
        STR_DLG_TITLE="PDF-Kompression"
        STR_DLG_TEXT="Wählen Sie die Kompressionsqualität:"
        STR_COL_SEL="Auswählen"
        STR_COL_QUAL="Qualität"
        STR_COL_DESC="Beschreibung"
        STR_PROG_TITLE="PDF-Kompression läuft"
        STR_PROG_TEXT="Vorbereitung..."
        STR_FINAL_ERR="Die folgenden Dateien konnten nicht komprimiert werden:"
        STR_FINAL_SUCCESS="Alle PDFs wurden erfolgreich komprimiert."
        
        DESC_PRINTER="Hohe Qualität. Geeignet für den Druck."
        DESC_EBOOK="Gute Qualität bei geringer Dateigrösse. Geeignet für E-Books."
        DESC_SCREEN="Minimale Dateigrösse, niedrige Qualität. Geeignet für die Anzeige auf Bildschirmen."
        DESC_PREPRESS="Maximale Qualität und Dateigrösse. Geeignet für den professionellen Druck."
        DESC_DEFAULT="Standardkompression. Gute Balance zwischen Qualität und Dateigrösse."
        ;;
    *)
        STR_ERR_GS_TITLE="Error: Ghostscript missing"
        STR_ERR_GS_BODY="Ghostscript (gs) is not installed. This program is required for PDF compression.\n\nInstallation:\nsudo apt update && sudo apt install ghostscript"
        STR_DLG_TITLE="PDF Compression"
        STR_DLG_TEXT="Select compression quality:"
        STR_COL_SEL="Select"
        STR_COL_QUAL="Quality"
        STR_COL_DESC="Description"
        STR_PROG_TITLE="PDF Compression in progress"
        STR_PROG_TEXT="Preparing..."
        STR_FINAL_ERR="The following files could not be compressed:"
        STR_FINAL_SUCCESS="All PDFs were successfully compressed."

        DESC_PRINTER="High quality. Suitable for printing."
        DESC_EBOOK="Good quality with small file size. Suitable for E-Books."
        DESC_SCREEN="Minimal file size, low quality. Suitable for screen display."
        DESC_PREPRESS="Maximum quality and file size. Suitable for professional printing."
        DESC_DEFAULT="Standard compression. Good balance between quality and size."
        ;;
esac

# Überprüfen, ob Ghostscript installiert ist
if ! command -v gs &> /dev/null; then
    zenity --error --title="$STR_ERR_GS_TITLE" \
        --text="$STR_ERR_GS_BODY"
    exit 1
fi

# Funktion zur Anzeige des Dialogs für die Auswahl der Kompressionsqualität
select_quality() {
    QUALITY=$(zenity --list --radiolist --title="$STR_DLG_TITLE" \
        --width=600 --height=300 \
        --text="$STR_DLG_TEXT" \
        --column="$STR_COL_SEL" --column="$STR_COL_QUAL" --column="$STR_COL_DESC" \
        TRUE "printer" "$DESC_PRINTER" \
        FALSE "ebook" "$DESC_EBOOK" \
        FALSE "screen" "$DESC_SCREEN" \
        FALSE "prepress" "$DESC_PREPRESS" \
        FALSE "default" "$DESC_DEFAULT")

    echo "$QUALITY"
}

# Kompressionsqualität auswählen
QUALITY=$(select_quality)

# Prüfen, ob der Benutzer abgebrochen hat (Zenity Exit-Status != 0)
if [ $? -ne 0 ] || [ -z "$QUALITY" ]; then
    exit 1
fi

TOTAL_FILES=$#
CURRENT=0
ERROR_LOG=$(mktemp)

# Sicherstellen, dass Dateien vorhanden sind (verhindert Division durch Null)
[[ $TOTAL_FILES -eq 0 ]] && exit 0

# Alle Dateien verarbeiten
(
for INPUT_PDF in "$@"; do
    # Fortschrittsbalken aktualisieren
    printf "# Komprimiere: %s\n" "${INPUT_PDF##*/}"
    
    # Ausgabe-PDF-Datei
    OUTPUT_PDF="${INPUT_PDF%.*}_compressed.pdf"

    # PDF komprimieren
    gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS="/$QUALITY" \
       -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$OUTPUT_PDF" -- "$INPUT_PDF"

    if [ $? -ne 0 ]; then
        printf "%s\n" "${INPUT_PDF##*/}" >> "$ERROR_LOG"
    fi

    CURRENT=$((CURRENT + 1))
    echo $((CURRENT * 100 / TOTAL_FILES))
done
) | zenity --progress --title="$STR_PROG_TITLE" --text="$STR_PROG_TEXT" --percentage=0 --auto-close

# Zusammenfassung anzeigen
if [ -s "$ERROR_LOG" ]; then
    ERRORS=$(cat "$ERROR_LOG")
    zenity --error --title="Abgeschlossen mit Fehlern" \
        --text="$STR_FINAL_ERR\n\n$ERRORS"
elif [ "$TOTAL_FILES" -gt 0 ]; then
    zenity --info --title="OK" --text="$STR_FINAL_SUCCESS"
fi

# Temporäre Datei löschen
rm -f "$ERROR_LOG"
