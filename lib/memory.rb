module Jabber
  
  module Nobot
    
    class Memory
      
      attr_reader :cells
      
      def initialize(mem=nil)
        @cells = mem || {}
      end
      
      def parse_path(path=nil)
        return @cells if path.nil?
        path = path.split('/')
        it = ""
        path.each { |p|
          if p != ''
            it += "['#{p}']"
            eval("@cells" + it + " = @cells" + it + " || {}")
          end
        }
        return it
      end
      
      # path=root/path/to/do
      def new_cell(name=nil, value=nil, path=nil)
        return if name.nil?
        nodes = parse_path(path)
        # node[name] = value
        eval("@cells" + nodes + "['#{name}'] = " + (value.nil? ? 'nil' : value.inspect))
        return eval("@cells" + nodes + "['#{name}']")
      end
      
      def del_cell(name=nil, path=nil)
        return if name.nil?
        nodes = parse_path(path)
        # node.delete(name)
        eval("@cells" + nodes + ".delete('" + name + "')")
      end
      
      def cell(name=nil, path=nil)
        return nil if name.nil?
        nodes = parse_path(path)
        node = nil
        eval("node = @cells" + nodes + "['#{name}']")
        return node ? node : new_cell(name, nil, path)
      end
      
      def dump(to='config/mem.yml')
        File.open(to, "w") { |f| YAML.dump(@cells, f)}
      end
      
    end
    
  end
  
end