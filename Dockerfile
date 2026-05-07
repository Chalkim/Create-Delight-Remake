FROM openjdk:17-slim
WORKDIR /app
COPY . .
RUN chmod +x start.sh

EXPOSE 25565

CMD ["./start.sh"]