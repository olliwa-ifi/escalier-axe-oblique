module StairPluginSquare
  module Config
    # Log d'initialisation au chargement du fichier
    StairObliqueLogger.log("Module Config initialisé", :debug)
    
    VERSION = "1.0.2"

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
      demo_mode: true 

    }

    def self.get(key); @@params[key]; end
    def self.set(key, value); @@params[key] = value; end
    def self.all; @@params; end
  end
end
