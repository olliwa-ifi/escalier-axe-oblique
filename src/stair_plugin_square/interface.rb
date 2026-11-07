module StairPluginSquare
  module Interface
    def self.show_dialog
      StairObliqueLogger.info("[STAIR PLUGIN] Lancement de la boîte de dialogue...")
      params = Config.all
      
      prompts = [
        "Largeur trémie (cm):", 
        "Longueur trémie (cm):", 
        "Hauteur trémie (cm):",
        "Épaisseur marche (cm):", 
        "Nombre de marches:", 
        "Poteau Circulaire (1=Oui, 0=Non):",
        "Diamètre poteau (cm):",
        "Angle de rotation total (°):", 
        "Grande Diagonale (1=Oui, 0=Non):",
        "Section Poteau W (cm):", 
        "Section Poteau L (cm):", 
        "Clockwise (1=Oui, 0=Non):",
        "Position X (cm):", 
        "Position Y (cm):",
        "Mode Démo (1=Oui, 0=Non):"
      ]
      
      defaults = [
        params[:width_opening].to_cm, 
        params[:length_opening].to_cm, 
        params[:height_opening].to_cm,
        params[:step_thickness].to_cm, 
        params[:num_steps], 
        params[:post_is_circular] ? 1 : 0,
        params[:post_diameter].to_cm,
        params[:total_rotation_angle], 
        params[:large_diagonal] ? 1 : 0,
        params[:post_section_w].to_cm, 
        params[:post_section_l].to_cm, 
        params[:clockwise] ? 1 : 0,
        params[:pos_x].to_cm, 
        params[:pos_y].to_cm,
        params[:demo_mode] ? 1 : 0
      ]

      input = UI.inputbox(prompts, defaults, "Paramètres de l'escalier")

      if input
        StairObliqueLogger.debug("Mise à jour de la configuration avec les données saisies par l'utilisateur: #{input.inspect}")
        # Update Configuration - Corrected Indices to match the prompts array
        Config.set(:width_opening, input[0].to_f.cm)
        Config.set(:length_opening, input[1].to_f.cm)
        Config.set(:height_opening, input[2].to_f.cm)
        Config.set(:step_thickness, input[3].to_f.cm)
        Config.set(:num_steps, input[4].to_i)
        Config.set(:post_is_circular, input[5] == 1)
        Config.set(:post_diameter, input[6].to_f.cm)
        Config.set(:total_rotation_angle, input[7].to_f)
        Config.set(:large_diagonal, input[8] == 1)
        Config.set(:post_section_w, input[9].to_f.cm)
        Config.set(:post_section_l, input[10].to_f.cm)
        Config.set(:clockwise, input[11] == 1)
        Config.set(:pos_x, input[12].to_f.cm)
        Config.set(:pos_y, input[13].to_f.cm)
        Config.set(:demo_mode, input[14] == 1)

         success = Generator.start_demo_or_generate
        
        if success
          final_params = Config.all
          # Fixed: changed 'final' to 'final_params' to resolve NameError
          shape = final_params[:post_is_circular] ? 
            "Circulaire (#{final_params[:post_diameter].to_cm.round(2)}cm)" : 
            "Rectangulaire (#{final_params[:post_section_w].to_cm.round(2)}x#{final_params[:post_section_l].to_cm.round(2)}cm)"
          
          bilan = "Génération terminée avec succès !\n\n"
          bilan += "--- Bilan des paramètres ---\n"
          bilan += "Trémie: #{final_params[:width_opening].to_cm.round(2)} x #{final_params[:length_opening].to_cm.round(2)} cm\n"
          bilan += "Hauteur: #{final_params[:height_opening].to_cm.round(2)} cm\n"
          bilan += "Marches: #{final_params[:num_steps]} (#{final_params[:step_thickness].to_cm.round(2)} cm)\n"
          bilan += "Rotation Totale: #{final_params[:total_rotation_angle].round(2)}°\n"
          bilan += "Poteau: #{shape}\n"
          bilan += "Sens: #{final_params[:clockwise] ? 'Clockwise' : 'Anti-clockwise'}\n"
          bilan += "Diagonale: #{final_params[:large_diagonal] ? 'Grande' : 'Petite'}\n"
          bilan += "Position: X:#{final_params[:pos_x].to_cm.round(2)}, Y:#{final_params[:pos_y].to_cm.round(2)}"
          
          StairObliqueLogger.info("Génération réussi. Paramètres finaux: #{final_params}")
          UI.messagebox(bilan)
        else
          StairObliqueLogger.error("[STAIR PLUGIN] Le Generator a renvoyé 'false'.")
          UI.messagebox("La génération a échoué. Veuillez vérifier la console.")
        end
      else
        StairObliqueLogger.info("[STAIR PLUGIN] L'utilisateur a annulé la boîte de dialogue.")
      end
    end
  end
end
