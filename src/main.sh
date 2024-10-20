
module secrets

main() {
#!/bin/bash

# Esempio di chiamata alla funzione
process_secrets
event=$1

# Imposta la variabile del file JSON della chiave dell'account di servizio
PRIVATE_KEY_FILE="${HOME}/.google/service_account.json"  # La chiave JSON scaricata


if [ -f "${PRIVATE_KEY_FILE}" ]; then
google_service_account="$(cat $PRIVATE_KEY_FILE)"
else
google_service_account="$(process_secrets google_service_account)"
fi

# Estrai l'email dell'account di servizio e la chiave privata dal file JSON
SERVICE_ACCOUNT_EMAIL=$(echo "${google_service_account}" | jq -r '.client_email' -)
PRIVATE_KEY=$(echo "${google_service_account}" | jq -r '.private_key' -)

# Imposta variabili per Google API e Google Sheet
SPREADSHEET_ID="1hAgyGmD8NUYidBbmCVe8MXpHQGwvKJTtrpPafiizFFw"
RANGE="Tracking!A1"  # Range dove inserire la riga

# Genera un JWT firmato per ottenere un access token
header=$(echo -n '{"alg":"RS256","typ":"JWT"}' | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
claim_set=$(echo -n '{"iss":"'$SERVICE_ACCOUNT_EMAIL'","scope":"https://www.googleapis.com/auth/spreadsheets","aud":"https://oauth2.googleapis.com/token","exp":'$(($(date +%s)+3600))',"iat":'$(date +%s)'}' | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')
signature=$(echo -n "$header.$claim_set" | openssl dgst -sha256 -sign <(echo -n "$PRIVATE_KEY") | openssl base64 -e | tr -d '=' | tr '/+' '_-' | tr -d '\n')

# Componi il token JWT
jwt="$header.$claim_set.$signature"

# Richiedi il token di accesso
ACCESS_TOKEN=$(curl -s --request POST \
  --url "https://oauth2.googleapis.com/token" \
  --header "Content-Type: application/x-www-form-urlencoded" \
  --data "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=$jwt" | jq -r '.access_token')

datetime=$(date +'%F %T')

if [ -n "${GITHUB_REPOSITORY}" ]; then
repository="https://github.com/${GITHUB_REPOSITORY}"
else
repository=$(git config --get remote.origin.url && true)
fi

# Prepara i dati da inserire
DATA='{
  "range": "'$RANGE'",
  "majorDimension": "ROWS",
  "values": [
    ["'$datetime'", "'$repository'", "'$event'"]
  ]
}'

# Invia la richiesta all'API di Google Sheets per aggiungere una riga
curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "$DATA" \
  "https://sheets.googleapis.com/v4/spreadsheets/$SPREADSHEET_ID/values/$RANGE:append?valueInputOption=USER_ENTERED"

}
