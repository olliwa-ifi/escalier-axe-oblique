require 'sketchup.rb'

module StairPluginSquare
  # 1. On définit le Logger immédiatement ou on s'assure qu'il est chargé
  # Si le code du logger est dans le même fichier, on le laisse ici. 
  # S'il est dans logger.rb, on le charge en priorité absolue.
  
  plugin_dir = File.join(File.dirname(__FILE__), 'stair_plugin_square')
  
  begin
    require File.join(plugin_dir, 'logger.rb')
    # On utilise maintenant le logger pour tout le reste
    StairObliqueLogger.log("Début du chargement du plugin", :info)
  rescue LoadError => e
    # Fallback si le logger lui-même ne charge pas
    puts "[FALLBACK] Erreur critique : logger.rb introuvable ! #{e.message}"
    # On définit une version minimale du logger pour éviter que le script ne crash
    module StairPluginSquare
      module StairObliqueLogger
        def self.log(msg, lvl=:info); puts "[#{lvl.to_s.upcase}] #{msg}"; end
        def self.debug(msg); log(msg, :debug); end
      end
    end
  end

  # 2. Liste des fichiers restants (on retire logger.rb car déjà chargé)
  files = ['config.rb', 'tools.rb', 'diaglarge.rb', 'diagsmall.rb', 'generator.rb', 'demo.rb', 'interface.rb']

  files.each do |file|
    begin
      path = File.join(plugin_dir, file)
      require path
      StairObliqueLogger.log("Chargement réussi : #{file}", :debug)
    rescue LoadError => e
      StairObliqueLogger.log("Impossible de charger #{file}. Détails : #{e.message}", :error)
    rescue StandardError => e
      StairObliqueLogger.log("Erreur critique dans #{file} : #{e.message}", :error)
    end
  end

  unless file_loaded?(__FILE__)
    begin
      version_label = Config::VERSION rescue "1.0.0"
      
      menu = UI.menu('Plugins')
      menu.add_item("Olliwa Escalier Axe Oblique v#{version_label}") {
        StairObliqueLogger.log("Bouton menu cliqué", :info)
        StairPluginSquare::Interface.show_dialog
      }
      file_loaded(__FILE__)
      StairObliqueLogger.log("Menu 'Plugins' ajouté avec succès (v#{version_label})", :info)
    rescue => e
      StairObliqueLogger.log("Erreur lors de la création du menu : #{e.message}", :error)
    end
  end
  
  StairObliqueLogger.log("Chargement terminé avec succès !", :info)
end
