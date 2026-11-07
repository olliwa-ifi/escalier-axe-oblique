module StairPluginSquare
  module Tools

    def self.intersect_with_box_small(origin, vector, p)
      x_min, x_max = 0, p[:length_opening]
      y_min, y_max = 0, p[:width_opening]
      eps = 1e-6
      
      t_vals = []
      
      if vector.x.abs > eps
        t_left = (x_min - origin.x) / vector.x
        t_right = (x_max - origin.x) / vector.x
        t_vals << t_left if t_left > 0.01
        t_vals << t_right if t_right > 0.01
      end
      
      if vector.y.abs > eps
        t_bottom = (y_min - origin.y) / vector.y
        t_top = (y_max - origin.y) / vector.y
        t_vals << t_bottom if t_bottom > 0.01
        t_vals << t_top if t_top > 0.01
      end
      
      valid_t = t_vals.select do |t|
        hit_pt = origin.offset(vector, t)
        hit_pt.x.between?(x_min - eps, x_max + eps) && 
        hit_pt.y.between?(y_min - eps, y_max + eps)
      end
      
      if valid_t.empty?
        if origin.x.between?(x_min, x_max) && origin.y.between?(y_min, y_max)
          return origin
        end
        return nil
      end
      
      origin.offset(vector, valid_t.min)
    end


    def self.intersect_with_box_large(origin, vector, p)
      x_min = 0.0
      x_max = p[:length_opening].to_f
      y_min = 0.0
      y_max = p[:width_opening].to_f
      eps = 0.1.mm.to_f

      dir = vector.normalize
      t_vals = []

      if dir.x.abs > eps
        [x_min, x_max].each do |x_bound|
          t = (x_bound - origin.x) / dir.x
          if t > 0
            pt = origin.offset(dir, t)
            if pt.y >= y_min - eps && pt.y <= y_max + eps
              t_vals << t
            end
          end
        end
      end

      if dir.y.abs > eps
        [y_min, y_max].each do |y_bound|
          t = (y_bound - origin.y) / dir.y
          if t > 0
            pt = origin.offset(dir, t)
            if pt.x >= x_min - eps && pt.x <= x_max + eps
              t_vals << t
            end
          end
        end
      end

      return nil if t_vals.empty?
      best_t = t_vals.max
      origin.offset(dir, best_t)
    end

    def self.draw_guide_circle(entities, center, radius)
      normal = Geom::Vector3d.new(0, 0, 1)
      entities.add_circle(center, normal, radius)
    end

    def self.orient_faces_outward(entities)
      centroid = calculate_global_centroid(entities)
      entities.grep(Sketchup::Face).each do |face|
        face_center = calculate_face_centroid(face)
        vector_outward = face_center - centroid
        face.reverse! if vector_outward.dot(face.normal) < 0
      end
    end

    def self.calculate_global_centroid(entities)
      faces = entities.grep(Sketchup::Face)
      return Geom::Point3d.new(0,0,0) if faces.empty?
      sum_x = sum_y = sum_z = total_area = 0.0
      faces.each do |f|
        c = f.bounds.center; a = f.area
        sum_x += c.x * a; sum_y += c.y * a; sum_z += c.z * a; total_area += a
      end
      total_area == 0 ? Geom::Point3d.new(0,0,0) : Geom::Point3d.new(sum_x / total_area, sum_y / total_area, sum_z / total_area)
    end

    def self.calculate_face_centroid(face)
      v = face.vertices
      sx = sy = sz = 0.0
      v.each { |vert| p = vert.position; sx += p.x; sy += p.y; sz += p.z }
      Geom::Point3d.new(sx / v.length, sy / v.length, sz / v.length)
    end

    def self.on_same_wall?(p1, p2, p)
      eps = 0.01
      return true if (p1.x - p2.x).abs < eps && ((p1.x).abs < eps || (p1.x - p[:length_opening]).abs < eps)
      return true if (p1.y - p2.y).abs < eps && ((p1.y).abs < eps || (p1.y - p[:width_opening]).abs < eps)
      false
    end

    def self.find_correct_corner(pointA, pointB, pointC, p)
      eps = 0.01
      x_min, x_max = 0, p[:length_opening]
      y_min, y_max = 0, p[:width_opening]
      wallB = nil
      wallC = nil
      # Identification du mur pour le point B
      wallB = 0 if (pointB.x - x_min).abs < eps
      wallB = 1 if (pointB.x - x_max).abs < eps
      wallB = 2 if (pointB.y - y_min).abs < eps
      wallB = 3 if (pointB.y - y_max).abs < eps
      # Identification du mur pour le point C
      wallC = 0 if (pointC.x - x_min).abs < eps
      wallC = 1 if (pointC.x - x_max).abs < eps
      wallC = 2 if (pointC.y - y_min).abs < eps
      wallC = 3 if (pointC.y - y_max).abs < eps

      if wallB && wallC
        # Le coin est l'intersection des deux murs identifiés
        # Si l'un des murs est le mur 0 (x_min) ou le mur 1 (x_max)
        x_coord = (wallB == 0 || wallC == 0) ? x_min : x_max
        # Si l'un des murs est le mur 2 (y_min) ou le mur 3 (y_max)
        y_coord = (wallB == 2 || wallC == 2) ? y_min : y_max
        return Geom::Point3d.new(x_coord, y_coord, pointA.z)
      end
      nil
    end

    # Méthode utilitaire pour calculer l'enveloppe convexe (Monotone Chain)
    def self.convex_hull(points)
      return points if points.length <= 2

      # Trier les points par X, puis par Y
      sorted = points.sort_by { |p| [p.x, p.y] }

      # Fonction pour déterminer l'orientation (produit vectoriel 2D)
      # Retourne > 0 pour un virage à gauche, < 0 pour la droite, 0 pour colinéaire
      cross_product = lambda do |o, a, b|
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
      end

      # Construction de la coque inférieure
      lower = []
      sorted.each do |p|
        while lower.length >= 2 && cross_product.call(lower[-2], lower[-1], p) <= 0
          lower.pop
        end
        lower << p
      end

      # Construction de la coque supérieure
      upper = []
      sorted.reverse_each do |p|
        while upper.length >= 2 && cross_product.call(upper[-2], upper[-1], p) <= 0
          upper.pop
        end
        upper << p
      end

      # Fusionner les deux (enlever le dernier point de chaque car il est répété)
      lower[0...-1] + upper[0...-1]
    end

  end
end