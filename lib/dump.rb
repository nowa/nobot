# dump to yml file

module Jabber
  
  module Nobot
   
    module Dump
      def dump
        dump_dict_spec
        dump_config
        @brain.mem.dump
      end
      
      def dump_dict_spec(to='config/dict_spec.yml')
        File.open(to, "w") { |f| YAML.dump(@dict_spec, f)}
      end
      
      def dump_config(to='config/robot.yml')
        File.open(to, "w") { |f| YAML.dump(@config, f)}
      end
    end
    
  end
  
end