# Практическая работа №10: Развертывание и DevOps
## Часть 1: Docker и контейнеризация Go-приложений
1) Написать простое HTTP-приложение на Go 
- Создано простейшее приложение на Go
```go
package main

import (
	"fmt"
	"net/http"
)

func handler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Hello from Docker!")
}

func main() {
	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}
```

2) Создать Dockerfile
- Создали Dockerfile с учетом требований для деплоя приложения
```dockerfile
FROM golang:1.23.9-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY go.sum ./

RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux go build -o main .

FROM alpine:latest

WORKDIR /root/

COPY --from=builder /app/main .

EXPOSE 8080

CMD ["./main"] 
```

3) Собрать и запустить образ
- Собрали и запустили образ
```bash
docker build -t my-go-app .
docker run -p 8080:8080 my-go-app
```
- Результат:
<image src="./images/hello.png" alt="Результат">


## Часть 2: Настройка CI/CD

1) Добавить файл .github/workflows/go.yml

- Создайли CI/CD pipeline для GitHub Actions

<a href="./.github/workflows/cicd.yml"> ./.github/workflows/cicd.yml</a>

## Часть 3: Развертывание в Kubernetes 

1) Подготовить deployment.yaml
- Создайли файл deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: go-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: go-app
  template:
    metadata:
      labels:
        app: go-app
    spec:
      containers:
        - name: go-app
          image: bersnakx/goapp:latest
          ports:
            - containerPort: 8080

```

2) Подготовить service.yaml
- Создайли файл service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: go-app-service
spec:
  selector:
    app: go-app
  ports:
    - protocol: TCP
      port: 80
      targetPort: 8080
  type: LoadBalancer

```

3) Развертывание
- Запустить minikube или использовать кластер в облаке

Был выбран Minikube
<image src="./images/minstart.png" alt="Запуск minikube">

- Применить манифесты

Результат применения манифестов:
<image src="./images/apply.png" alt="Результат применения манифестов">


## Дополнительное задание

- Реализовали автосборку и пуш docker image в dockerhub в ci/cd pipeline

```yaml
docker-build-and-push:
    needs: test-and-build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && (github.ref == 'refs/heads/main' || github.ref == 'refs/heads/master')
    steps:
      - name: Checkout code
        uses: actions/checkout@v3

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2

      - name: Login to Docker Hub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_TOKEN }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ${{ env.DOCKER_IMAGE }}:latest
            ${{ env.DOCKER_IMAGE }}:${{ env.DOCKER_TAG }}
```

## Результат

- Создали go-приложение
- Создали CI/CD pipeline
- На удаленном севере установили docker, go, minikube
- При пуше в github автоматически собирается и пушится docker-image, после этого в minikube запускается k8s Loadbalancer, доступный на порту 5555