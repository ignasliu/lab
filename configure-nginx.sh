#!/bin/bash

# Install necessary packages
apt-get update
apt-get install -y nginx jq

# Enable managed identity
IDENTITY_TOKEN=$(curl -H "Metadata:true" "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2019-08-01&resource=https://vault.azure.net" | jq -r '.access_token')

# Download certificates from Azure Key Vault
KEYVAULT_NAME="MyKeyVaultlbpoc"
mkdir -p /etc/nginx/certs
for CERT_NAME in serverCert customer1Cert customer2Cert customer3Cert clientCert; do
  CERT_URI="https://${KEYVAULT_NAME}.vault.azure.net/secrets/${CERT_NAME}?api-version=7.0"
  curl -H "Authorization: Bearer ${IDENTITY_TOKEN}" "${CERT_URI}" | jq -r '.value' | base64 -d > "/etc/nginx/certs/${CERT_NAME}.crt"
done

# Configure Nginx
cat <<EOF > /etc/nginx/nginx.conf
events { }

http {
    include       mime.types;
    default_type  application/octet-stream;

    server {
        listen 443 ssl;
        server_name customer1.local;

        ssl_certificate /etc/nginx/certs/customer1Cert.crt;
        ssl_certificate_key /etc/nginx/certs/serverCert.crt;
        ssl_client_certificate /etc/nginx/certs/clientCert.crt;
        ssl_verify_client on;

        location / {
            root   html;
            index  index.html index.htm;
            return 200 'Customer 1 Response';
            add_header Content-Type text/plain;
        }
    }

    server {
        listen 443 ssl;
        server_name customer2.local;

        ssl_certificate /etc/nginx/certs/customer2Cert.crt;
        ssl_certificate_key /etc/nginx/certs/serverCert.crt;
        ssl_client_certificate /etc/nginx/certs/clientCert.crt;
        ssl_verify_client on;

        location / {
            root   html;
            index  index.html index.htm;
            return 200 'Customer 2 Response';
            add_header Content-Type text/plain;
        }
    }

    server {
        listen 443 ssl;
        server_name customer3.local;

        ssl_certificate /etc/nginx/certs/customer3Cert.crt;
        ssl_certificate_key /etc/nginx/certs/serverCert.crt;
        ssl_client_certificate /etc/nginx/certs/clientCert.crt;
        ssl_verify_client on;

        location / {
            root   html;
            index  index.html index.htm;
            return 200 'Customer 3 Response';
            add_header Content-Type text/plain;
        }
    }
}
EOF

# Restart Nginx to apply configuration
systemctl restart nginx
