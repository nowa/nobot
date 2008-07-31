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
    
    module Command
      # Say 'puts foo' or 'p foo' and 'foo' will be written to $stdout.
      #   # The bot will also respond with "'foo' written to $stdout."
      #   add_command(
      #     :syntax      => 'puts <string>',
      #     :description => 'Write something to $stdout',
      #     :regex       => /^puts\s+.+$/,
      #     :alias       => [ :syntax => 'p <string>', :regex => /^p\s+.+$/ ]
      #   ) do |sender, message|
      #     puts "#{sender} says #{message}."
      #     "'#{message}' written to $stdout."
      #   end
      # 
      #   # 'puts!' is a non-responding version of 'puts', and has two aliases,
      #   # 'p!' and '!'
      #   add_command(
      #     :syntax      => 'puts! <string>',
      #     :description => 'Write something to $stdout (without response)',
      #     :regex       => /^puts!\s+.+$/,
      #     :alias       => [ 
      #       { :syntax => 'p! <string>', :regex => /^p!\s+.+$/ },
      #       { :syntax => '! <string>', :regex => /^!\s+/.+$/ }
      #     ]
      #   ) do |sender, message|
      #     puts "#{sender} says #{message}."
      #     nil
      #   end
      def add_command(command, &callback)
        name = command_name(command[:syntax])
        
        # Add the command meta - used in the 'help' command response.
        add_command_meta(name, command)
        
        # Add the command spec - used for parsing incoming commands.
        add_command_spec(command, callback)
        
        # Add any command aliases to the command meta and spec
        unless command[:alias].nil?
          command[:alias].each { |a| add_command_alias(name, a, callback) }
        end
      end
      
      # Returns an Array of masters
      def master
        @config[:master]
      end
      
      # Returns +true+ if the given Jabber id is a master, +false+ otherwise.
      def master?(jabber_id)
        @config[:master].include? jabber_id
      end
      
      private
      
        # Extract the command name from the given syntax
        def command_name(syntax)
          if syntax.include? ' '
            syntax.sub(/^(\S+).*/, '\1')
          else
            syntax
          end
        end
        
        # Add a command alias for the given original +command_name+
        def add_command_alias(command_name, alias_command, callback) #:nodoc:
          original_command = @commands[:meta][command_name]
          original_command[:syntax] << alias_command[:syntax]

          alias_name = command_name(alias_command[:syntax])

          add_command_meta(alias_name, original_command, true)
          add_command_spec(alias_command, callback)
        end
        
        # Add a command meta
        def add_command_meta(name, command, is_alias=false) #:nodoc:
          syntax = command[:syntax]

          @commands[:meta][name] = {
            :syntax      => syntax.is_a?(Array) ? syntax : [syntax],
            :description => command[:description],
            :is_alias    => is_alias
          }
        end
        
        # Add a command spec
        def add_command_spec(command, callback) #:nodoc:
          @commands[:spec] << {
            :regex     => command[:regex],
            :callback  => callback
          }
        end
        
        # Returns the default help message describing the bot's command repertoire.
        # Commands are sorted alphabetically by name, and are displayed according
        # to the bot's and the commands's _public_ attribute.
        def help_message(sender, command_name) #:nodoc:
          if command_name.nil? or command_name.length == 0
            # Display help for all commands
            help_message = "我可以执行以下预设命令:\n\n"

            @commands[:meta].sort.each do |command|
              # Thank you, Hash.sort
              command = command[1]

              if !command[:is_alias] and (master? sender)
                command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
                help_message += "  #{command[:description]}\n\n"
              end
            end
          else
            # Display help for the given command
            command = @commands[:meta][command_name]

            if command.nil?
              help_message = "'#{command_name}' 不是预设的命令，你可以尝试跟我说" +
                  " 'help' 来获得所有预设命令。"
            else
              help_message = ''
              command[:syntax].each { |syntax| help_message += "#{syntax}\n" }
              help_message += "  #{command[:description]} "
            end
          end

          help_message
        end
        
        # Parses the given command message for the presence of a known command by
        # testing it against each known command's regex. If a known command is
        # found, the command parameters are passed on to the callback block, minus
        # the command trigger. If a String result is present it is delivered to the
        # sender.
        #
        # If the bot has not been made public, commands from anyone other than the
        # bot master(s) will be silently ignored.
        def parse_command(sender, message) #:nodoc:
          is_master = master? sender
          
          # 退出处理
          Logger.p "command matching..."

          @commands[:spec].each do |command|
            # if command[:is_public] or is_master
              unless (message.strip =~ command[:regex]).nil?
                params = nil

                if message.include? ' '
                  params = message.sub(/^\S+\s+(.*)$/, '\1')
                end

                response = command[:callback].call(sender, params)
                @body.say(sender, response) unless response.nil?

                return
              end
            # end
          end

          response = "'#{message.strip}' 不是预设的命令，你可以尝试跟我说" +
              " 'help' 来获得所有预设命令。"
          @body.say(sender, response)
        end
    end
  
    class Brain
      include Command
      attr_accessor :body
      
      def initialize(config)
        @config = config || {}
        @received = 'born'
        @sender = @config[:master]
      
        @commands = { :spec => [], :meta => {} }
        add_command(
          :syntax      => 'help [<command>]',
          :description => '返回指定命令的帮助信息，如果不指定命令则返回所有可用命令列表',
          :regex => /^help(\s+?.+?)?$/,
          :alias => [ :syntax => '? [<command>]', :regex  => /^\?(\s+?.+?)?$/ ]
        ) { |sender, message| help_message(sender, message) }
      end
    
      def dispatch
        parse_command(@sender, @received)
      end
    
      def hear(msg, from)
        Logger.p "#{from}: #{msg}"
        @received = msg
        @sender = from
        # @body.say(from, 'I heard.')

        dispatch
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
          Logger.p "#{pres.from.to_s.sub(/\/.+$/, '')} changed presence: #{pres.show}, #{pres.status}"
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
      
      def preset_command(command, &callback)
        @brain.add_command(command, &callback)
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