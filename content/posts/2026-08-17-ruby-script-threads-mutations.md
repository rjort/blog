---
title: "Ruby: script com threads e GraphQL"
date: 2026-08-17
published: true
summary: "Uma utilização real na empresa para o uso de script utilizando técnicas de threads."
---

# Log: Script em Ruby para testes reais na empresa.

## Contexto

Este artigo criei há um bom tempo para o blog da empresa (2021 ou 2022) e agora vou adicioná-lo aqui ao blog para iniciar os posts, uma vez que meu post sumiu do blog da mesma. Darei uma modificada para não ter que divulgar algumas informações quanto ao projeto da época e estou utilizando parte do rascunho que tinha no meu notebook pessoal.

## O Problema

Na aplicação, tínhamos um robô que era configurado via cronjob em uma máquina do EC2 para que ele atualizasse todos os 'timeframes' (nossos períodos de cálculos) de determinadas organizações no projeto, mas o mesmo não estava realizando seu trabalho direito, uma vez que o propósito dele era para ser utilizado de outra maneira e estava desatualizado com a aplicação. Agora tínhamos um robô desatualizado e que já teria que ser executado em produção para satisfazer a necessidade do cliente. Tínhamos um prazo curto, reclamações e não havia uma maneira de realizar os testes que fosse eficiente o suficiente para saber se todos os timeframes foram atualizados de forma manual, então comecei a desenvolver um script para que fosse verificado se tudo estava 'ok'.

## O Script

O script seria bem simples:

1. Criar alguns novos timeframes via API em cerca de 500 times em uma única organização para ficarem marcados como novos;
2. Uma execução nas chamadas das nossas APIs para processar os dados do GraphQL antes e depois da execução do robô para saber se os timestamps dos timeframes foram atualizados;
3. Gerar um relatório para a chefia validar de forma mais rápida que está tudo ok.

Por que Ruby e não outra linguagem? Os QAs do projeto poderiam utilizá-lo, já que as automações de testes eram em Ruby + Capybara e eu tenho boa experiência com o ecossistema Ruby/RoR.

## Construção do script

A princípio, achei que seria uma tarefa fácil, teríamos cerca de 150~200K de dados para processar. A primeira ideia foi fazer o script mais grosseiro, fazendo consultas de forma linear em lotes de 100 em 100 dados para não correr o risco de timeout, e acreditava que uns 5 a 10min de execução seria "tranquilo".

Na primeira implementação, para fazer uma simples consulta para saber se o script estava se comunicando com o endpoint, tomei uma série de erros de que não fazia ideia do que eram relacionados ao Introspection. Nessa época, apenas StackOverflow e buscas no Google serviam para saber o que estava acontecendo e não tinha ninguém da equipe que pudesse me ajudar, já que aparentemente estava tudo certo. Aí, conversando com o DevOps, notamos o Introspection de produção desabilitado. Eu nunca tinha implementado GraphQL ou mexido tanto assim com a tecnologia para saber que se tratava disso; logo, tive que fazer um trabalho de cão montando o schema na mão para poder dar load e fazer funcionar.

``` ruby
URL = "<endpoint>"

HTTP = GraphQL::Client::HTTP.new(URL) do
  def headers(context)
    "Content-Type": "application/json",
    "Authorization": "#{ENV['ID_TOKEN']}",
    "Connection": "keep-alive"
  end
end

Schema = GraphQL::Client.load_schema("./schemas/endpoint1.json")
Client = GraphQL::Client.new(Schema: Schema, execute: HTTP)
```

A primeira parte do script é obter todos os códigos de times da organização na aplicação e salvar em um array. A notação do GraphQL torna tudo mais fácil, já que temos QUERY e MUTATION; a grosso modo, 'query' está para um 'get' e 'mutation' está para um 'post': um busca dados e o outro altera dados.

``` ruby

variables = {
  take: 999,
  skip: 0
}

lista_codigos ||= []

begin
res = Client.query(<MINHA_QUERY>, variables: variables)
res.data.find_many_alguma_coisa.elements.each do |element|
  element.team_code.attributes.each do |item|
    lista_codigos << item
  end
end

rescue => e
  p e.message
  exit
end

```

