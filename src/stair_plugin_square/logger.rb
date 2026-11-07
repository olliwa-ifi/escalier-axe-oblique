module StairPluginSquare
  module StairObliqueLogger
    def self.log(message, level = :info)
      timestamp = Time.now.strftime("%H:%M:%S")
      formatted_msg = "[#{timestamp}] [#{level.to_s.upcase}] #{message}"
      
      puts formatted_msg # Console Ruby
      
      if level == :error
        UI.messagebox(formatted_msg)
      end
    end

    def self.info(message)
      log(message, :info)
    end

    def self.debug(message)
      log(message, :debug)
    end

    def self.error(message)
      log(message, :error)
    end
  end
end
