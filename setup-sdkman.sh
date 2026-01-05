#!/bin/bash

##############################################################################
# Script para configurar versões corretas do Java, Maven e Quarkus via SDKMAN
# 
# Versões configuradas:
# - Java: 17 (compatível com Quarkus 3.6.4)
# - Maven: 3.9.6 (compatível com Quarkus 3.6.4)
# - Quarkus: 3.6.4 (definido no pom.xml)
##############################################################################

set -e

# Cores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Versões
JAVA_VERSION="17.0.11-tem"
MAVEN_VERSION="3.9.6"
QUARKUS_VERSION="3.6.4"

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Configuração SDKMAN - Java, Maven e Quarkus                ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar se SDKMAN está instalado
if [ ! -d "$HOME/.sdkman" ]; then
    echo -e "${YELLOW}⚠️  SDKMAN não encontrado. Instalando...${NC}"
    echo ""
    
    curl -s "https://get.sdkman.io" | bash
    
    # Carregar SDKMAN
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
    
    echo -e "${GREEN}✅ SDKMAN instalado com sucesso!${NC}"
    echo ""
else
    echo -e "${GREEN}✅ SDKMAN já está instalado${NC}"
    
    # Carregar SDKMAN se já estiver instalado
    export SDKMAN_DIR="$HOME/.sdkman"
    [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"
fi

echo ""

# Verificar versão atual do Java
echo -e "${YELLOW}📦 Configurando Java ${JAVA_VERSION}...${NC}"
if command -v java &> /dev/null; then
    CURRENT_JAVA=$(java -version 2>&1 | head -n 1)
    echo "  Versão atual: $CURRENT_JAVA"
fi

# Instalar/Configurar Java 17
if ! sdk list java | grep -q "$JAVA_VERSION"; then
    echo "  Instalando Java $JAVA_VERSION..."
    sdk install java "$JAVA_VERSION" || {
        echo -e "${YELLOW}  Tentando instalar versão alternativa...${NC}"
        sdk install java 17.0.11-tem || sdk install java 17.0.10-tem || sdk install java 17.0.9-tem
    }
fi

sdk use java "$JAVA_VERSION" 2>/dev/null || sdk default java "$JAVA_VERSION"

# Verificar instalação do Java
if command -v java &> /dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -n 1)
    echo -e "${GREEN}  ✅ Java configurado: $JAVA_VER${NC}"
else
    echo -e "${RED}  ❌ Erro ao configurar Java${NC}"
    exit 1
fi

echo ""

# Verificar versão atual do Maven
echo -e "${YELLOW}📦 Configurando Maven ${MAVEN_VERSION}...${NC}"
if command -v mvn &> /dev/null; then
    CURRENT_MAVEN=$(mvn -version | head -n 1)
    echo "  Versão atual: $CURRENT_MAVEN"
fi

# Instalar/Configurar Maven
if ! sdk list maven | grep -q "$MAVEN_VERSION"; then
    echo "  Instalando Maven $MAVEN_VERSION..."
    sdk install maven "$MAVEN_VERSION"
fi

sdk use maven "$MAVEN_VERSION" 2>/dev/null || sdk default maven "$MAVEN_VERSION"

# Verificar instalação do Maven
if command -v mvn &> /dev/null; then
    MAVEN_VER=$(mvn -version | head -n 1)
    echo -e "${GREEN}  ✅ Maven configurado: $MAVEN_VER${NC}"
else
    echo -e "${RED}  ❌ Erro ao configurar Maven${NC}"
    exit 1
fi

echo ""

# Resumo final
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    Configuração Concluída                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}✅ Versões configuradas:${NC}"
echo "  • Java: $(java -version 2>&1 | head -n 1 | awk '{print $3}' | tr -d '"')"
echo "  • Maven: $(mvn -version | head -n 1 | awk '{print $3}')"
echo "  • Quarkus: $QUARKUS_VERSION (definido no pom.xml)"
echo ""
echo -e "${YELLOW}💡 Para usar estas versões em uma nova sessão, execute:${NC}"
echo "  source ~/.sdkman/bin/sdkman-init.sh"
echo "  sdk use java $JAVA_VERSION"
echo "  sdk use maven $MAVEN_VERSION"
echo ""
echo -e "${YELLOW}💡 Ou adicione ao seu ~/.bashrc ou ~/.zshrc:${NC}"
echo "  export SDKMAN_DIR=\"\$HOME/.sdkman\""
echo "  [[ -s \"\$HOME/.sdkman/bin/sdkman-init.sh\" ]] && source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
echo "  sdk default java $JAVA_VERSION"
echo "  sdk default maven $MAVEN_VERSION"
echo ""

# Verificar se as versões estão corretas
JAVA_MAJOR=$(java -version 2>&1 | head -n 1 | awk -F'"' '{print $2}' | awk -F'.' '{print $1}')
MAVEN_MAJOR=$(mvn -version | head -n 1 | awk '{print $3}' | awk -F'.' '{print $1}')

if [ "$JAVA_MAJOR" != "17" ]; then
    echo -e "${RED}⚠️  Aviso: Java $JAVA_MAJOR detectado, mas Java 17 é recomendado${NC}"
fi

# Verificar e gerar Maven Wrapper se necessário
echo ""
echo -e "${YELLOW}📦 Verificando Maven Wrapper...${NC}"
if [ ! -f ".mvn/wrapper/maven-wrapper.jar" ]; then
    echo "  Maven Wrapper não encontrado. Gerando..."
    mkdir -p .mvn/wrapper
    
    # Tentar gerar via Maven
    if mvn wrapper:wrapper -Dmaven=3.9.6 -Dtype=jar 2>/dev/null; then
        echo -e "${GREEN}  ✅ Maven Wrapper gerado via Maven${NC}"
    else
        # Baixar manualmente se Maven falhar
        echo "  Baixando maven-wrapper.jar manualmente..."
        curl -L -o .mvn/wrapper/maven-wrapper.jar \
            https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.3.4/maven-wrapper-3.3.4.jar 2>/dev/null
        
        if [ -f ".mvn/wrapper/maven-wrapper.jar" ]; then
            echo -e "${GREEN}  ✅ Maven Wrapper baixado manualmente${NC}"
        else
            echo -e "${YELLOW}  ⚠️  Não foi possível baixar maven-wrapper.jar${NC}"
            echo "  Você pode baixar manualmente de:"
            echo "  https://repo.maven.apache.org/maven2/org/apache/maven/wrapper/maven-wrapper/3.3.4/maven-wrapper-3.3.4.jar"
        fi
    fi
else
    echo -e "${GREEN}  ✅ Maven Wrapper já existe${NC}"
fi

echo ""
echo -e "${GREEN}✅ Configuração concluída! Você pode agora executar:${NC}"
echo "  ./mvnw clean package"
echo "  ./mvnw quarkus:dev"
echo ""

