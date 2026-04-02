#!/bin/bash

# Sprachsteuerung (i18n)
case "${LANG:0:2}" in
    de)
        STR_ERR_PANDOC_TITLE="Fehler: Pandoc nicht gefunden"
        STR_ERR_PANDOC_BODY="Pandoc ist nicht installiert. Bitte installieren Sie es mit 'sudo apt install pandoc'."
        STR_ERR_MIXED_TITLE="Fehler: Gemischte Auswahl"
        STR_ERR_MIXED_BODY="Sie haben Dateien mit unterschiedlichen Typen ausgewählt.\n\nBitte wählen Sie nur Dateien des gleichen Typs aus (z.B. nur Markdown-Dateien)."
        STR_HINT_PDF_TITLE="Hinweis: PDF-Konvertierung"
        STR_HINT_PDF_BODY="XeLaTeX ist nicht installiert. Die PDF-Option wird ausgeblendet.\n\nInstallation:\nsudo apt install texlive-xetex texlive-fonts-recommended"
        STR_HINT_LO_TITLE="Hinweis: LibreOffice"
        STR_HINT_LO_BODY="LibreOffice wurde nicht gefunden. Dies wird für die Bearbeitung von DOCX/ODT Dateien empfohlen.\n\nInstallation:\nsudo apt install libreoffice"
        STR_HINT_IM_TITLE="Hinweis: Bild-Konvertierung"
        STR_HINT_IM_BODY="ImageMagick ist nicht installiert. Bild-Optionen werden ausgeblendet.\n\nInstallation:\nsudo apt install imagemagick"
        STR_WARN_NO_CONV="Keine gemeinsame Konvertierung für die gewählten Dateitypen verfügbar."
        STR_DLG_TITLE="Konvertierung für $# Dateien"
        STR_DLG_TEXT="Wählen Sie das Zielformat für alle Dateien:"
        STR_PROG_TITLE="Konvertierung läuft"
        STR_PROG_TEXT="Vorbereitung..."
        STR_FINAL_ERR="Die folgenden Dateien konnten nicht konvertiert werden:"
        STR_FINAL_SUCCESS="Alle Dateien wurden erfolgreich konvertiert."
        
        DESC_MD_ODT="Markdown zu LibreOffice ODT"
        DESC_MD_DOCX="Markdown zu Word DOCX"
        DESC_MD_HTML="Markdown zu HTML"
        DESC_MD_PDF="Markdown zu PDF (via XeLaTeX)"
        DESC_CSV_ODT="CSV zu LibreOffice ODT (als Tabelle)"
        DESC_HTML_MD="HTML zu Markdown"
        DESC_ODT_MD="LibreOffice ODT zu Markdown"
        DESC_PNG_JPG="PNG zu JPG"
        DESC_JPG_PNG="JPG zu PNG"
        DESC_IMG_WEBP="Bild zu WebP"
        ;;
    *)
        STR_ERR_PANDOC_TITLE="Error: Pandoc not found"
        STR_ERR_PANDOC_BODY="Pandoc is not installed. Please install it with 'sudo apt install pandoc'."
        STR_ERR_MIXED_TITLE="Error: Mixed Selection"
        STR_ERR_MIXED_BODY="You have selected files with different types.\n\nPlease select only files of the same type (e.g., only Markdown files)."
        STR_HINT_PDF_TITLE="Hint: PDF Conversion"
        STR_HINT_PDF_BODY="XeLaTeX is not installed. The PDF option will be hidden.\n\nInstallation:\nsudo apt install texlive-xetex texlive-fonts-recommended"
        STR_HINT_LO_TITLE="Hint: LibreOffice"
        STR_HINT_LO_BODY="LibreOffice was not found. This is recommended for DOCX/ODT files.\n\nInstallation:\nsudo apt install libreoffice"
        STR_HINT_IM_TITLE="Hint: Image Conversion"
        STR_HINT_IM_BODY="ImageMagick is not installed. Image options will be hidden.\n\nInstallation:\nsudo apt install imagemagick"
        STR_WARN_NO_CONV="No common conversion available for the selected file types."
        STR_DLG_TITLE="Conversion for $# files"
        STR_DLG_TEXT="Select the target format for all files:"
        STR_PROG_TITLE="Conversion in progress"
        STR_PROG_TEXT="Preparing..."
        STR_FINAL_ERR="The following files could not be converted:"
        STR_FINAL_SUCCESS="All files were successfully converted."

        DESC_MD_ODT="Markdown to LibreOffice ODT"
        DESC_MD_DOCX="Markdown to Word DOCX"
        DESC_MD_HTML="Markdown to HTML"
        DESC_MD_PDF="Markdown to PDF (via XeLaTeX)"
        DESC_CSV_ODT="CSV to LibreOffice ODT (as table)"
        DESC_HTML_MD="HTML to Markdown"
        DESC_ODT_MD="LibreOffice ODT to Markdown"
        DESC_PNG_JPG="PNG to JPG"
        DESC_JPG_PNG="JPG to PNG"
        DESC_IMG_WEBP="Image to WebP"
        ;;
