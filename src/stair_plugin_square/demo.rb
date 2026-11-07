module StairPluginSquare
  module Demo
    SCENARIOS = [
      { id: 1, pos_x: 0.cm,   pos_y: 0.cm,   large_diagonal: false, clockwise: true,  post_is_circular: true },
      { id: 2, pos_x: 0.cm,   pos_y: 200.cm, large_diagonal: false, clockwise: false, post_is_circular: false },
      { id: 3, pos_x: 200.cm, pos_y: 0.cm,   large_diagonal: true,  clockwise: true,  post_is_circular: true },
      { id: 4, pos_x: 200.cm, pos_y: 200.cm, large_diagonal: true,  clockwise: false, post_is_circular: false }
    ]

    def self.run_all
      model = Sketchup.active_model
      model.start_operation('Demo Staircase Generation', true)
      
      StairObliqueLogger.log("Lancement du mode DEMO : Génération des 4 scénarios de test", :info)
      
      begin
        SCENARIOS.each do |scenario|
          # Log détaillé pour chaque scénario
          diag = scenario[:large_diagonal] ? "Large" : "Small"
          sens = scenario[:clockwise] ? "CW" : "CCW"
          poteau = scenario[:post_is_circular] ? "Circulaire" : "Carré"
          
          StairObliqueLogger.log("Exécution Scénario ##{scenario[:id]} [Diag: #{diag}, Sens: #{sens}, Poteau: #{poteau}]", :debug)
          
          # Application des paramètres
          Config.set(:pos_x, scenario[:pos_x])
          Config.set(:pos_y, scenario[:pos_y])
          Config.set(:large_diagonal, scenario[:large_diagonal])
          Config.set(:clockwise, scenario[:clockwise])
          Config.set(:post_is_circular, scenario[:post_is_circular])
          
          # Génération effective
          StairPluginSquare::Generator.generate
        end
        
        # On repasse le mode demo à false pour revenir à l'utilisation normale
        Config.set(:demo_mode, false)
        
        model.commit_operation
        StairObliqueLogger.log("Mode DEMO terminé : Tous les cas ont été traités avec succès", :info)
        
        return true 
        
      rescue => e
        model.abort_operation
        StairObliqueLogger.log("ERREUR durant le mode DEMO : #{e.message}", :error)
        StairObliqueLogger.debug(e.backtrace.join("\n"))
        return false
      end
    end
  end
end
