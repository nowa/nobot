module Jabber
  
  module Nobot
    
    class Memory
      
      attr_reader :cells
      
      def initialize(mem=nil)
        @cells = mem.nil? ? {} || mem
      end
      
      def parse_path(path=nil)
        return @cells if path.nil?
        node = @cells
        path = path.split('/')
        path.each { |p|
          if p != ''
            node[p] = {} if !node[p]
            node = node[p]
          end
        }
        return node;
      end
      
      # path=root/path/to/do
      def new_cell(name=nil, value=nil, path=nil)
        return if name.nil?
        node = parse_path(path)
        node[name] = value
      end
      
      def del_cell(name=nil, path=nil)
        return if name.nil?
        node = parse_path(path)
        node.delete(name)
        return node
      end
      
      def cell(name=nil, path=nil)
        return nil if name.nil?
        node = parse_path(path)
        return node[name] ? node[name] : new_cell(name, nil, path)
      end
      
      def dump(to='config/mem.yml')
        File.open(to, "w") { |f| YAML.dump(@config, f)}
      end
      
    end
    
  end
  
end