# Fiche de choix du binôme

| Rubrique | À renseigner |
|---|---|
| Application et besoin métier | API de tickets informatiques NovaServices : permet de consulter la liste des tickets du support |
| Source du projet | Dépôt GitHub du binôme créé à partir de ce modèle (URL : ………) |
| Exécution | `python app.py` (développement) ou `gunicorn app:app` (conteneur) ; port interne 8000 |
| Validation (3 comportements) | 1) GET /health répond 200 ; 2) GET /tickets renvoie la liste ; 3) une URL inconnue répond 404 |
| Identification | Le commit Git, affiché par GET /version |
