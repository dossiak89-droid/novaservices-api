#!/usr/bin/env bash
# Exécuté SUR LA VM (envoyé par SSH depuis le workflow).
# Variables reçues : IMAGE, DIGEST, COMMIT, SIMULATE_FAILURE (optionnelle)
set -euo pipefail

: "${IMAGE:?IMAGE manquante}" "${DIGEST:?DIGEST manquant}" "${COMMIT:?COMMIT manquant}"

NAME="application-tp"
HOST_PORT="${HOST_PORT:-8080}"
STATE_DIR="$HOME/deploy"
CURRENT_FILE="$STATE_DIR/current_image"     # version actuellement en service
PREVIOUS_FILE="$STATE_DIR/previous_image"   # version précédente (pour le rollback)
NEW_IMAGE="${IMAGE}@${DIGEST}"

mkdir -p "$STATE_DIR"

# Attend que /health réponde 200, puis (si demandé) que /version contienne le commit.
attendre_service() {
  local commit_attendu="${1:-}"
  for _ in $(seq 1 30); do
    if curl -fsS "http://localhost:${HOST_PORT}/health" > /dev/null 2>&1; then
      if [ -z "$commit_attendu" ]; then
        return 0
      fi
      if curl -fsS "http://localhost:${HOST_PORT}/version" | grep -q "$commit_attendu"; then
        return 0
      fi
    fi
    sleep 2
  done
  return 1
}

demarrer() {
  local image="$1"; shift
  docker rm -f "$NAME" > /dev/null 2>&1 || true
  docker run -d --name "$NAME" --restart unless-stopped \
    -p "${HOST_PORT}:8000" "$@" "$image"
}

echo "==> Récupération de l'image validée : $NEW_IMAGE"
docker pull "$NEW_IMAGE"

# Option réservée au TP : simuler une panne de la nouvelle version
EXTRA=()
if [ "${SIMULATE_FAILURE:-}" = "true" ]; then
  echo "!! Simulation d'échec activée (FAIL_HEALTH=1)"
  EXTRA=(-e FAIL_HEALTH=1)
fi

echo "==> Démarrage de la nouvelle version"
demarrer "$NEW_IMAGE" "${EXTRA[@]}"

if attendre_service "$COMMIT"; then
  echo "==> Succès : version $COMMIT en service"
  [ -f "$CURRENT_FILE" ] && cp "$CURRENT_FILE" "$PREVIOUS_FILE"
  echo "$NEW_IMAGE" > "$CURRENT_FILE"
  exit 0
fi

echo "!! Échec du contrôle HTTP. Journaux du conteneur :"
docker logs "$NAME" || true

if [ -f "$CURRENT_FILE" ]; then
  OLD_IMAGE="$(cat "$CURRENT_FILE")"
  echo "==> Retour arrière vers : $OLD_IMAGE"
  demarrer "$OLD_IMAGE"
  if attendre_service ""; then
    echo "==> Service rétabli avec la version précédente"
  else
    echo "!! Le retour arrière a aussi échoué : intervention manuelle nécessaire"
  fi
else
  echo "!! Aucune version précédente connue : pas de retour arrière possible"
fi

# On termine en échec pour que le job reste rouge et garde son diagnostic.
exit 1
