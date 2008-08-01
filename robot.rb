#!/usr/bin/ruby

require 'lib/nobot'
require 'cgi'
require 'iconv'

nowa = Jabber::Nobot::Bot.new({
  :name      => 'nowa.robot',
  :jabber_id => 'nowa.robot@gmail.com',
  :password  => 'nfish677266',
  :master    => ['nowazhu@gmail.com'],
  :presence  => :chat,
  :priority  => 5,
  :status    => 'nowa是我的主人'
})

nowa.preset_command({
  :syntax      => 'curl <url>',
  :description => '获取指定url的http头',
  :regex       => /^curl\s+.+$/
}) { |body, sender, message| `curl -I #{message}` }

nowa.preset_command({
  :syntax      => 'cstatus <string>',
  :description => '更改机器人的签名',
  :regex       => /^cstatus\s+.+$/
}) { |body, sender, message| 
  body.status = message
  body.say(body.config[:master], "#{sender}把我的签名改成了：#{message}")
}

nowa.preset_command({
  :syntax       => 'dict <word>',
  :description  => '中英互译，使用dict.cn的服务',
  :regex        => /^dict\s+.+$/
}) { |body, sender, message|
  trans = ""
  if message != 'nowa'
    begin
      doc = REXML::Document.new(`curl http://dict.cn/ws.php?q=#{CGI::escape(message)}`)
      root = doc.root
      trans = (root.elements["pron"] ? root.elements["pron"].text + "\n" : '') + root.elements["def"].text
      sent = ""
      sent_index = 1
      root.elements.each("sent") { |element| 
        sent += sent_index.to_s + ". " + element.elements["orig"].text + "\n" + "    " + element.elements["trans"].text + "\n"
        sent_index += 1
      }
      trans += "\n\n例句：\n" + sent if sent != ""
    rescue Exception => e
      body.say(body.config[:master], "#{sender} 查询 #{message} 时发生异常 ：\n #{e}")
      trans = "查询时有一个错误产生，我要向我的主人报告下"
    end
  else
    trans = 'nowa是世界上最帅最好的男人，他是我的主人，是小娘的老公。'
  end
  trans
}

nowa.preset_command({
  :syntax       => 'cpn <手机号码>',
  :description  => '查手机号码归属地，输入前7位即可',
  :regex        => /^cpn\s+.+$/
}) { |body, sender, message| 
  result = ""
  begin
    converter = Iconv.new('UTF-8', 'GBK')
    source = converter.iconv(`curl http://www.imobile.com.cn/search.php?searchkeyword=#{message}&searchcategory=号码地区`)
    match = /class="title_txt_pi_none">[0-9\+]+?<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>/i.match(source)
    result = "号码段：#{message}\n归属地：#{match[2]}\n卡类型：#{match[4]}\n邮政编码：#{match[6]}\n电话区号：#{match[8]}"
  rescue Exception => e
    body.say(body.config[:master], "#{sender} 查询 #{message} 时发生异常 ：\n #{e}")
    result = "查询时有一个错误产生，我要向我的主人报告下"
  end
  result
}

nowa.born