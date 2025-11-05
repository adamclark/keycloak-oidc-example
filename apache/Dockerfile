FROM registry.redhat.io/ubi10/httpd-24

USER root

# Install EPEL repository and mod_auth_openidc
RUN yum install -y mod_auth_openidc && \
    yum clean all

USER 1001

# Copy Apache configuration
COPY httpd-oidc.conf /etc/httpd/conf.d/httpd-oidc.conf

COPY certs/tls.key /etc/httpd/tls/localhost.key
COPY certs/tls.crt /etc/httpd/tls/localhost.crt

USER root
RUN chmod a+r /etc/httpd/tls/*
USER 1001