module StairPluginSquare
  module Config
    # Log d'initialisation au chargement du fichier
    StairObliqueLogger.log("Module Config initialisé", :debug)
    
    VERSION = "1.0.4"

    # --- DÉFINITION DES MATIÈRES (COULEURS) ---
    # On définit des constantes de couleurs RGB
    module Materials
      # Bois Clair : Teinte beige/blonde (R: 225, G: 190, B: 150)
      WOOD_LIGHT = Sketchup::Color.new(225, 190, 150)
      
      # Bois Foncé : Teinte brun profond/acajou (R: 90, G: 50, B: 30)
      WOOD_DARK  = Sketchup::Color.new(90, 50, 30)
    end

    @@params = {
      width_opening: 100.cm,
      length_opening: 100.cm,
      height_opening: 300.cm,
      step_thickness: 5.cm,
      num_steps: 12,
      total_rotation_angle: 180.0,
      post_diameter: 10.cm,
      post_is_circular: true, 
      large_diagonal: true,
      post_section_w: 10.cm,
      post_section_l: 10.cm,
      clockwise: true,
      pos_x: 200.cm,
      pos_y: 200.cm,
      demo_mode: true,

      # --- Paramètres de sélection des matières ---
      material_type: "Bois Clair", 
      post_material_same_as_steps: true 
    }

    def self.get(key); @@params[key]; end
    def self.set(key, value); @@params[key] = value; end
    def self.all; @@params; end
  end
end
