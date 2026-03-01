####
# Este Dockerfile é usado para construir uma imagem de container para a aplicação
####
FROM registry.access.redhat.com/ubi8/openjdk-17:1.23

ENV LANGUAGE='en_US:en'

# Configura o diretório de trabalho
WORKDIR /work/

# Copia o jar da aplicação
COPY --chown=185 target/quarkus-app/lib/ /work/lib/
COPY --chown=185 target/quarkus-app/*.jar /work/
COPY --chown=185 target/quarkus-app/app/ /work/app/
COPY --chown=185 target/quarkus-app/quarkus/ /work/quarkus/

# Expõe a porta padrão
EXPOSE 8082

# Define o usuário não-root
USER 185

# Comando para iniciar a aplicação
CMD ["java", "-jar", "/work/quarkus-run.jar"]

