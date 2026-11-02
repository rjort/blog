---
title: System Design ou RPG de Desenvolvimento, parte 1
date: 2026-11-01
slug: system-design-ou-rpg-de-desenvolvimento-parte-1
published: true
summary: Como uma entrevista de System Design me fez perceber que desenhar arquiteturas de software tem tudo a ver com uma boa sessão de RPG de mesa.
---

# System Design ou RPG de Desenvolvimento, parte 1

## Introdução

Recentemente fiz uma entrevista para Dev Mid-Level RoR, com 5 etapas, sendo a penúltima o System Design. Até então, na minha vida como desenvolvedor, isso seria apenas mais uma skill que eu só aprimoraria quando eu precisasse chegar ao próximo nível ou atuasse de forma mais próxima ao arquiteto/tech lead. Mas enfim, voltando à entrevista.

## Role Play, Aprendendo as Regras

Eu tinha 1 dia para aprender realmente sobre o que é System Design. Vi vídeos, treinei com IA, li blogs, mas o nervosismo tomou conta no final de tudo, e o entendimento de como eu poderia ter levado a conversa só veio nos momentos finais e já não dava para reverter a impressão que causei. De qualquer maneira, foi um ótimo aprendizado.

Os vídeos falam sobre você ter um bom conhecimento sobre as tecnologias para fazer boas perguntas ao entrevistador para que você obtenha o máximo de informações possíveis sobre o funcionamento da sua solução. Quanto mais assistia a vídeos e lia textos, eu pensava: "Onde foi que eu já interagi desse jeito para resolver algo?"

Mesmo durante a entrevista eu continuava com uma sensação de que algo ainda parecia familiar, mas o que estava em jogo ali era diferente, então não dava para associar as coisas.

Com a entrevista encerrada e o dia finalizado, naquele momento em que deito e reflito sobre o dia, eu ligo os pontos: "System Design é RPG de desenvolvedor". É aí que tenho a ideia de fazer esse texto.

Em uma entrevista de System Design, você vai conversar com o entrevistador. Ele vai te dar algumas informações prévias e a partir disso você vai tentar coletar mais informações enquanto vai informando suas ações e desenhando o diagrama da sua solução, simples assim.

## Teste de Carisma: RPG Fantasia x RPG System Design

O mestre da mesa começa:

> Você está em uma taberna com seu grupo recém-formado de aventureiros discutindo sobre uma informação que ouviram de camponeses refugiados sobre Grifos de pelo escuro que estavam sobrevoando a região. Um dos camponeses escutou de alguém do grupo de soldados da realeza que alguém pagaria 5000 peças de ouro pela cabeça e pele do animal. O elfo do grupo diz que já ouviu falar sobre tais grifos e que são muito raros e são muito mais agressivos.

Nessa situação, você já tem no grupo alguém que já ouviu falar das criaturas e por isso seria sensato perguntar ao membro do grupo/NPC como seria o melhor jeito para prosseguir com a caçada, perguntar para algumas pessoas na taberna se ouviram falar também dos animais, verificar se pode conseguir o mapa da região e tentar escutar ao redor para ver se mais pessoas estão falando sobre esses rumores para comprovar se é verdade.

Agora veja só o seguinte desafio de System Design:

O entrevistador começa:

> **Plataforma de Automação**
>
> Você deve projetar a arquitetura de um sistema de automação que permita que usuários configurem fluxos do tipo:
>
> Trigger (evento) → Ação (resposta)
>
> **Requisitos funcionais:**
>
> 1. Usuários podem criar múltiplas automações (workflows).
> 2. O sistema deve receber triggers de diferentes fontes (ex.: HTTP webhook, fila de eventos, agendamentos).
> 3. Cada trigger dispara uma ou mais ações (ex.: chamar uma API externa, enviar e-mail, gravar em banco).
> 4. Usuários devem poder ver o histórico de execuções (sucesso, falha, tempo de execução).
>
> **Exemplos:**
>
> - Quando receber um e-mail com anexo → salvar o anexo no Google Drive.
> - Quando houver um novo registro em uma planilha → enviar uma notificação no Slack.
> - Quando um sensor IoT enviar um alerta → disparar um SMS.