GraphQL em Ruby é muito simples de usar, a gem permite que tudo do schema se transforme em 'snake_case'. Logo, se você tem uma query/mutation com alguma notação em camelCase, basta replicar no código Ruby em snake_case.

Exemplo:

``` ruby

QUERY <<~ 'GRAPHQL'
findManyAlgumaCoisa(options: { take: $take, skip: $skip }) {
  elements {
    teamCode {
      attributes {
        code
      }
    }
  }
}
GRAPHQL

# find_many_alguma_coisa.elements.team_code.attributes.code
```

Nesse primeiro 'filtro' de informação obtivemos todos os dados em apenas uma requisição e toda a parte de passar a variável `lista_codigos` ocorre de forma muito rápida. Aqui ainda não são os dados de que precisaríamos, apenas códigos de identificação dos times em que iríamos rodar a `mutation`.

## Threads VS Ruby

Uma vez obtidos todos os códigos, rodar as mutations seria o grande desafio: aproximadamente 500 times, e precisaríamos criar para cada time de 2 a 4 `timeframe`. Se me lembro bem, a versão do Ruby utilizada era a 2.7, então ainda tínhamos o "mardito" GIL monothread. A melhor solução na época era a gem `concurrent-ruby` (como passei horas naquele RubyDoc deles...).

Na primeira versão, eu estava gerenciando as threads com array, sincronizando um mutex manual, fazendo join na thread, uma fila FIFO... Enfim, depois que entendi como o `concurrent-ruby` abstrairia tudo, saímos disso:

``` ruby
queue         = Queue.new
semaphore     = Concurrent::Semaphore.new(3)
counter_mutex = Mutex.new
threads     ||= []
counter       = 0
total_codes   = lista_codigos.size

3.times do
  while !queue.empty? && code = queue.pop(true) rescue nil
    semaphore.acquire
    begin
      mutation              = gerar_consulta_a_mutation(code)
      criar_dados_mutation  = Client.parse(mutation)
      res                   = Client.query(criar_dados_mutation)

      puts "Periodo criado | Codigo Time: #{code}" unless res.errors.any?
    rescue => e
      puts "ERRO: #{e.message}"
    ensure
      semaphore.release
    end
    counter_mutex.synchronize do
      counter += 1
      puts "FINALIZADO: #{counter}/#{total_codes}"
    end
  end
end

threads.each(&:join)
```

Para isso:

``` ruby
require 'concurrent-ruby'

thread_pool = Concurrent::FixedThreadPool.new(3)
count       = Concurrent::AtomicFixnum.new(0)
total_codes = lista_codigos.size

lista_codigos.each do |cod|
  thread_pool.post do
    begin
      mutation              = gerar_consulta_a_mutation(cod)
      criar_dados_mutation  = Client.parse(mutation)
      res                   = Client.query(criar_dados_mutation)

      puts "Periodo criado | Codigo Time: #{cod}" unless res.errors.any?
    rescue => e
      puts "ERRO: #{e.message}"
    ensure
      puts "FINALIZADO: #{count.up}/#{total_codes}"
    end
  end
end

thread_pool.shutdown
thread_pool.wait_for_termination
```
Escolhi apenas 3 threads para esse script para evitar qualquer tipo de bloqueio pelos middleware das API, alem de nao causar sobrecarga as mesmas.
O `concurrent-ruby` deixou o código bem mais limpo. O que mais me animou nesse script foi a possibilidade de usar threads de forma mais "manual" e mais "baixo nível", sem abstrações de serviços como Sidekiq, Event Loop, Workers, enfim, coisas voltadas à programação na web.

## Conclusão

Então é isso... Um script simples, mas com conceitos de utilização que não se costuma ver muito no dia a dia do desenvolvimento web. Criar algo no dia a dia que utilize threads é geralmente difícil, e acredito que minha base para paralelismo na época ainda estava se desenvolvendo. No post do blog da empresa eu possuía benchmarks de utilização, mas isso ficou na versão final que estava no notebook da empresa, então não trarei aqui para comparações. É isso. Até!
