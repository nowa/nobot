# 联系人

module Jabber
  
  module Nobot
    
    class Contacts
      def initialize
        @list = {}
      end
      
      def add(pres=nil)
        return if pres.nil?
        item = Contact.new(pres.from.to_s.sub(/\/.+$/, ''), pres)
        if @list[item.gid]
          @list[item.gid].new_online = false
          @list[item.gid].status = item.status unless item.status.nil?
          @list[item.gid].show = item.show unless item.show.nil?
        else
          @list[item.gid] = item
        end
      end
      
      def remove(gid=nil)
        return if gid.nil?
        @list.delete(gid)
      end
      
      def all
        return @list
      end
      
      def new_online?(gid=nil)
        return @list[gid].new_online
      end
    end
    
    class Contact
      attr_reader :gid
      attr_reader :status
      attr_reader :show
      attr_reader :presence
      attr_reader :name
      attr_accessor :nickname
      attr_accessor :new_online
      
      def initialize(jabber_id=nil, pres=nil)
        @gid = jabber_id
        @presence = pres
        @status = pres.status
        @show = pres.show
        @name = @gid.sub(/\@.+$/, '')
        @nickname = @gid.sub(/\@.+$/, '')
        @new_online = true
      end
      
      def status=(status)
        @status = status
      end
      
      def show=(show)
        @show = show
      end
    end
    
  end
  
end