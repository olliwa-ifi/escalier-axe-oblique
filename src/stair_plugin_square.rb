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

  # 3. Création des menus
  unless file_loaded?(__FILE__)
    begin
      version_label = Config::VERSION rescue "1.0.0"
            # Création du sous-menu
      main_menu = UI.menu('Plugins').add_submenu("Olliwa Escalier Axe Oblique")
      
      # Item pour lancer l'interface
      main_menu.add_item("Lancer l'outil v#{version_label}") {
        StairObliqueLogger.log("Bouton Lancement cliqué", :info)
        StairPluginSquare::Interface.show_dialog
      }
      
      main_menu.add_separator
      
      # Item pour l'aide avec le texte détaillé
      main_menu.add_item("Aide / Documentation") {
        StairObliqueLogger.log("Bouton Aide cliqué", :info)
        
        help_text = <<~TEXT
          Remplir les paramètres requis :

            - Trémie : la largeur, la longueur et la hauteur de l'ouverture.
            - Poteau : 
                - la forme (circulaire ou rectangulaire)
                - les dimensions, 
                - le type de diagonale
                - la position du composant de l'escalier  
            - Marches : 
                - le nombre de marches,
                - leur épaisseur,
                - le sens de rotation de l'escalier clockwise ou anti-clockwise
                - l'angle de rotation total de l'escalier.
            - Matieres : 
                - le type de bois entre "Bois Clair" et "Bois Foncé" pour l'ensemble de l'escalier,
                - même couleur pour le poteau et les marches ou rester dans une finition distincte.

                Cliquer sur OK pour lancer la création de l'escalier. 
                Le plugin créera un composant comprenant le composant du poteau central et les composants de toutes les marches.

        TEXT

        
        # Syntaxe correcte : UI.messagebox(message, icone, titre)
        # 64 correspond à l'icône d'information (MB_ICONINFORMATION)
          # 1. Affiche l'aide (le script attend ici le clic sur OK)
        UI.messagebox(help_text, 64, "Guide d'utilisation")
        
        # 2. Lance le plugin immédiatement après le clic sur OK
        StairObliqueLogger.log("Lancement automatique après aide", :info)
        StairPluginSquare::Interface.show_dialog

      }
      
      file_loaded(__FILE__)
      StairObliqueLogger.log("Menu 'Plugins' et sous-menu Aide ajoutés avec succès", :info)
    rescue => e
      StairObliqueLogger.log("Erreur lors de la création du menu : #{e.message}", :error)
    end
  end 
end       
