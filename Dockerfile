FROM python:3.12-slim

WORKDIR /app

# Dépendances d'abord (meilleur cache de build)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

# Le commit Git est fourni à la construction : /version l'affichera.
ARG GIT_COMMIT=local
ENV GIT_COMMIT=${GIT_COMMIT} \
    APP_VERSION=${GIT_COMMIT}

# Exécuter sans les droits root
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# 0.0.0.0 : indispensable pour être joignable depuis l'extérieur du conteneur
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
