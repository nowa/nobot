require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster'
require "rexml/document"
require 'yaml'
require 'cgi'
require 'iconv'

Jabber::debug = false

module Jabber

  module Nobot
  
    class Logger
      @@debug = false
      
      def Logger.p(log)
        puts log if @@debug
      end
    end
    
    require 'lib/brain'
    require 'lib/net'
    require 'lib/contact'
    require 'lib/dump'
    
    module DictSpec
      def add_dict_spec(word=nil, mean=nil, sender=nil)
        return unless word or mean
        return [false, "你不是主人，不能覆盖已经存在的词条！"] if @dict_spec["dict_spec"]["#{word}"] and !@config[:master].include?(sender)
        @dict_spec["dict_spec"]["#{word}"] = mean
        dump_dict_spec
        return [true, "添加成功"]
      end
    end
  
    class Bot
      include DictSpec
      include Dump
      
      attr_reader :net
      attr_reader :config
      attr_reader :dict_spec
      attr_reader :contacts
      
      def initialize(config)
        @config = config || {}
        if @config[:name].nil? or @config[:name].length == 0
          @config[:name] = @config[:jabber_id].sub(/@.+$/, '')
        end
      
        unless @config[:master].is_a?(Array)
          @config[:master] = [@config[:master]]
        end
      
        @contacts = Contacts.new
        @brain = Brain.new({
          :master => @config[:master]
        })
        @net = Net.new({
          :jabber_id => @config[:jabber_id], 
          :password => @config[:password],
          :presence => @config[:presence],
          :priority => @config[:priority],
          :status => @config[:status],
          :master => @config[:master]
        })
        @net.brain = @brain
        @brain.body = self
        
        @dict_spec = YAML::load( File.open('config/dict_spec.yml') )
        load_config
      end
    
      def born
        @net.connect
      end
    
      def sleep
        dump
        @net.disconnect
      end
      
      def reborn
        dump
        @net.need_reconnect = true
        @net.wakeup
      end
      
      def load_config
        conf = YAML::load(File.open('config/robot.yml'))
        if conf[:status]
          @config[:status] = conf[:status]
          self.status = conf[:status]
        end
        
        if conf[:presence]
          @config[:presence] = conf[:presence]
          self.presence = conf[:presence]
        end
        
        if conf[:master]
          @config[:master] = conf[:master].is_a?(Array) ? conf[:master] : conf[:master].split(',')
        end
        
        if conf[:name]
          @config[:name] = conf[:name]
        end
      end
      
      def say(to, msg)
        @net.deliver(to, msg)
        return nil
      end
      
      def report(msg)
        @net.deliver(@config[:master], msg)
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
        @config[:presence] = presence
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
        @config[:status] = status
        @net.presence(@config[:presence], status, @config[:priority])
      end
    end
  
  end

end