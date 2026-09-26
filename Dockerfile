FROM eclipse-temurin:25-jdk-jammy
WORKDIR /app
COPY . .
RUN chmod +x startup.sh
EXPOSE 25567 25565
CMD ["bash", "startup.sh"]
