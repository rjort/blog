---
title: "ruby e websockets pt2"
date: 2025-06-22
published: true
summary: "Aprofundando no ActionCable e transmissões em tempo real."
---

# Log: ruby e websockets pt2

## Recapitulando a parte 1

[ [<- Ler parte 1: ruby e websockets pt1](/posts/ruby-e-websockets-pt1) ]

## ActionCable na pratica

No Rails 8.1, o ActionCable oferece suporte integrado para streaming e atualizações em tempo real com facilidade.

```ruby
class ChatChannel < ApplicationCable::Channel
  def subscribed
    stream_from "chat_channel"
  end

  def speak(data)
    ActionCable.server.broadcast("chat_channel", message: data["message"])
  end
end
```

## Escalabilidade e Redis

Para cenários de alto tráfego, o adaptador de pub/sub baseado em Redis ou Solid Cable garante a distribuição eficiente entre múltiplos servidores Puma.
