require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'

module Jabber

  module Nobot
  
    class Logger
      def Logger.p(log)
        puts log
      end
    end
  
    class Brain
      attr_accessor :body
      
      def initialize(config)
        @received = 'born'
        @sender = 'god'
        @config = config || {}
      
        @commands = { :spec => [], :meta => {} }
      end
    
      def dispatch
      
      end
    
      def hear(msg, from)
        Logger.p "#{from}: #{msg}"
        @received = msg
        @sender = from
        @body.say(from, 'I heard.')
      
        dispatch_thread = Thread.new do
          dispatch
        end
        dispatch_thread.join
      end
    end
  
    # 为nobot提供基础网络服务，包括nobot机器人的上下线，消息接受以及发送等
    class Net
      attr_reader :client
      attr_reader :listen_thread
      attr_accessor :brain
    
      def initialize(config)
        @config = config || {}
        @listen_thread = Thread.current
        @connected = false
      end
    
      def connect
        jid = JID.new(@config[:jabber_id])
        @client = Client.new(jid)
        @client.connect
        @client.auth(@config[:password])
        @connected = true
        presence(@config[:presence], @config[:status], @config[:priority])
        Logger.p "Nobot(#{@config[:jabber_id]}) connected."
      
        start_listener
      end
    
      def disconnect
        if @connected
          @client.close
        end
      end
    
      # Deliver a message to the specified recipient(s). Accepts a single
      # recipient or an Array of recipients.
      def deliver(to, message)
        if to.is_a?(Array)
          to.each { |t| @client.send(Message.new(t, message)) }
        else
          @client.send(Message.new(to, message))
        end
      end
    
      # Sets the bot presence, status message and priority.
      def presence(presence=nil, status=nil, priority=nil)
        status_message = Presence.new(presence, status, priority)
        @client.send(status_message) if @connected
      end
    
      def start_listener
        @client.add_message_callback do |m|
          # Remove the Jabber resourse, if any
          sender = m.from.to_s.sub(/\/.+$/, '')

          if m.type == :chat && m.body != nil
            parse_thread = Thread.new do
              @brain.hear(m.body, sender)
            end

            parse_thread.join
          end
        end
        
        @client.add_presence_callback do |pres|
          Logger.p "#{pres.from.to_s.sub(/\/.+$/, '')} changed presence: #{pres.show.to_s == '' ? 'online' : pres.show.to_s}, #{pres.status}"
        end
        
        roster = Roster::Helper.new(@client)
        roster.add_subscription_request_callback do |item, pres|
          roster.accept_subscription(pres.from)
          Logger.p "Subscription from #{pres.from} accepted."
        end
        Thread.stop
      end
    end
  
    class Bot
      def initialize(config)
        @config = config || {}
        if @config[:name].nil? or @config[:name].length == 0
          @config[:name] = @config[:jabber_id].sub(/@.+$/, '')
        end
      
        unless @config[:master].is_a?(Array)
          @config[:master] = [@config[:master]]
        end
      
        @brain = Brain.new({
          :master => @config[:master]
        })
        @net = Net.new({
          :jabber_id => @config[:jabber_id], 
          :password => @config[:password],
          :presence => @config[:presence],
          :priority => @config[:priority],
          :status => @config[:status]
        })
        @net.brain = @brain
        @brain.body = self
      end
    
      def connect
        @net.connect
      end
    
      def disconnect
        @net.disconnect
      end
      
      def say(to, msg)
        @net.deliver(to, msg)
      end
    
      # Sets the bot presence. If you need to set more than just the presence,
      # use presence() instead.
      #
      # Available values for presence are:
      #
      #   * nil   : online
      #   * :chat : free for chat
      #   * :away : away from the computer
      #   * :dnd  : do not disturb
      #   * :xa   : extended away
      #
      def presence=(presence)
        @net.presence(presence, @config[:status], @config[:priority])
      end
    
      # Set the bot priority. Priority is an integer from -127 to 127. If you need
      # to set more than just the priority, use presence() instead.
      def priority=(priority)
        @net.presence(@config[:presence], @config[:status], priority)
      end
    
      # Set the status message. A status message is just a String, e.g. 'I am
      # here.' or 'Out to lunch.' If you need to set more than just the status
      # message, use presence() instead.
      def status=(status)
        @net.presence(@config[:presence], status, @config[:priority])
      end
    end
  
  end

end