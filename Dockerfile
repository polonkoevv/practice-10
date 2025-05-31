# Dockerfile
# Этап сборки
FROM golang:1.23-alpine AS builder

# Установка необходимых утилит
RUN apk add --no-cache git

# Рабочая директория
WORKDIR /app

# Копирование и загрузка зависимостей
COPY go.mod go.sum ./
RUN go mod download

# Копирование исходного кода
COPY . .

# Компиляция приложения
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o library .

# Финальный образ
FROM alpine:3.18

# Установка зависимостей
RUN apk add --no-cache ca-certificates tzdata

# Создание непривилегированного пользователя
RUN adduser -D -g '' appuser

# Копирование бинарного файла из этапа сборки
WORKDIR /app
COPY --from=builder /app/library .

# Установка прав
RUN chown -R appuser:appuser /app

# Переключение на непривилегированного пользователя
USER appuser

# Открытие порта
EXPOSE 8080

# Команда запуска
CMD ["./main"]
