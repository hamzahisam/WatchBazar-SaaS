"""
Django settings for WatchBazar project.
========================================================================================

PRODUCTION-READY CONFIGURATION
This file reads sensitive settings from environment variables (.env file)
instead of hardcoding them in the source code.

DOCUMENTATION:
--------------
- SECRET_KEY: Unique secret for cryptographic signing. NEVER share or commit this.
- DEBUG: Set to False in production to hide error details from users.
- ALLOWED_HOSTS: List of domains that can serve your app.
- DATABASE_URL: Connection string for your database (PostgreSQL ready).

HOW IT WORKS:
-------------
1. Development: Settings are read from .env file in project root
2. Production: Settings come from environment variables (set in Railway/Render dashboard)

SWITCHING TO POSTGRESQL:
------------------------
When you're ready to use PostgreSQL:
1. Set DATABASE_URL in .env or Railway dashboard:
   DATABASE_URL=postgres://user:password@host:5432/dbname
2. That's it! The code below will automatically use PostgreSQL.

========================================================================================
"""

from pathlib import Path
import os

# python-decouple reads from .env file
# Docs: https://github.com/HBNetwork/python-decouple
from decouple import config, Csv

# dj-database-url parses DATABASE_URL into Django format
# Docs: https://github.com/jazzband/dj-database-url
import dj_database_url


# ======================================================================================
# PATH CONFIGURATION
# ======================================================================================
# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent


# ======================================================================================
# SECURITY SETTINGS
# ======================================================================================

# SECRET_KEY: Read from .env file (REQUIRED)
# Generate with: python -c 'import secrets; print(secrets.token_urlsafe(50))'
SECRET_KEY = config('DJANGO_SECRET_KEY')

# DEBUG: Set to False in production!
# In .env: DJANGO_DEBUG=1 (development) or DJANGO_DEBUG=0 (production)
DEBUG = config('DJANGO_DEBUG', default=False, cast=bool)

# ALLOWED_HOSTS: Domains that can serve your app
# In .env: ALLOWED_HOSTS=yourdomain.com,www.yourdomain.com
# Railway/Render will set this automatically via environment variables
ALLOWED_HOSTS = config(
    'ALLOWED_HOSTS',
    default='localhost,127.0.0.1,.railway.app,.onrender.com',
    cast=Csv()
)


# ======================================================================================
# APPLICATION DEFINITION
# ======================================================================================

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'django.contrib.humanize',
    # Your apps
    'pages',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    # WhiteNoise: Serves static files in production (must be after SecurityMiddleware)
    # Docs: https://whitenoise.readthedocs.io/
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'config.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'config.wsgi.application'


# ======================================================================================
# DATABASE CONFIGURATION (MODULAR - SQLite now, PostgreSQL-ready)
# ======================================================================================
# How it works:
# - If DATABASE_URL is set (in .env or environment), use that (PostgreSQL)
# - Otherwise, fall back to SQLite (development default)
#
# To switch to PostgreSQL:
# 1. Set in .env: DATABASE_URL=postgres://user:pass@host:5432/dbname
# 2. Run: python manage.py migrate

DATABASE_URL = config('DATABASE_URL', default=None)

if DATABASE_URL:
    # Production: Use PostgreSQL (or whatever DATABASE_URL points to)
    DATABASES = {
        'default': dj_database_url.parse(DATABASE_URL, conn_max_age=600)
    }
else:
    # Development: Use SQLite
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': BASE_DIR / 'db.sqlite3',
        }
    }


# ======================================================================================
# PASSWORD VALIDATION
# ======================================================================================
# https://docs.djangoproject.com/en/5.2/ref/settings/#auth-password-validators

AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# ======================================================================================
# INTERNATIONALIZATION
# ======================================================================================
# https://docs.djangoproject.com/en/5.2/topics/i18n/

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_TZ = True


# ======================================================================================
# STATIC FILES (CSS, JavaScript, Images)
# ======================================================================================
# https://docs.djangoproject.com/en/5.2/howto/static-files/

# URL prefix for static files
STATIC_URL = '/static/'

# Where to look for static files in development
STATICFILES_DIRS = [BASE_DIR / 'static']

# Where to collect static files for production (run: python manage.py collectstatic)
STATIC_ROOT = BASE_DIR / 'staticfiles'

# WhiteNoise: Compress and cache static files for better performance
# Docs: https://whitenoise.readthedocs.io/en/latest/django.html
STATICFILES_STORAGE = 'whitenoise.storage.CompressedManifestStaticFilesStorage'


# ======================================================================================
# DEFAULT PRIMARY KEY FIELD TYPE
# ======================================================================================
# https://docs.djangoproject.com/en/5.2/ref/settings/#default-auto-field

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'


# ======================================================================================
# SECURITY SETTINGS FOR PRODUCTION
# ======================================================================================
# These settings are automatically enabled when DEBUG=False

if not DEBUG:
    # HTTPS settings
    # NOTE: Railway/Render handle SSL termination, so we disable SECURE_SSL_REDIRECT
    # to prevent redirect loops. Set SECURE_SSL_REDIRECT=1 if hosting elsewhere.
    SECURE_SSL_REDIRECT = config('SECURE_SSL_REDIRECT', default=False, cast=bool)
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    
    # HSTS settings (tells browsers to always use HTTPS)
    SECURE_HSTS_SECONDS = 31536000  # 1 year
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    
    # Trust the X-Forwarded-Proto header from Railway/Render
    SECURE_PROXY_SSL_HEADER = ('HTTP_X_FORWARDED_PROTO', 'https')
