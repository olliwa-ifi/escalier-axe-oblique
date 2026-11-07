# ==========================================================================
# LOGIQUE PETITE DIAGONALE (CALCUL + DESSIN)
# ==========================================================================

module StairPluginSquare
  module DiagSmall
    def self.generate_steps_small_diagonal(p, p_start, p_end, post_dir, post_length, assembly_entities, plugin_v, thickness)
      num_steps_int = p[:num_steps].to_i
      num_steps_f = p[:num_steps].to_f
      
      total_rot = p[:total_rotation_angle].to_f
      base_angle = p[:clockwise] ? Math::PI : 0.0
      multiplier = p[:clockwise] ? -1 : 1
      rot_suffix = p[:clockwise] ? "cw" : "acw"

      # --- A. CALCUL ---
      total_rot_rad = total_rot * (Math::PI / 180.0)
      angle_per_step_rad = total_rot_rad / num_steps_f
      
      # --- B. DESSIN 3D ---
      model = Sketchup.active_model
      
      (0...num_steps_int).each do |i|
        z_step = ((p[:height_opening] - 1.mm) / num_steps_f) * (i + 1)
        t = [z_step / p[:height_opening].to_f, 1.0].min
        
        pointA = p_start.offset(post_dir, t * post_length)
   
        current_angle_rad = base_angle + (i * angle_per_step_rad * multiplier)
        next_angle_rad = current_angle_rad + (angle_per_step_rad * multiplier)
        
        vec1 = Geom::Vector3d.new(Math.cos(current_angle_rad), Math.sin(current_angle_rad), 0)
        vec2 = Geom::Vector3d.new(Math.cos(next_angle_rad), Math.sin(next_angle_rad), 0)

        origin_2d = Geom::Point3d.new(pointA.x, pointA.y, 0)

        # APPEL AU MODULE TOOLS
        pointB_2d = StairPluginSquare::Tools.intersect_with_box_small(origin_2d, vec1, p)
        pointC_2d = StairPluginSquare::Tools.intersect_with_box_small(origin_2d, vec2, p)

        pointB = pointB_2d ? pointB_2d.offset(Z_AXIS, z_step) : nil
        pointC = pointC_2d ? pointC_2d.offset(Z_AXIS, z_step) : nil 

        if pointB && pointC
          step_def = model.definitions.add("Step_Small_Diag_#{rot_suffix}_#{i+1}_v#{plugin_v}")
          ents = step_def.entities
          
          pts_top = [pointA, pointB]

          if !StairPluginSquare::Tools.on_same_wall?(pointB, pointC, p)
            pointM = StairPluginSquare::Tools.find_correct_corner(pointA, pointB, pointC, p)
            pts_top << pointM if pointM
          end
          pts_top << pointC

          pts_bottom = pts_top.map { |pt| pt.offset(Z_AXIS, -thickness) }
          
          ents.add_face(pts_top) rescue nil
          ents.add_face(pts_bottom) rescue nil
          (0...pts_top.length).each do |idx|
            n_idx = (idx + 1) % pts_top.length
            ents.add_face(pts_top[idx], pts_top[n_idx], pts_bottom[n_idx], pts_bottom[idx]) rescue nil
          end

          StairPluginSquare::Tools.orient_faces_outward(ents)
          assembly_entities.add_instance(step_def, Geom::Transformation.new([0,0,0]))
          
          StairObliqueLogger.log("Marche #{i+1} (SmallDiag) générée", :debug)
        else
          StairObliqueLogger.log("Saut de la marche #{i+1} (SmallDiag) : Intersection manquante", :debug)
        end
      end
    end
  end
end
