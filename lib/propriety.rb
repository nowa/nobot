# 礼法

module Jabber
  
  module Nobot
    
    module BuiltInCommand
      def say_hi(to)
        return unless @body.contacts.new_online?(to)
        hour = Time.now.strftime("%H").to_i
        hi = nil
        if hour >= 0 and hour < 6
          hi = "Hi，想不到你也是长夜漫漫无心睡眠挖？"
        elsif hour >= 6 and hour < 8
          hi = "早起的鸟儿有虫虫吃，早哈"
        elsif hour >= 8 and hour < 11
          hi = "早上好哈～～～"
        elsif hour >= 11 and hour < 13
          hi = "一股饭菜的香味，你吃饭没？"
        elsif hour >= 13 and hour < 17
          hi = "下午人总是有点困，偶要趴会..."
        elsif hour >= 17 and hour < 20
          hi = "晚饭吃没？外面现在车真堵！"
        elsif hour >= 20 and hour <= 23
          hi = "吃完饭后跟老婆一起看看电视，真惬意啊～～～"
        end
        Logger.p "say hi to #{to}: #{hi}"
        @body.say(to, hi)
      end
    end
    
    module Propriety
      def when_saw(pres=nil)
        return if pres.nil?
        say_hi(pres.from.to_s.sub(/\/.+$/, ''))
      end
    end
    
  end
  
end