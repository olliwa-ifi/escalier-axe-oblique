module StairPluginSquare
  module Interface
    # 1. LE SCHEMA : La source unique de vérité
    # Format: clé_config => { prompt: "", default_key: :key, list: "A|B", type: :float/:int/:bool/:string }
    SCHEMA = {
      height_opening:       { prompt: "[TRÉMIE]  Hauteur (cm):",   default_key: :height_opening,       list: nil, type: :float },
      width_opening:        { prompt: "          Largeur (cm):",   default_key: :width_opening,        list: nil, type: :float },
      length_opening:       { prompt: "          Longueur (cm):",  default_key: :length_opening,       list: nil, type: :float },
      post_is_circular:     { prompt: "[POTEAU]  Forme:",          default_key: :post_is_circular,      list: "Circulaire|Rectangulaire", type: :bool },
      post_dimension_w:     { prompt: "          Diamètre/W (cm):", default_key: :post_dim_w,           list: nil, type: :float },
      post_section_l:       { prompt: "          Section L (cm):",  default_key: :post_section_l,       list: nil, type: :float },
      large_diagonal:       { prompt: "          Diagonale:",       default_key: :large_diagonal,       list: "Grande|Petite", type: :bool },
      pos_x:                { prompt: "          Pos X (cm):",      default_key: :pos_x,                list: nil, type: :float },
      pos_y:                { prompt: "          Pos Y (cm):",      default_key: :pos_y,                list: nil, type: :float },
      num_steps:            { prompt: "[MARCHES] Nombre:",         default_key: :num_steps,            list: nil, type: :integer },
      step_thickness:       { prompt: "          Épaisseur (cm):",  default_key: :step_thickness,      list: nil, type: :float },
      clockwise:            { prompt: "          Rotation:",        default_key: :clockwise,            list: "Clockwise|Anti-clockwise", type: :bool },
      total_rotation_angle: { prompt: "          Angle (°):",       default_key: :total_rotation_angle, list: nil, type: :float },
      material_type:        { prompt: "[MATIÈRE] Bois Marches:",   default_key: :material_type,        list: "Bois Clair|Bois Foncé", type: :string },
      post_material_same:   { prompt: "          Poteau identique:", default_key: :post_material_same,   list: "Oui|Non", type: :bool },
      demo_mode:            { prompt: "[SYSTÈME] Mode Démo:",       default_key: :demo_mode,            list: "Oui|Non", type: :bool }
    }.freeze

    # Règles de validation liées aux clés du SCHEMA
    VALIDATION_RULES = {
      height_opening: { min: 5, max: 1000 },
      width_opening: { min: 5, max: 1000 },
      length_opening: { min: 5, max: 1000 },
      post_diameter: { min: 5, max: 100 },
      post_section_w: { min: 5, max: 100 },
      post_section_l: { min: 5, max: 100 },
      pos_x: { min: -5000, max: 5000 },
      pos_y: { min: -5000, max: 5000 },
      num_steps: { min: 1, max: 500 },
      step_thickness: { min: 1, max: 50 },
      total_rotation_angle: { min: 0, max: 360 }
    }.freeze

    def self.show_dialog
      begin
        StairObliqueLogger.info("[STAIR PLUGIN] Lancement de la boîte de dialogue...")
        params = Config.all
        
        # Construction automatique via le SCHEMA
        prompts = SCHEMA.values.map { |v| v[:prompt] }
        lists    = SCHEMA.values.map { |v| v[:list] }
        defaults = SCHEMA.keys.map { |key| build_default_for(key, params) }
        
        input = UI.inputbox(prompts, defaults, lists, "Paramètres de l'escalier")
        return unless input

        # Mapping des résultats : on crée un Hash { clé_schema => valeur_saisie }
        # Cela supprime définitivement la dépendance aux index input[0], input[1]...
        user_data = SCHEMA.keys.zip(input).to_h
        
        validated_params = validate_and_sanitize(user_data)
        apply_configuration(validated_params)
        execute_generation
        
      rescue ArgumentError => e
        UI.messagebox("Erreur de validation : #{e.message}", MB_OK)
      rescue StandardError => e
        StairObliqueLogger.error("[STAIR PLUGIN] Erreur: #{e.message}\n#{e.backtrace.join("\n")}")
        UI.messagebox("Erreur système : Consultez les logs.", MB_OK)
      end
    end

    private

    # Gère la récupération des valeurs par défaut de manière dynamique
    def self.build_default_for(key, params)
      case key
       # 1. Cas des Booléens / Enums (SANS conversion)  
      when :post_is_circular then params[:post_is_circular] ? "Circulaire" : "Rectangulaire"
      when :post_dimension_w then (params[:post_is_circular] ? params[:post_diameter] : params[:post_section_w])&.to_cm
      when :large_diagonal   then params[:large_diagonal] ? "Grande" : "Petite"
      when :clockwise        then params[:clockwise] ? "Clockwise" : "Anti-clockwise"
      when :post_material_same then params[:post_material_same_as_steps] ? "Oui" : "Non"
      when :demo_mode        then params[:demo_mode] ? "Oui" : "Non"
      # 2. Cas des valeurs numériques PURES (SANS conversion .to_cm)
      when :num_steps, :total_rotation_angle
        params[SCHEMA[key][:default_key]].to_s # On convertit juste en texte pour l'UI      
      # 3. Cas des dimensions physiques (AVEC conversion .to_cm)
      else
        # Pour toutes les autres dimensions (height, width, etc.)
        val = params[SCHEMA[key][:default_key]]
        val.respond_to?(:to_cm) ? val.to_cm : val
      end.to_s

    end

    def self.validate_and_sanitize(user_data)
      validated = {}

      user_data.each do |key, value|
        config = SCHEMA[key]
        label = config[:prompt].split(':').first # Nettoyage du label pour l'erreur

        case config[:type]
        when :float
          num = value.to_f
          # Gestion du cas spécial Poteau (Diamètre vs Largeur)
          v_key = (key == :post_dimension_w) ? (user_data[:post_is_circular] == "Circulaire" ? :post_diameter : :post_section_w) : key
          check_range(num, v_key, label)
          validated[v_key] = num
        when :integer
          num = value.to_i
          check_range(num, key, label)
          validated[key] = num
        when :bool
          # On considère "Oui", "Circulaire", "Grande", "Clockwise" comme TRUE
          validated[key] = ["Oui", "Circulaire", "Grande", "Clockwise"].include?(value)
        when :string
          validated[key] = value.to_s.strip
        end
      end
      validated
    end

    def self.check_range(val, key, label)
      rule = VALIDATION_RULES[key]
      return if rule.nil?
      if val < rule[:min] || val > rule[:max]
        raise ArgumentError, "#{label} : doit être entre #{rule[:min]} et #{rule[:max]} (reçu #{val})"
      end
    end

    def self.apply_configuration(params)
      # Application propre vers Config
      Config.set(:height_opening, params[:height_opening].cm)
      Config.set(:width_opening,  params[:width_opening].cm)
      Config.set(:length_opening, params[:length_opening].cm)
      Config.set(:post_is_circular, params[:post_is_circular])
      
      # Gestion dynamique du diamètre/largeur
      if params[:post_is_circular]
        Config.set(:post_diameter, params[:post_diameter].cm)
      else
        Config.set(:post_section_w, params[:post_section_w].cm)
      end

      Config.set(:post_section_l, params[:post_section_l].cm)
      Config.set(:large_diagonal, params[:large_diagonal])
      Config.set(:pos_x, params[:pos_x].cm)
      Config.set(:pos_y, params[:pos_y].cm)
      Config.set(:num_steps, params[:num_steps])
      Config.set(:step_thickness, params[:step_thickness].cm)
      Config.set(:clockwise, params[:clockwise])
      Config.set(:total_rotation_angle, params[:total_rotation_angle])
      Config.set(:material_type, params[:material_type])
      Config.set(:post_material_same_as_steps, params[:post_material_same])
      Config.set(:demo_mode, params[:demo_mode])
    end

    def self.execute_generation
      if Generator.start_demo_or_generate
        UI.messagebox("✓ Succès : L'escalier a été généré.", MB_OK)
      else
        UI.messagebox("✗ Erreur : La génération a échoué.", MB_OK)
      end
    end
  end
end
