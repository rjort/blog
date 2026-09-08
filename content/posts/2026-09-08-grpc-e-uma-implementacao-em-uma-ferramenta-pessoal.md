---
title: "gRPC e uma implementação em uma ferramenta pessoal"
date: 2026-09-08
published: true
summary: "Como tirei o SalvaAposta do papel usando gRPC, Protobuf, Python e Connect-RPC para integrar o frontend sem REST tradicional."
---

Finalmente tirei uma das minhas ideias do papel conseguindo concluí-la. Este é o SalvaAposta, uma ferramenta que criei para que eu possa salvar minhas "fezinhas".

## Contexto

Vez ou outra vou na lotérica da Caixa fazer pagamentos para meus sogros ou simplesmente sacar dinheiro para eles. Eles já são idosos, então aceitar o Pix e a tecnologia é uma barreira um pouco difícil. E nisso de ir à lotérica, aproveito para dar uma olhada nas cotas dos jogos disponíveis; geralmente gosto de pegar cotas que possuem mais dezenas para a Mega-Sena e Lotofácil. 

Como ultimamente tenho feito isso uma ou duas vezes por mês, acaba que depois eu tenho que pesquisar sobre o concurso e bater número por número para saber quantos acertei ou não. Esse simples trabalho acaba custando uns minutos e, dependendo do horário do dia, não tenho concentração suficiente para validar o bilhete direito ou até mesmo esqueço do jogo que comprei. Eis que entra essa ferramenta, que tenho idealizado desde a época da faculdade, porque desde lá minha tia, que trabalhava em uma lotérica, vez ou outra pedia para que eu pegasse uma cota para ajudá-la a encerrar o dia.

## A ideia inicial

A ideia inicial era bem simples: um script que guarda minha aposta e concurso e, através de um cronjob, outro script faz uma busca na API da Caixa para consultar o resultado e comparar os números sorteados com os meus.

Um exemplo simples do esboço da CLI:
`$ salva_aposta "4, 22, 12, 53, 23, 10" -C 2220` # salvar a aposta e retornar um hash usando uuid com os 6 primeiros dígitos
`$ salva_aposta -C 2220 --result` # retornar o resultado do concurso
`$ salva_aposta -C 2220 --result --diff <hash_aposta>` # retornar o resultado do concurso e mostrar os números da aposta que batem com o resultado.

Na época, eu queria integrar com o bot do Telegram e do Discord para ter um push notification no celular e validar o resultado apenas batendo o olho. Comecei a criar o script em Ruby. Além disso, não lembro se foi um assunto forte em 2019~2020, mas em algum momento ouvi falar e não sei se só queria testar ou se o pessoal da minha bolha do Facebook estava hypado discutindo o uso de servidores gRPC (saudades grupo da A.P.D.A).

## ProtoBuf

Naquela época, eu não sabia absolutamente nada sobre gRPC além do que li no Facebook. Era uma ferramenta que não era usual no dia a dia do que se deveria estudar para conseguir um emprego, então fui à documentação.

O conceito de Protobuf para mim foi mind-blowing, porque estaríamos lidando com arquivos binários para as mensagens e fugindo dos textos em JSON e XML. Do ponto de vista de estrutura, escrever um "contrato" em `.proto` seria o equivalente a escrever uma `interface` para implementar em uma `classe`. Nós temos os conceitos de `message`, `service` e `rpc`:

- `message` é o nosso bloco de dados. Nele definimos os tipos que os dados terão, basicamente nosso "payload" caso fosse um JSON. Vale destacar que os números (`= 1`, `= 2`) não são valores padrão (default), mas sim os *field tags* (identificadores binários únicos de cada campo).

```protobuf
message AccountInfo {
	string name = 1;
	int32 age = 2;
	string email = 3;
	string password = 4;
}

message CreateAccountRequest {
	string account_id = 1;
}
```

- `service` é nossa interface. Nele declaramos nosso agrupamento de serviços.

```protobuf
service AccountService {
	...
}
```

- `rpc` são, basicamente, os métodos que declaramos em nosso service.

```protobuf
service AccountService {
	rpc CreateAccount (CreateAccountRequest) returns (AccountInfo);
}
```

Bom, explicada um pouco da notação de Protobuf, vamos à implementação atual.

## O SalvaApostas

Tudo começa em uma noite desta semana onde vi que tinha duas apostinhas aqui para o sorteio da Independência (hahahaha) e me perguntei quando eu tinha pego essas apostas e quando seria o resultado. Então, acabo lembrando do SalvaApostas original e procuro o código antigo e alguma coisa já implementada. No final, não encontrei nada do código anterior, nem no GitHub nem nos backups, então vamos à nova implementação.

Primeiro decidi mudar a stack utilizada para Python e seu ferramental mais completo para gRPC. A estratégia aqui foi criar um chat com o Gemini para lidar com o frontend, onde seria um pequeno "microfrontend", e eu lidaria com o backend com o auxílio do Gemini no plano de ação e elaboração da arquitetura para implementar os pormenores.

Para o chat do frontend, eu sabia que a IA poderia fazer besteira. Por isso, em todo frontend que sou responsável por criar a tela, eu mando um protótipo de baixa fidelidade para que ela possa seguir os moldes, além de forçar a IA a sempre me questionar sobre possíveis gargalos de UX. Mas como o projeto é para mim, eu saberia como usar a ferramenta, então criei o seguinte protótipo no Excalidraw para o Gemini seguir:

