#!/bin/sh

set -e

python manage.py collectstatic --noinput
python manage.py wait_for_db # wait until db is ready
python  manage.py migrate

uwsgi --socket :9000 --workers 4 --master --enable-threads --module app.wsgi

# Proxy Config
### Environment Variables

 # - `LISTEN_PORT` - Port to listen on (default: `8000`)
 # - `APP_HOST` - Hostname of the app to forward requests to (default: `app`)
 # - `APP_PORT` - Port of the app to forward requests to (default: `9000`)

 # we have mapped proxy who can forward requests on port 9000 to python app web server 