# syntax=docker/dockerfile:1
#
# auth-service (Go) — build multi-stage.
# Estágio 1 compila um binário estático; estágio 2 carrega só o binário.
# Imagem final: distroless/static (~2 MB de base, sem shell, sem gerenciador de pacotes).

# ---------- estágio 1: build ----------
FROM golang:1.21-alpine AS build

WORKDIR /src

# go.mod/go.sum primeiro: essa camada só invalida quando as dependências mudam,
# então alterar o código-fonte não refaz o download dos módulos.
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# CGO_ENABLED=0  -> binário estático, roda em imagem sem libc
# -trimpath       -> remove caminhos absolutos da máquina de build
# -ldflags="-s -w"-> descarta tabela de símbolos e DWARF
RUN CGO_ENABLED=0 GOOS=linux go build \
    -trimpath -ldflags="-s -w" \
    -o /out/auth-service .

# ---------- estágio 2: runtime ----------
FROM gcr.io/distroless/static-debian12:nonroot

COPY --from=build /out/auth-service /auth-service

EXPOSE 8001
USER nonroot:nonroot

ENTRYPOINT ["/auth-service"]
