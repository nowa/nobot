# 为nobot提供基础网络服务，包括nobot机器人的上下线，消息接受以及发送等

module Jabber
  
  module Nobot
    
    class Net
      attr_reader :client
      attr_reader :listen_thread
      attr_accessor :brain
      attr_accessor :need_reconnect

      def initialize(config)
        @config = config || {}
        @listen_thread = Thread.current
        @connected = false
        @need_reconnect = false
      end

      def connect
        Logger.p "connecting..."
        jid = JID.new(@config[:jabber_id])
        @client = Client.new(jid)
        @client.connect
        @client.auth(@config[:password])
        @connected = true
        presence(@config[:presence], @config[:status], @config[:priority])
        Logger.p "Nobot(#{@config[:jabber_id]}) connected."
        @need_reconnect = !@need_reconnect

        start_listener
      end

      def disconnect
        if @connected
          @client.close
          @connected = false
        end
      end

      def wakeup
        Logger.p "wakeuping..."
        @listen_thread.wakeup
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
          Logger.p "#{pres.from.to_s.sub(/\/.+$/, '')} changed presence: #{pres.show.to_s.inspect}, #{pres.status.to_s}"
        end

        roster = Roster::Helper.new(@client)
        roster.add_subscription_request_callback do |item, pres|
          begin
            roster.accept_subscription(pres.from)
            deliver(@config[:master], "#{pres.from} 加我为好友了")
            Logger.p "Subscription from #{pres.from} accepted."
          rescue Exception => e
            deliver(@config[:master], "接受好友添加（来自：#{pres.from}）请求时产生一个异常：#{e}\n偶将于3秒后尝试自我重启以重新捕捉该请求")
            sleep(3)
            @need_reconnect = true
            wakeup
          end
        end

        Thread.stop
        if @need_reconnect
          disconnect
          sleep(1)
          connect
        end
      end
    end
    
  end
  
end