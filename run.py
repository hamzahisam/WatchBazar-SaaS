#!/usr/bin/env python
"""Quick script to run Django development server."""
import os
import sys

if __name__ == '__main__':
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
    os.system(f'{sys.executable} manage.py runserver')
