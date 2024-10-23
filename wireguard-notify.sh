#!/bin/bash

# Activer le verbose de l'application pour la debugguer
DEBUG=false

# URL du webhook Home Assistant
WEBHOOK_URL="http://homeassistant.local:8123/api/webhook/WEBHOOKID"
# Fichier contenant les noms des clients et leurs cles publiques
CLIENTS_FILE="/etc/wireguard/configs/clients.txt"
# Delai de verification
DELAY=5

[[ "$DEBUG" == true ]] && echo "[debug]" "Lancer (ou relancer) une connexion WireGuard pour déclencher la notification..."

# Fonction represantant la commande pour surveiller les connexions WireGuard
check_connections() {
    # Obtenir les endpoints des clients
    wg show wg0 endpoints
}

# Fonction pour recuperer le nom du client a partir de sa cle publique
get_client_name() {
    local client_pub_key="$1"

    # Rechercher le nom associe a la cle publique dans clients.txt
    client_name=$(grep " $client_pub_key" "$CLIENTS_FILE" | awk '{print $1}')

    if [[ -z "$client_name" ]]; then
        echo "null"
        return 1
    fi

    echo ${client_name}
}

# Fonction pour envoyer une notification a Home Assistant
send_notification() {
    client_ip=$1
    client_name=$(get_client_name $2)
    client_ipinfo="http://ipinfo.io/"$client_ip

    [[ "$DEBUG" == true ]] && echo "[notif]" $client_ip
    [[ "$DEBUG" == true ]] && echo "[notif]" $client_name
    [[ "$DEBUG" == true ]] && echo "[notif]" $client_ipinfo

    curl -X POST $WEBHOOK_URL -H "Content-Type: application/json" \
       -d "{ \"message\": \"Nouvelle connexion WireGuard detectee\", \"client_ip\": \"$client_ip\", \"client_ipinfo\": \"$client_ipinfo\", \"client_name\": \"$client_name\" }"
}

# Initialiser une variable pour stocker les connexions precedentes
previous_endpoints=$(check_connections)

# Boucle pour surveiller les connexions
while true; do
    current_endpoints=$(check_connections)

    # Comparer les endpoints actuels avec ceux precedemment enregistres
    if [ "$current_endpoints" != "$previous_endpoints" ]; then
        # Identifier les nouvelles connexions
        new_connections=$(diff <(echo "$previous_endpoints") <(echo "$current_endpoints") | grep ">" | awk '{print $2, $3}')

        [[ "$DEBUG" == true ]] && echo "[diff]" $(diff <(echo "$previous_endpoints") <(echo "$current_endpoints"))
        [[ "$DEBUG" == true ]] && echo "[diff]" $(diff <(echo "$previous_endpoints") <(echo "$current_endpoints") | grep ">" | awk '{print $2, $3}')
        [[ "$DEBUG" == true ]] && echo "[new_connections]" "$new_connections"

        client_pubkey=$(echo $new_connections | awk '{print $1}')
        client_ip=$(echo $new_connections | awk '{print $2}' | cut -d':' -f1)

        [[ "$DEBUG" == true ]] && echo "[debug] ip : " $client_ip
        [[ "$DEBUG" == true ]] && echo "[debug] key : " $client_pubkey

        # Déclencher la fonction de notification
        send_notification $client_ip $client_pubkey

        # Mettre a jour les connexions precedentes
        previous_endpoints=$current_endpoints
    fi

    # Attendre quelques secondes avant de verifier a nouveau
    sleep $DELAY
done
