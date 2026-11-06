from app import app

client = app.test_client()


def test_health_repond_200():
    reponse = client.get("/health")
    assert reponse.status_code == 200
    assert reponse.get_json()["status"] == "ok"


def test_route_metier_renvoie_la_liste_des_tickets():
    reponse = client.get("/tickets")
    assert reponse.status_code == 200
    donnees = reponse.get_json()
    assert isinstance(donnees, list)
    assert len(donnees) >= 1
    assert {"id", "titre", "statut"} <= set(donnees[0].keys())


def test_route_inexistante_renvoie_404():
    reponse = client.get("/cette-route-nexiste-pas")
    assert reponse.status_code == 404


def test_version_est_exposee():
    reponse = client.get("/version")
    assert reponse.status_code == 200
    assert "version" in reponse.get_json()
