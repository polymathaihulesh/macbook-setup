# Docker variant of config_dev.py — identical, except the DB HOST is the
# compose service name `db` instead of `localhost` (inside the web container,
# `localhost` is the container itself, not the MySQL container).
# docker-compose.yml copies this to config.py at startup.

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'evd_replica',
        'USER': 'root',
        'PASSWORD': 'evadmin123',
        'HOST': 'db',
        'PORT': '3306',
        'OPTIONS': {
            "init_command": "SET default_storage_engine=INNODB",
        }
    },
    'wikividya': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'wiki1',
        'USER': 'root',
        'PASSWORD': 'evadmin123',
        'HOST': 'db',
        'PORT': '3306',
        'OPTIONS': {
            "init_command": "SET default_storage_engine=INNODB",
        }
    }
}

# Local dev only: print emails to the console instead of sending via SMTP.
EMAIL_BACKEND = 'django.core.mail.backends.console.EmailBackend'
