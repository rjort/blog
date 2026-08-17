namespace :export do
  desc "Exporta a aplicação Rails para páginas HTML estáticas na pasta out/"
  task static: :environment do
    require "fileutils"

    # Precompila os assets para gerar os arquivos minificados/digests
    system("bin/rails assets:precompile")

    output_dir = Rails.root.join("out")
    FileUtils.rm_rf(output_dir)
    FileUtils.mkdir_p(output_dir)

    session = ActionDispatch::Integration::Session.new(Rails.application)
    session.host = "127.0.0.1"

    # Helper para salvar respostas HTML
    save_page = lambda do |path, destination_rel_path|
      session.get("http://127.0.0.1#{path}")
      if session.status == 200
        dest_file = output_dir.join(destination_rel_path)
        FileUtils.mkdir_p(File.dirname(dest_file))
        File.write(dest_file, session.body)
        puts " [✓] Exportado: #{path} -> #{destination_rel_path}"
      else
        puts " [X] ERRO ao exportar #{path} (Status #{session.status})"
      end
    end

    # 1. Exporta Página Inicial
    save_page.call("/", "index.html")

    # 2. Exporta cada Post para posts/:slug/index.html (para URLs limpas no Cloudflare Pages)
    Post.all.each do |post|
      save_page.call("/posts/#{post.slug}", "posts/#{post.slug}/index.html")
    end

    # 3. Copiar todos os assets compilados do Propshaft para out/assets/
    public_assets_dir = Rails.root.join("public", "assets")
    if Dir.exist?(public_assets_dir)
      FileUtils.cp_r(public_assets_dir, output_dir.join("assets"))
      puts " [✓] Copiados assets de public/assets/ para out/assets/"
    end

    # Copiar outros arquivos estáticos da pasta public (ícones, robots.txt, etc)
    public_dir = Rails.root.join("public")
    Dir.glob("#{public_dir}/*").each do |file|
      next if File.directory?(file) || file.end_with?(".html")
      FileUtils.cp(file, output_dir.join(File.basename(file)))
    end

    # Limpa a pasta public/assets temporária
    FileUtils.rm_rf(public_assets_dir)

    puts "\n🎉 Exportação estática concluída com sucesso no diretório `out/`!"
  end
end
