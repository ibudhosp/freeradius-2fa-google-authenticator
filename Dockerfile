FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Install FreeRADIUS, Google Authenticator, Python, PostgreSQL client
RUN apt-get update && \
    apt-get install -y \ 
      freeradius \ 
      freeradius-utils \ 
      libpam-google-authenticator \ 
      libqrencode4 \ 
      python3 \ 
      python3-pip \ 
      python3-venv \ 
      supervisor \ 
      postgresql-client \ 
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory for GA secrets
RUN mkdir -p /etc/freeradius/users-ga

# ===== Python API =====
RUN python3 -m venv /opt/api-venv
COPY api/requirements.txt /opt/api/requirements.txt
RUN /opt/api-venv/bin/pip install --no-cache-dir -r /opt/api/requirements.txt
COPY api/ /opt/api/

# ===== PAM Configuration =====
COPY config/pam_radiusd /etc/pam.d/radiusd

# ===== FreeRADIUS Configuration =====
COPY config/clients.conf /etc/freeradius/3.0/clients.conf
COPY config/users /etc/freeradius/3.0/mods-config/files/authorize
COPY config/default-site /etc/freeradius/3.0/sites-enabled/default

# ===== Scripts =====
COPY scripts/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# FreeRADIUS run as root to read .google_authenticator
RUN sed -i 's/^user = freerad$/user = root/' /etc/freeradius/3.0/radiusd.conf && \
    sed -i 's/^group = freerad$/group = root/' /etc/freeradius/3.0/radiusd.conf

# ===== Supervisor config =====
RUN printf '[program:freeradius]\n\
command=freeradius -f\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n\
\n\
[program:api]\n\
command=/opt/api-venv/bin/uvicorn main:app --host 0.0.0.0 --port 8000\n\
directory=/opt/api\n\
autostart=true\n\
autorestart=true\n\
stdout_logfile=/dev/stdout\n\
stdout_logfile_maxbytes=0\n\
stderr_logfile=/dev/stderr\n\
stderr_logfile_maxbytes=0\n' > /etc/supervisor/conf.d/services.conf

# Expose ports
EXPOSE 1812/udp 1813/udp 8000/tcp

VOLUME ["/etc/freeradius/users-ga"]

ENTRYPOINT ["/entrypoint.sh"]