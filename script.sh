#!/bin/sh

# Récupérer le paramètre
PARAM="$1"

echo "Le script s'exécute avec le paramètre : $PARAM"

# Exemple d'utilisation du paramètre
case "$PARAM" in
    install)
        echo "Installation en cours..."
        # Ajoute ici les commandes d'installation
        ;;
    update)
        echo "Mise à jour en cours..."
        # Ajoute ici les commandes de mise à jour
        ;;
    *)
        echo "Usage: script.sh [install|update]"
        exit 1
        ;;
esac
