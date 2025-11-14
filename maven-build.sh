#!/bin/bash

# Script para executar o Maven com as versões corretas do Java e Maven
# Este script configura Java 21 e Maven 3.9.6 que são compatíveis com Quarkus 3.6.4

export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-amd64
export PATH=/home/eduardo-almeida/.sdkman/candidates/maven/3.9.6/bin:$JAVA_HOME/bin:$PATH

echo "Configuracao:"
echo "Java: $(java -version 2>&1 | head -n 1)"
echo "Maven: $(mvn -version | head -n 1)"
echo ""

mvn "$@"



