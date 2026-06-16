# eVidyaloka (Django 4.2 / Python 3.12) — dev container.
# Mirrors the current Ubuntu x86 environment. Run as linux/amd64 (see compose)
# so all dependencies — including the Intel-only daal4py — install cleanly,
# even on Apple Silicon Macs (Docker Desktop emulates x86 via Rosetta).
FROM python:3.12-slim

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# System libraries needed to build/run the Python deps:
#   - default-libmysqlclient-dev, pkg-config, build-essential -> mysqlclient
#   - libjpeg/zlib/freetype                                    -> Pillow / reportlab
#   - libssl/libffi                                            -> cryptography
#   - default-mysql-client                                     -> mysql/mysqldump CLI inside the container
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential pkg-config default-libmysqlclient-dev \
        libjpeg-dev zlib1g-dev libfreetype6-dev libssl-dev libffi-dev \
        default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (better layer caching)
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt
# These are imported by the app but missing from requirements.txt (they were
# only present in the old Ubuntu environment):
#   python-dotenv  -> evidyaloka/settings.py
#   SQLAlchemy     -> web/views.py (create_engine)
#   firebase-admin -> vrm_services/context_processor.py (runs on every request)
RUN pip install "python-dotenv==0.15.0" "SQLAlchemy>=2.0,<2.1" "firebase-admin>=6.0,<7.0"

# App code is bind-mounted in dev (see docker-compose.yml), so this COPY is for
# image completeness / non-mounted runs.
COPY . .

EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
