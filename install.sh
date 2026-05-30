#!/bin/bash
# VibeShort — instalador para VPS Ubuntu/Debian
set -e

echo "=========================================="
echo "  Instalador VibeShort para VPS"
echo "=========================================="

echo "[1/6] Instalando dependencias..."
sudo apt-get update
sudo apt-get install -y python3 python3-pip python3-venv nginx certbot python3-certbot-nginx

if [ ! -d "/opt/vibeshort" ]; then
  echo "[2/6] Cloná tu repo a /opt/vibeshort primero:"
  echo "  cd /opt && git clone https://github.com/TU-USUARIO/TU-REPO vibeshort"
  exit 1
fi

cd /opt/vibeshort/backend

echo "[3/6] Creando entorno virtual..."
python3 -m venv venv
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

if [ ! -f .env ]; then
  echo "[4/6] Generando .env con JWT_SECRET random..."
  echo "JWT_SECRET=$(openssl rand -hex 32)" > .env
  echo "PORT=8001" >> .env
fi

echo "[5/6] Configurando systemd..."
sudo tee /etc/systemd/system/vibeshort.service > /dev/null <<EOF
[Unit]
Description=VibeShort (Lluvia App Studio)
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=/opt/vibeshort/backend
EnvironmentFile=/opt/vibeshort/backend/.env
ExecStart=/opt/vibeshort/backend/venv/bin/uvicorn server:app --host 0.0.0.0 --port 8001
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable vibeshort
sudo systemctl start vibeshort

echo "[6/6] Verificando que arrancó..."
sleep 2
sudo systemctl status vibeshort --no-pager || true

echo ""
echo "=========================================="
echo "  ✅ VibeShort instalado!"
echo "=========================================="
echo "  Corriendo en: http://$(curl -s ifconfig.me):8001"
echo ""
echo "  PRÓXIMO PASO: configurar HTTPS con Nginx + Let's Encrypt:"
echo "    sudo certbot --nginx -d TU_DOMINIO.com"
echo "=========================================="
