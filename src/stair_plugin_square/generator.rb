module StairPluginSquare
  class Generator
    # Entry point called by the UI or Loader
    def self.start_demo_or_generate
      # --- INTERCEPTION MODE DÉMO ---
      # Si le mode démo est actif, on délègue la génération des 4 cas au module Demo
      if Config.get(:demo_mode)
        StairObliqueLogger.info("Demo mode active: triggering test scenarios.")
        StairPluginSquare::Demo.run_all
      else
        # Call the actual logic method
        self.generate
      end
    end

    def self.generate 
      p = Config.all
      plugin_v = Config::VERSION 
      thickness = p[:step_thickness]
      
      model = Sketchup.active_model
      entities = model.active_entities
      model.start_operation('Staircase Generation', true)

      begin
        # --- 1. CALCULS RELATIFS ---
        diag_type = p[:large_diagonal] ? "Large" : "Small"
        timecode = Time.now.strftime("%Y%m%d_%H%M%S")

        StairObliqueLogger.info("Starting generation: #{diag_type} diagonal (v#{plugin_v})")
        StairObliqueLogger.debug("Config parameters: #{p.inspect}")

        # Ces points sont définis par rapport à [0,0,0], ils sont donc déjà "locaux"
        # pour le futur composant assembly_def
        if p[:large_diagonal]
          p_start = Geom::Point3d.new(p[:length_opening], 0, 0)
          p_end = Geom::Point3d.new(0, p[:width_opening], p[:height_opening])
        else
          if p[:clockwise]
            p_start = Geom::Point3d.new(p[:length_opening], 0, 0)
            p_end = Geom::Point3d.new(0, 0, p[:height_opening])
          else
            p_start = Geom::Point3d.new(0, 0, 0)
            p_end = Geom::Point3d.new(p[:length_opening], 0, p[:height_opening])
          end
        end

        post_vector = p_end - p_start
        post_length = post_vector.length
        post_dir = post_vector.normalize

        # --- 2. ASSEMBLEMENT ---
        assembly_name = "Staircase_#{diag_type}_Diag_#{timecode}_v#{plugin_v}"
        stair_assembly_def = model.definitions.add(assembly_name)
        assembly_entities = stair_assembly_def.entities
        
        # On définit la transformation du composant principal. 
        # Comme on dessine À L'INTÉRIEUR de stair_assembly_def, 
        # sa transformation interne est l'identité (pas de rotation/déplacement interne).
        main_transformation = Geom::Transformation.new 

        # --- 3. POTEAU ---
        post_name = "Post_#{diag_type}_Diag_v#{plugin_v}"
        post_def = model.definitions.add(post_name)
        create_post(p_start, p_end, p, post_def.entities)
        StairPluginSquare::Tools.orient_faces_outward(post_def.entities)
        assembly_entities.add_instance(post_def, Geom::Transformation.new([0,0,0]))
        StairObliqueLogger.debug("Central post created and added to assembly.")

        # --- 4. MARCHES ---

        if p[:large_diagonal]
          StairObliqueLogger.info("Generating steps for large diagonal...")
          StairPluginSquare::DiagLarge.generate_steps_large_diagonal(p, p_start, post_dir, post_length, assembly_entities, plugin_v)
        else
          StairObliqueLogger.info("Generating steps for small diagonal...")
          StairPluginSquare::DiagSmall.generate_steps_small_diagonal(p, p_start, post_dir, post_length, assembly_entities, plugin_v)
        end

        # --- NOUVEAU : APPLICATION MATIÈRE AUX MARCHES ---
        # On détermine la couleur des marches selon la config
        step_color = (p[:material_type] == "Bois Clair") ? 
                      StairPluginSquare::Config::Materials::WOOD_LIGHT : 
                      StairPluginSquare::Config::Materials::WOOD_DARK

        # On applique cette couleur à toutes les faces de l'assemblage, 
        # SAUF celles qui appartiennent au poteau.
        # Note : Puisque le poteau est un composant (instance), 
        assembly_entities.grep(Sketchup::ComponentInstance).each do |instance|
          # Skip the post instance to ensure the post keeps its own specific color
          next if instance.definition.name.include?("Post_")
          
          # Apply material to all faces inside the step definition
          instance.definition.entities.grep(Sketchup::Face).each do |face|
            face.material = step_color
          end
        end
        # --- 5. POSITIONNEMENT FINAL ---
        # C'est ici et SEULEMENT ICI que l'on applique la position mondiale (pos_x, pos_y)
        final_position = Geom::Transformation.new([p[:pos_x], p[:pos_y], 0])
        entities.add_instance(stair_assembly_def, final_position)

        model.commit_operation
        StairObliqueLogger.info("Staircase generation completed successfully.")
        return true
      rescue => e
        model.abort_operation
        StairObliqueLogger.error("Critical error during generation: #{e.message}\n#{e.backtrace.join("\n")}")
        return false
      end
    end
  
    def self.create_post(p_start, p_end, p, target_entities)
      # --- GESTION DES MATIÈRES ---
      # 1. Déterminer la couleur du poteau
      if p[:post_material_same_as_steps]
        # Le poteau suit la couleur des marches
        color_choice = p[:material_type]
        post_color = (color_choice == "Bois Clair") ? 
                      StairPluginSquare::Config::Materials::WOOD_LIGHT : 
                      StairPluginSquare::Config::Materials::WOOD_DARK
      else
        # Le poteau est forcement en bois foncé (comme demandé)
        post_color = StairPluginSquare::Config::Materials::WOOD_DARK
      end

      # On stocke les faces créées pour leur appliquer la couleur à la fin
      created_faces = []
      if p[:post_is_circular]
        radius = p[:post_diameter] / 2.0
        pts_start = []; pts_end = []
        (0...24).each do |i|
          angle = (i * 15).degrees
          offset = Geom::Vector3d.new(Math.cos(angle)*radius, Math.sin(angle)*radius, 0)
          pts_start << p_start.offset(offset)
          pts_end << p_end.offset(offset)
        end
        target_entities.add_face(pts_start)
        target_entities.add_face(pts_end)
        (0...24).each do |i|
          next_i = (i + 1) % 24
          target_entities.add_face(pts_start[i], pts_start[next_i], pts_end[next_i], pts_end[i])
        end
      else
        w = p[:post_section_w] / 2.0
        l = p[:post_section_l] / 2.0
        offsets = [
          Geom::Vector3d.new(-w, -l, 0),
          Geom::Vector3d.new(w, -l, 0),
          Geom::Vector3d.new(w, l, 0),
          Geom::Vector3d.new(-w, l, 0)
        ]
        pts_start = offsets.map { |off| p_start.offset(off) }
        pts_end = offsets.map { |off| p_end.offset(off) }
        target_entities.add_face(pts_start)
        target_entities.add_face(pts_end)
        (0...4).each do |i|
          next_i = (i + 1) % 4
          target_entities.add_face(pts_start[i], pts_start[next_i], pts_end[next_i], pts_end[i])
        end
      end
      # --- 3. APPLICATION DE LA MATIÈRE ---
      # On boucle sur toutes les faces de l'entité cible pour appliquer la couleur
      target_entities.grep(Sketchup::Face).each do |face|
        face.material = post_color
      end
    end
  end
end