esac

# Überprüfen, ob pandoc installiert ist
if ! command -v pandoc &> /dev/null; then
    zenity --error --text="$STR_ERR_PANDOC_BODY" --title="$STR_ERR_PANDOC_TITLE"
    exit 1
fi

# 1. Alle vorkommenden Dateiendungen sammeln und auf Einheitlichkeit prüfen
extensions=()
for f in "$@"; do
    ext="${f##*.}"
    ext="${ext,,}"
    
    # Normalisierung: Behandle md/markdown und jpg/jpeg als identisch für diese Prüfung
    check_ext="$ext"
    [[ "$ext" == "markdown" ]] && check_ext="md"
    [[ "$ext" == "jpeg" ]] && check_ext="jpg"
    
    # Eindeutige Endungen sammeln
    found=false
    for e in "${extensions[@]}"; do
        [[ "$e" == "$check_ext" ]] && found=true && break
    done
    [[ "$found" == "false" ]] && extensions+=("$check_ext")
done

# Wenn mehr als ein Grundtyp ausgewählt wurde, abbrechen
if [ ${#extensions[@]} -gt 1 ]; then
    zenity --error --title="$STR_ERR_MIXED_TITLE" \
        --text="$STR_ERR_MIXED_BODY" \
        --width=400
    exit 1
fi

# Abhängigkeiten prüfen
HAS_XELATEX=$(command -v xelatex &> /dev/null && echo true || echo false)
HAS_LIBREOFFICE=$(command -v libreoffice &> /dev/null && echo true || echo false)
HAS_IMAGEMAGICK=$(command -v convert &> /dev/null && echo true || echo false)

# Gezielte Hinweise geben
NEED_PDF_HINT=false
NEED_LO_HINT=false
NEED_IM_HINT=false

for ext in "${extensions[@]}"; do
    # Falls Markdown markiert ist, aber XeLaTeX fehlt
    [[ "$HAS_XELATEX" == "false" && "$ext" == "md" ]] && NEED_PDF_HINT=true
    # Falls Office-Formate markiert sind, aber LibreOffice fehlt
    [[ "$HAS_LIBREOFFICE" == "false" && ("$ext" == "odt" || "$ext" == "docx") ]] && NEED_LO_HINT=true
    # Falls Bilder markiert sind, aber ImageMagick fehlt
    [[ "$HAS_IMAGEMAGICK" == "false" && ("$ext" == "png" || "$ext" == "jpg" || "$ext" == "webp") ]] && NEED_IM_HINT=true
done

if [ "$NEED_PDF_HINT" = true ]; then
    zenity --info --title="$STR_HINT_PDF_TITLE" \
        --text="$STR_HINT_PDF_BODY" --width=450
fi

if [ "$NEED_LO_HINT" = true ]; then
    zenity --info --title="$STR_HINT_LO_TITLE" \
        --text="$STR_HINT_LO_BODY" --width=450
fi

if [ "$NEED_IM_HINT" = true ]; then
    zenity --info --title="$STR_HINT_IM_TITLE" \
        --text="$STR_HINT_IM_BODY" --width=450
fi

# Funktion zur Durchführung der Konvertierung
convert_file() {
    local input_file="$1"
    local output_format="$2"
    local output_extension="$3"
    local pandoc_options="$4"
    local opt_id="$5"

    local filename="${input_file%.*}"
    local output_file="${filename}.${output_extension}"

    # Konvertierung durchführen und Fehlermeldungen (stderr) abfangen
    local error_output
    if [[ "$opt_id" == img-* ]]; then
        error_output=$(convert -- "$input_file" "$output_file" 2>&1)
    else
        error_output=$(pandoc -s -- "$input_file" -o "$output_file" $pandoc_options 2>&1)
    fi
    local status=$?
    
    # Wenn ein Fehler auftrat, die Meldung zurückgeben
    [ $status -ne 0 ] && echo "$error_output"
    return $status
}

# Liste der verfügbaren Konvertierungsoptionen für das Zenity-Menü
# Jede Zeile: <Option-ID> <Beschreibung> <Input-Typ(en)> <Output-Format> <Output-Extension> <Pandoc-Optionen>
# Wir verwenden '|' als Trenner, um Probleme mit Leerzeichen in Beschreibungen zu vermeiden.
options=(
    "md-to-odt|$DESC_MD_ODT|md markdown|odt|odt|"
    "md-to-docx|$DESC_MD_DOCX|md markdown|docx|docx|"
    "md-to-html|$DESC_MD_HTML|md markdown|html|html|"
    "md-to-pdf|$DESC_MD_PDF|md markdown|pdf|pdf|--pdf-engine=xelatex"
    "csv-to-odt|$DESC_CSV_ODT|csv|odt|odt|--to=markdown --wrap=none --markdown-headings=atx --standalone"
    "html-to-md|$DESC_HTML_MD|html htm|md|md|"
    "odt-to-md|$DESC_ODT_MD|odt|md|md|"
    "img-png-to-jpg|$DESC_PNG_JPG|png|jpg|jpg|"
    "img-jpg-to-png|$DESC_JPG_PNG|jpg jpeg|png|png|"
    "img-to-webp|$DESC_IMG_WEBP|png jpg jpeg webp|webp|webp|"
)

# 2. Menüoptionen filtern (nur Optionen, die für ALLE markierten Endungen gültig sind)
dialog_options=()
first_match=true
for row in "${options[@]}"; do
    IFS='|' read -r opt_id opt_desc opt_inputs opt_out_fmt opt_out_ext opt_p_opts <<< "$row"

    # Abhängigkeiten prüfen
    [[ "$opt_id" == "md-to-pdf" && "$HAS_XELATEX" == "false" ]] && continue
    [[ "$opt_id" == "odt-to-md" && "$HAS_LIBREOFFICE" == "false" ]] && continue
    [[ "$opt_id" == img-* && "$HAS_IMAGEMAGICK" == "false" ]] && continue

    all_supported=true
    for ext in "${extensions[@]}"; do
        supported=false
        for type in $opt_inputs; do
            [[ "$ext" == "$type" ]] && supported=true && break
        done
        if [ "$supported" = false ]; then
            all_supported=false
            break
        fi
    done

    if [ "$all_supported" = true ]; then
        [ "$first_match" = true ] && dialog_options+=("TRUE") || dialog_options+=("FALSE")
        first_match=false
        dialog_options+=("$opt_id" "$opt_desc")
    fi
done

if [ ${#dialog_options[@]} -eq 0 ]; then
     zenity --warning --text="$STR_WARN_NO_CONV" --title="Abbruch"
     exit 1
fi

# 3. Einmalige Abfrage des Formats
selected_option=$(zenity --list \
    --title="$STR_DLG_TITLE" \
    --text="$STR_DLG_TEXT" \
    --radiolist --column="Auswählen" --column="ID" --column="Beschreibung" \
    --print-column=2 --hide-column=2 \
    "${dialog_options[@]}" \
    --cancel-label="Abbrechen" --width=450 --height=300)

[ $? -ne 0 ] || [ -z "$selected_option" ] && exit 0

# Details für die gewählte Option extrahieren
for row in "${options[@]}"; do
    IFS='|' read -r opt_id opt_desc opt_inputs opt_out_fmt opt_out_ext opt_p_opts <<< "$row"
    [[ "$opt_id" == "$selected_option" ]] && break
done

# 4. Alle Dateien konvertieren
TOTAL_FILES=$#
CURRENT=0
ERROR_LOG=$(mktemp)

# Sicherstellen, dass Dateien vorhanden sind (verhindert Division durch Null)
[[ $TOTAL_FILES -eq 0 ]] && exit 0

(
for input_file in "$@"; do
    printf "# Konvertiere: %s\n" "${input_file##*/}"
    
    if ! error_msg=$(convert_file "$input_file" "$opt_out_fmt" "$opt_out_ext" "$opt_p_opts" "$opt_id"); then
        printf "DATEI: %s\n" "${input_file##*/}" >> "$ERROR_LOG"
        printf "FEHLER: %s\n" "$error_msg" >> "$ERROR_LOG"
        echo "-------------------------------------------" >> "$ERROR_LOG"
    fi

    CURRENT=$((CURRENT + 1))
    echo $((CURRENT * 100 / TOTAL_FILES))
done
) | zenity --progress --title="$STR_PROG_TITLE" --text="$STR_PROG_TEXT" --percentage=0 --auto-close

# Zusammenfassung am Ende anzeigen
if [ -s "$ERROR_LOG" ]; then
    ERRORS=$(cat "$ERROR_LOG")
    zenity --error --title="Abgeschlossen mit Fehlern" \
        --text="$STR_FINAL_ERR\n\n$ERRORS"
elif [ "$TOTAL_FILES" -gt 0 ]; then
    zenity --info --title="OK" --text="$STR_FINAL_SUCCESS"
fi

# Temporäre Datei löschen
rm -f "$ERROR_LOG"