![Protótipo de baixa fidelidade do frontend](/images/posts/prototipo-frontend-excalidraw.png)

Como vocês podem estar vendo ali em cima, temos um "Salvar aposta por foto com IA". Essa implementação atual do SalvaAposta era perfeita para que eu pudesse mexer com IA, mas falamos disso mais tarde.

E para o backend, temos o diagrama de arquitetura que propus à IA:

![Diagrama da arquitetura do backend](/images/posts/arquitetura-backend-salvaaposta.png)

Teríamos toda uma arquitetura para fazermos tratamento de imagem e enviar para um modelo pequeno de IA local no meu notebook apenas para ler imagens de jogos realizados, e aí a IA poderia separar as apostas [A-B-C-...] e o concurso do ticket. Porém, os modelos que utilizei não deram conta devido à limitação do meu notebook (i5 13ª gen, RTX 3050 6GB, 16GB de RAM). Os modelos usados foram o Moondream 2 e o MiniCPM-V 2.6, e ambos não trouxeram bons resultados, por mais que eu otimizasse prompts, cortasse a imagem, saturasse e processasse algumas informações com a biblioteca `Pillow` (eu poderia ter ido mais longe com OpenCV, mas o objetivo do projeto não é esse, talvez em outro momento).

## Frontend e RPC

Quando pensamos em integração de Frontend com Backend na Web, o modelo mental padrão de quase todo desenvolvedor é o modelo **REST (HTTP + JSON)**. 

No modelo REST tradicional, o frontend se comunica através de **endpoints e URLs fixas**, usando verbos HTTP (`GET`, `POST`, `PUT`, `DELETE`). Você precisa saber exatamente a URL de cada recurso, montar headers manualmente e enviar/receber strings em formato JSON.

Com **RPC (Remote Procedure Call)**, nós eliminamos essa camada de abstração de rotas e URLs. Em vez de chamar um *endpoint* HTTP e passar um JSON no corpo da requisição, no RPC o frontend chama **uma função diretamente no servidor**, como se essa função estivesse declarada localmente dentro do próprio código do frontend.

Exemplo de uma abordagem REST:

No REST, o frontend precisa conhecer a rota `/api/v1/apostas`, saber que o verbo é `POST`, montar o JSON na mão e deserializar a resposta usando `fetch` ou `axios`:

```ts
async function salvarApostaRest() {
  const response = await fetch('https://api.salvaaposta.com/api/v1/apostas', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer token_123'
    },
    body: JSON.stringify({
      concurso: 2220,
      dezenas: [4, 22, 12, 53, 23, 10]
    })
  });

  if (!response.ok) {
    throw new Error('Erro ao salvar aposta');
  }

  const data = await response.json();
  console.log("Aposta salva com ID:", data.id);
}
```

Exemplo de uma abordagem gRPC-Web / RPC:

No gRPC, o compilador do Protobuf gera automaticamente os arquivos do cliente e as tipagens em TypeScript. Você não digita URLs nem cria objetos JSON soltos; você instancia uma classe de requisição e invoca o método do serviço:

```ts
import { ApostaServiceClient } from './generated/aposta_pb_service';
import { CriarApostaRequest } from './generated/aposta_pb';

const client = new ApostaServiceClient('http://localhost:8080');

async function salvarApostaRpc() {
  const request = new CriarApostaRequest();
  request.setConcurso(2220);
  request.setDezenasList([4, 22, 12, 53, 23, 10]);

  client.criarAposta(request, {}, (err, response) => {
    if (err) {
      console.error("Erro gRPC:", err.message);
      return;
    }
    console.log("Aposta salva com ID:", response.getApostaId());
  });
}
```

Como os navegadores web não dão acesso direto aos recursos de baixo nível do HTTP/2 exigidos pelo gRPC nativo, a alternativa é utilizar ferramentas intermediárias para fazer a ponte entre o frontend e o servidor, e nesse caso esbarrei no `Connect-RPC`.

O **Connect-RPC** é um ecossistema moderno e extremamente leve criado pela Buf. A grande sacada do protocolo Connect é que ele **pode eliminar a necessidade de ter um Envoy Proxy separado**, pois os servidores compatíveis com Connect entendem gRPC nativo, gRPC-Web e o protocolo Connect (HTTP/1.1 JSON/Protobuf) nativamente na mesma porta.

![Diagrama Connect-RPC e gRPC-Web](/images/posts/diagrama-connect-rpc.png)

Essa abordagem garante tipagem ponta a ponta (se eu mudar algo no arquivo `.proto`, o TypeScript me avisa imediatamente no frontend), payloads binários ultraleves e zero necessidade de escrever boilerplate de rotas REST.

## Conclusão

Construir o SalvaAposta foi uma excelente oportunidade para finalmente tirar uma ideia antiga da gaveta e colocar em prática conceitos que sempre tive curiosidade de explorar mais a fundo, como gRPC, Protobuf e a integração de chamadas RPC com o frontend. 

Mesmo que a parte de visão por computador com modelos locais de IA tenha esbarrado nas limitações de hardware do meu notebook, o aprendizado de desenhar a arquitetura, estruturar os contratos em `.proto` e implementar a comunicação ponta a ponta valeu demais. É o tipo de projeto pessoal que lembra por que gostamos de programar: resolver um problema real do nosso dia a dia aprendendo tecnologias interessantes, e é isso, até o próximo post... daqui a sei lá... alguns dias ou semanas... estou desempregado então vai ser em alguns dias... já tenho quase pronto o texto que será sobre esse blog.
