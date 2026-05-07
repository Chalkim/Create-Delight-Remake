FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY . .
RUN chmod +x start.sh

EXPOSE 25565

CMD ["./start.sh"]