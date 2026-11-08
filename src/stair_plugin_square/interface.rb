module StairPluginSquare
  module Interface
    def self.show_dialog
      StairObliqueLogger.info("[STAIR PLUGIN] Lancement de la boîte de dialogue...")
      params = Config.all
      
      # --- 1. PROMPTS (Ajout de la section MATIÈRES) ---
      prompts = [
        "[TRÉMIE]  Hauteur (cm):", 
        "          Largeur (cm):", 
        "          Longueur (cm):",
        "[POTEAU]  Forme:", 
        "          Diamètre/W (cm):", 
        "          Section L (cm):", 
        "          Diagonale:", 
        "          Pos X (cm):", 
        "          Pos Y (cm):",
        "[MARCHES] Nombre:", 
        "          Épaisseur (cm):", 
        "          Rotation:", 
        "          Angle (°):",
        "[MATIÈRE] Bois Marches:",
        "          Poteau identique:",
        "[SYSTÈME] Mode Démo:"
      ]
      
      # --- 2. DEFAULTS (Synchronisation avec Config) ---
      defaults = [
        params[:height_opening].to_cm, 
        params[:width_opening].to_cm, 
        params[:length_opening].to_cm,
        params[:post_is_circular] ? "Circulaire" : "Rectangulaire",
        (params[:post_is_circular] ? params[:post_diameter] : params[:post_section_w]).to_cm,
        params[:post_section_l].to_cm,
        params[:large_diagonal] ? "Grande" : "Petite", # Index 6
        params[:pos_x].to_cm,
        params[:pos_y].to_cm,
        params[:num_steps],
        params[:step_thickness].to_cm,
        params[:clockwise] ? "Clockwise" : "Anti-clockwise",
        params[:total_rotation_angle],
        params[:material_type], 
        params[:post_material_same_as_steps] ? "Oui" : "Non",
        params[:demo_mode] ? "Oui" : "Non"
      ]

      # --- 3. LISTS (Index synchronisés avec les nouveaux prompts) ---
      lists = Array.new(prompts.length, nil)
      lists[3]  = "Circulaire|Rectangulaire"
      lists[6] = "Grande|Petite"
      lists[11] = "Clockwise|Anti-clockwise"
      lists[13] = "Bois Clair|Bois Foncé" # Menu pour la matière des marches
      lists[14] = "Oui|Non"               # Menu pour la synchronisation du poteau
      lists[15] = "Oui|Non"               # Mode démo (index décalé)

      # --- 4. AFFICHAGE ---
      input = UI.inputbox(prompts, defaults, lists, "Paramètres de l'escalier")

      if input
        begin
          # --- 5. CASTING STRICT ET MISE À JOUR CONFIG ---
          Config.set(:height_opening, input[0].to_f.cm) # Index 0 -> Hauteur
          Config.set(:width_opening,  input[1].to_f.cm) # Index 1 -> Largeur
          Config.set(:length_opening, input[2].to_f.cm) # Index 2 -> Longueur
          
          is_circular = (input[3] == "Circulaire")
          Config.set(:post_is_circular, is_circular)
          
          val_w_diam = input[4].to_f.cm
          is_circular ? Config.set(:post_diameter, val_w_diam) : Config.set(:post_section_w, val_w_diam)
          
          Config.set(:post_section_l, input[5].to_f.cm)
          Config.set(:large_diagonal, input[6] == "Grande") # Index 6
          Config.set(:pos_x,          input[7].to_f.cm)      # Index 7
          Config.set(:pos_y,          input[8].to_f.cm)      # Index 8
          
          Config.set(:num_steps,      input[9].to_i)         # Index 9
          Config.set(:step_thickness, input[10].to_f.cm)     # Index 10
          Config.set(:clockwise,      input[11] == "Clockwise")
          Config.set(:total_rotation_angle, input[12].to_f)
          
          # Mise à jour des matières
          Config.set(:material_type, input[13])
          Config.set(:post_material_same_as_steps, input[14] == "Oui")
          
          Config.set(:demo_mode,      input[15] == "Oui")

          # --- 6. BILAN FINAL ---
          result = Generator.start_demo_or_generate
          
          if result
            StairObliqueLogger.info("[STAIR PLUGIN] Génération réussie.")
            UI.messagebox("Succès : L'escalier a été généré avec les paramètres appliqués.")
          else
            StairObliqueLogger.error("[STAIR PLUGIN] Échec de la génération.")
            UI.messagebox("Erreur : La génération a échoué. Veuillez vérifier vos dimensions dans les logs.")
          end
          
        rescue => e
          StairObliqueLogger.error("Erreur interface: #{e.message}")
          UI.messagebox("Erreur de saisie : #{e.message}")
        end
      end
    end
  end
end
