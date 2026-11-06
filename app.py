import os

from flask import Flask, jsonify

app = Flask(__name__)

# Ces deux valeurs sont injectées par le Dockerfile (le commit Git).
VERSION = os.getenv("APP_VERSION", "dev")
COMMIT = os.getenv("GIT_COMMIT", "local")

# Données fictives (périmètre court, comme demandé dans le TP).
TICKETS = [
    {"id": 1, "titre": "Imprimante du 2e étage en panne", "statut": "ouvert"},
    {"id": 2, "titre": "Demande de compte VPN", "statut": "en_cours"},
    {"id": 3, "titre": "Écran noir sur le PC de la compta", "statut": "résolu"},
]


@app.get("/health")
def health():
    # FAIL_HEALTH sert uniquement à simuler une panne pendant l'étape 13 du TP.
    if os.getenv("FAIL_HEALTH") == "1":
        return jsonify(status="ko"), 503
    return jsonify(status="ok"), 200


@app.get("/version")
def version():
    return jsonify(version=VERSION, commit=COMMIT), 200


@app.get("/tickets")
def tickets():
    return jsonify(TICKETS), 200


@app.errorhandler(404)
def not_found(_error):
    return jsonify(erreur="route inconnue"), 404


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "8000")))
