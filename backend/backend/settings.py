"""DineQR Backend — Django Settings"""
import os
from pathlib import Path
from datetime import timedelta

from dotenv import load_dotenv
import dj_database_url

load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('SECRET_KEY', 'dineqr-dev-secret-key-change-me')
DEBUG = os.getenv('DEBUG', 'True') == 'True'
ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '*').split(',')

# ─── INSTALLED APPS ──────────────────────────────────────────

INSTALLED_APPS = [
    'daphne',
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',

    # Third party
    'rest_framework',
    'corsheaders',
    'channels',

    # Local apps
    'users.apps.UsersConfig',
    'menu.apps.MenuConfig',
    'orders.apps.OrdersConfig',
]

# ─── MIDDLEWARE ────────────────────────────────────────────────

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'backend.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'backend.wsgi.application'
ASGI_APPLICATION = 'backend.asgi.application'


# ─── DATABASE (Supabase via DATABASE_URL) ────────────────────

# If DATABASE_URL is not explicitly set, try to construct it from
# SUPABASE_* environment variables for convenience.
supabase_host = os.getenv('SUPABASE_HOST')
default_db_url = None
if supabase_host:
    supabase_user = os.getenv('SUPABASE_USER', 'postgres')
    supabase_password = os.getenv('SUPABASE_PASSWORD', '')
    supabase_db = os.getenv('SUPABASE_DB', 'postgres')
    supabase_port = os.getenv('SUPABASE_PORT', '5432')
    default_db_url = (
        f"postgresql://{supabase_user}:{supabase_password}"
        f"@{supabase_host}:{supabase_port}/{supabase_db}"
    )

DATABASE_URL = os.getenv('DATABASE_URL', default_db_url)

if not DATABASE_URL:
    raise RuntimeError('DATABASE_URL or SUPABASE_* environment variables must be set')

DATABASES = {
    'default': dj_database_url.parse(
        DATABASE_URL,
        conn_max_age=600,
        conn_health_checks=True,
    )
}

# ─── AUTH ─────────────────────────────────────────────────────

AUTH_USER_MODEL = 'users.User'

AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# ─── REST FRAMEWORK ───────────────────────────────────────────

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': (
        'rest_framework.permissions.AllowAny',
    ),
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 50,
}

# ─── JWT ──────────────────────────────────────────────────────

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(hours=12),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=7),
    'ROTATE_REFRESH_TOKENS': True,
    'AUTH_HEADER_TYPES': ('Bearer',),
}

# ─── CORS ─────────────────────────────────────────────────────

CORS_ALLOW_ALL_ORIGINS = os.getenv('CORS_ALLOW_ALL', 'True') == 'True'

# ─── CHANNELS (WebSocket) ────────────────────────────────────

REDIS_URL = os.getenv('REDIS_URL', 'redis://localhost:6379/0')
CHANNEL_LAYERS = {
    'default': {
        'BACKEND': 'channels_redis.core.RedisChannelLayer' if 'redis' in REDIS_URL else 'channels.layers.InMemoryChannelLayer',
        'CONFIG': {
            'hosts': [REDIS_URL],
        } if 'redis' in REDIS_URL else {},
    },
}

# ─── STATIC & MEDIA ──────────────────────────────────────────

LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'Africa/Addis_Ababa'
USE_I18N = True
USE_TZ = True

STATIC_URL = '/static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'
STATICFILES_DIRS = [BASE_DIR / 'static']

MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'
