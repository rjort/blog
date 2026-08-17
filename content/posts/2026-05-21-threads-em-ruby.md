---
title: "threads em ruby"
date: 2026-05-21
published: true
summary: "Entendendo o modelo de concorrência, GIL e threads no Ruby moderno."
---

# Log: threads em ruby

## Uma breve introducao

O suporte a concorrência em Ruby tem evoluído drasticamente nas últimas versões. Com o avanço do **Ruby 3** e **Ruby 4**, o gerenciamento de threads e modelos assíncronos se tornou muito mais eficiente e intuitivo.

Neste artigo, exploramos o funcionamento interno das Threads em Ruby e como tirar o melhor proveito do paralelismo na sua aplicação.

## o que sao threads

Threads (ou linhas de execução) permitem que um programa realize múltiplas tarefas de forma simultânea ou concorrente no mesmo espaço de memória.

```ruby
# Exemplo simples de criação de Threads em Ruby
threads = []

3.times do |i|
  threads << Thread.new do
    sleep(1)
    puts "Thread #{i} concluída!"
  end
end

threads.each(&:join)
```

Diferente de processos separados (`Process.fork`), as threads compartilham a mesma memória do processo pai, tornando a comunicação entre elas muito rápida, mas exigindo cuidado com *race conditions*.

## como ruby lida com isso

No Ruby (MRI / CRuby), existe o conhecido **GIL** (*Global Interpreter Lock*), atualmente chamado de **GVL** (*Global VM Lock*).

### Como o GVL afeta as Threads:

1. **Tarefas I/O Bound**: Excelente performance! Enquanto uma thread aguarda leitura de disco ou rede, o GVL é liberado para que outra thread execute.
2. **Tarefas CPU Bound**: Executam em apenas 1 core por vez no mesmo processo Ruby, chaveando a execução rapidamente.

Para concorrência real em CPU sem GIL no Ruby moderno, podemos utilizar **Ractors** (Ruby Actors) ou múltiplos processos de worker (Puma cluster).

```ruby
# Exemplo de busca concorrente de dados (I/O)
urls = ["https://api.github.com", "https://rubygems.org"]

results = urls.map do |url|
  Thread.new { URI.open(url).read }
end.map(&:value)
```

## Conclusao

Entender threads em Ruby é essencial para construir sistemas de alta performance. Utilize threads para operações de I/O e Ractors/Processos para processamento pesado de CPU.
