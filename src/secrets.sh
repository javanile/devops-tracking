
# Funzione per processare la variabile DEVOPS_TRACKING_SECRETS
process_secrets() {
    # Leggi la variabile DEVOPS_TRACKING_SECRETS
    local secrets="$DEVOPS_TRACKING_SECRETS"
    local section=${1:-default}

    # Variabili di stato per il loop
    local current_file=""
    local current_content=""

    # Leggi riga per riga e processa
    while IFS= read -r line; do
        # Verifica se la riga inizia con "@[", cioè indica un nuovo file
        if [[ "$line" =~ ^@\[(.*)\]$ ]]; then
            # Se c'è un file precedente, salvalo
            if [[ -n "$current_file" ]] && [[ "$current_file" = "$section" ]]; then
                echo "$current_content"
            fi

            # Estrai il percorso del nuovo file e resetta il contenuto
            current_file=$(echo "$line" | sed 's/@\[//;s/\]//')
            current_content=""
        else
            # Aggiungi il contenuto alla variabile del file corrente
            current_content+="$line"$'\n'
        fi
    done <<< "$secrets"

    # Salva l'ultimo file
    if [[ -n "$current_file" ]] && [[ "$current_file" = "$section" ]]; then
        echo "$current_content"
    fi
}

