# ==========================================================================
# LOGIQUE GRANDE DIAGONALE (COMPOSANTS + RELATIF + CLOCKWISE)
# ==========================================================================

module StairPluginSquare
  module DiagLarge
    def self.generate_steps_large_diagonal(p, p_start, post_dir, post_length, assembly_entities, plugin_v)
      num_steps_i = p[:num_steps].to_i
      num_steps_f = p[:num_steps].to_f
      thickness = p[:step_thickness]
      total_rot_rad = p[:total_rotation_angle].to_f * (Math::PI / 180.0) 
      base_angle_rad = p[:clockwise] ? (- Math::PI / 2.0) : 0.0 
      multiplier = p[:clockwise] ? -1 : 1

      # --- A. PRE-CALCULATION PHASE ---
      stair_data = []
      angle_per_step_rad = 2 * Math::PI / num_steps_f 

      r_circle = p[:width_opening] / 2.0
      center_x = r_circle
      center_y = r_circle
             
      (0...num_steps_i).each do |i|
        z_step = ((p[:height_opening] - 0.1.mm) / num_steps_f) * (i + 1)
        t = [z_step / p[:height_opening].to_f, 1.0].min
        
        pointA = p_start.offset(post_dir, t * post_length)
        current_angle_rad = base_angle_rad + ((i + 1) * angle_per_step_rad * multiplier)

        c2_x = center_x + r_circle * Math.cos(current_angle_rad)
        c2_y = center_y + r_circle * Math.sin(current_angle_rad)
        pointB = Geom::Point3d.new(c2_x, c2_y, z_step)
        
        vec_AB_2d = Geom::Vector3d.new(pointB.x - pointA.x, pointB.y - pointA.y, 0)
        origin_2d = Geom::Point3d.new(pointA.x, pointA.y, 0)
        
        # APPEL AU MODULE TOOLS
        pointC_2d = StairPluginSquare::Tools.intersect_with_box_large(origin_2d, vec_AB_2d, p)

        pointC = pointC_2d ? pointC_2d.offset(Z_AXIS, z_step) : nil 
        stair_data << { z: z_step, c1: pointA, c2: pointB, c3: pointC}
      end
      
      # --- B. DRAWING PHASE ---
      model = Sketchup.active_model
      stair_data.each_with_index do |data, i|
        z_lvl = data[:z]
        c1 = data[:c1]
        c2 = data[:c2]
        c3 = data[:c3]
        
        next_step = stair_data[(i + 1) % stair_data.length]
        c4_raw = next_step[:c3]

        if c3 && c4_raw
          c4_planar = Geom::Point3d.new(c4_raw.x, c4_raw.y, z_lvl)
          
          if z_lvl < (p[:height_opening] / 2.0)
            c5_raw = stair_data[(i + 1) % stair_data.length][:c1]
          else
            c5_raw = stair_data[(i - 1) % stair_data.length][:c1]
          end
          c5_planar = c5_raw ? Geom::Point3d.new(c5_raw.x, c5_raw.y, z_lvl) : nil

          begin
            same_wall = StairPluginSquare::Tools.on_same_wall?(c3, c4_planar, p)
            
            step_def = model.definitions.add("Step_Large_Diag_#{p[:clockwise] ? 'cw' : 'acw'}_#{i+1}_v#{plugin_v}")
            ents = step_def.entities
            pts_top = [c1, c3]
            if !same_wall
              corner = StairPluginSquare::Tools.find_correct_corner(c1, c3, c4_planar, p)
              pts_top << corner if corner
            end
            
            pts_top << c4_planar
            pts_top << c5_planar if c5_planar
            
            cleaned_top = StairPluginSquare::Tools.convex_hull(pts_top.compact)
            down_vec = Geom::Vector3d.new(0, 0, -thickness)
            pts_bottom = cleaned_top.map { |pt| pt.offset(down_vec) }
            
            ents.add_face(cleaned_top) rescue nil
            ents.add_face(pts_bottom) rescue nil
             
            (0...cleaned_top.length).each do |j|
              p1 = cleaned_top[j]
              p2 = cleaned_top[(j + 1) % cleaned_top.length]
              ents.add_face(p1, p2, pts_bottom[(j + 1) % cleaned_top.length], pts_bottom[j]) rescue nil
            end
                       
            StairPluginSquare::Tools.orient_faces_outward(ents)
            assembly_entities.add_instance(step_def, Geom::Transformation.new([0,0,0]))
            
            # Remplacement du puts par le logger (debug car très répétitif)
            StairObliqueLogger.log("Marche #{i+1} générée avec succès", :debug)
            
          rescue => e
            StairObliqueLogger.log("CRASH sur Marche #{i+1}: #{e.message}", :error)
            raise e
          end
        else
          StairObliqueLogger.log("Saut de la Marche #{i+1}: Intersection manquante", :debug)
        end
      end
    end
  end
end
