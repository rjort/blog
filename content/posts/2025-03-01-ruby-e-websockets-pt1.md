---
title: "ruby e websockets pt1"
date: 2025-03-01
published: false
summary: "Introdução ao protocolo WebSocket e comunicação em tempo real no ecossistema Ruby."
---

# Log: ruby e websockets pt1

## O que sao WebSockets

Diferente do modelo tradicional HTTP request-response, o protocolo WebSocket permite comunicação bidirecional de baixíssima latência.

## Conexao inicial (Handshake)

Tudo começa com um *Upgrade Header* no HTTP:

```http
GET /cable HTTP/1.1
Host: localhost:3000
Upgrade: websocket
Connection: Upgrade
```

### Mais
[ [Ir para a parte 2: ruby e websockets pt2 ->](/posts/ruby-e-websockets-pt2) ]
