# Rjort Blog 🚀

Blogue de tecnologia minimalista em formato de terminal construído com **Ruby 4.0.6**, **Rails 8.1**, **Tailwind CSS v4** e suporte a **Markdown (estilo Hextra)**.

---

## 🛠️ Tecnologias Utilizadas

- **Ruby**: 4.0.6
- **Rails**: 8.1.3
- **Estilização**: Tailwind CSS v4 (Estética Terminal Retro `pic_view`)
- **Markdown Parser**: `commonmarker` + `rouge` (Syntax Highlighting) + `front_matter_parser`
- **Deploy**: Exportação Estática (`out/`) para **Cloudflare Pages**

---

## 🚀 Como Rodar Localmente

```bash
# 1. Instalar as dependências do projeto
bundle install

# 2. Iniciar o servidor de desenvolvimento
bin/dev
# ou
rails server
```

Acesse [http://localhost:3000](http://localhost:3000) no seu navegador.

---

## ☁️ Exportação Estática (Cloudflare Pages)

Para gerar o site estático minificado e pronto para publicação:

```bash
bin/rails export:static
```

Os arquivos estáticos serão gerados na pasta `out/`.
