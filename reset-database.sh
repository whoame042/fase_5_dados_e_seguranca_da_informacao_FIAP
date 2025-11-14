#!/bin/bash

# Script para reinicializar o banco de dados com dados limpos
# Remove os volumes e reinicia os containers para executar o init-data.sql novamente

echo "Parando containers..."
docker-compose down

echo ""
echo "Removendo volumes do PostgreSQL..."
docker-compose down -v

echo ""
echo "Recriando containers e inicializando banco com dados do init-data.sql..."
docker-compose up -d

echo ""
echo "Aguardando PostgreSQL ficar pronto..."
sleep 5

echo ""
echo "Verificando status dos containers..."
docker-compose ps

echo ""
echo "Para ver os logs:"
echo "  docker-compose logs -f"
echo ""
echo "Para conectar ao PostgreSQL:"
echo "  docker exec -it vehicle-resale-postgres psql -U postgres -d vehicle_resale"
echo ""
echo "Banco de dados reinicializado com sucesso!"