Esse é o enunciado do meu desafio de desenvolvedor mid-level, e a partir disso devemos começar a "rolar o D20" para entrevistar os entrevistadores para obtermos mais informações sobre como vamos desenvolver essa aplicação.

Como podem ver, em ambas as situações, com uma pergunta bem elaborada e uma boa experiência de como agir, você com certeza conseguirá se preparar bem em como vai iniciar sua aventura/desenvolver o sistema. Então vamos para nosso teste de destreza.

## Teste de Iniciativa/Destreza: Pensamento Estruturado para Estratégia

**Jogador:** "Vou prestar atenção no ambiente, consigo escutar alguém comentando sobre o rumor?"

**Mestre:** "Sim, duas mesas atrás de vocês existem dois guardas que estão conversando um pouco mais baixo."

**Jogador (ação):** "Eu levanto da mesa e me aproximo, mas sem levantar muitas suspeitas para tentar ouvir de forma mais clara."

**Mestre:** "Faça um teste de iniciativa..."

Jogadores de RPG (D&D, Tormenta, dentre outros) podem inventar mil maneiras de como fazer essa abordagem, desde muito extravagantes até mais furtivas sem nem mesmo levantar da mesa, apenas usando concentração dentre outras ferramentas do seu arsenal.

Durante a entrevista de System Design, você precisa o tempo todo estar lidando com as informações dadas pelos entrevistadores e o desenho do seu sistema precisa refletir isso. No nosso exemplo, precisamos definir um ponto de partida, e acredito que o melhor lugar para definir isso é **a primeira interação do usuário** seguindo um "caminho feliz" (você não precisa começar dessa maneira dependendo do desafio, mas aqui vamos iniciar pelo tópico 1).

_OBS.: eu não adotei essa estratégia devido ao nervosismo, mas, refletindo sobre o desafio, o primeiro ponto de partida do usuário pode estabelecer como continuar com o fluxo e talvez melhorar a linha de raciocínio._

**Desenvolvedor:** "Como os usuários podem criar múltiplos workflows?"

**Entrevistador:** "Vai ser uma página de configuração."

**Desenvolvedor (ação):** "O usuário acessa o frontend e salva as configurações que vão para SalvarDadosUsuario que valida as informações, se estiver tudo certo, salva no banco de dados."

**Entrevistador:** "O que é SalvarDadosUsuario?"

**Desenvolvedor:** "SalvarDadosUsuario é uma API/Serviço que se conecta com o banco e sanitiza as informações."

![Diagrama do primeiro fluxo: Frontend, API e Banco de Dados](/images/posts/system_design_fluxo_1.png)

Nessa pequena interação, definimos a primeira ação da aventura e o primeiro fluxo. E note a "ação": assim como no RPG, você precisa estar informando qualquer decisão que vai ser tomada.

## Fim da primeira sessão da mesa

Estamos desenvolvendo uma "aventura" baseada no fluxo do meu desafio de System Design e acredito que logo logo vamos finaliza-la e acredito que já conseguimos entender a base para continuarmos com o desafio: como fazer perguntas e explicar nossa "ação".

System Design não precisa ser uma Tiamat... digo, bicho de 7 cabeças, mas é preciso ter uma base sólida para tentar resolver o problema da melhor maneira possível. Essa série de textos não visa ser um tutorial de como vocês devem se comportar, mas entender da melhor forma um todo.

Vamos encerrar nossa sessão por aqui, e na próxima vez que nos reunirmos à mesa, vamos sair dessa primeira etapa melhorando ainda mais o fluxo inicial do usuário e entrar na etapa do processamento dos eventos. Te vejo lá!