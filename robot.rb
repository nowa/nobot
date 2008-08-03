#!/usr/bin/ruby

require 'lib/nobot'

nowa = Jabber::Nobot::Bot.new({
  :name      => 'nowa.robot',
  :jabber_id => 'nowa.robot@gmail.com/Nobot.v0.1',
  :password  => 'nfish677266',
  :master    => ['nowazhu@gmail.com', 'halflifexp@gmail.com'],
  :presence  => :chat,
  :priority  => 5,
  :status    => 'nowa是我的主人'
})

nowa.preset_command({
  :command     => 'curl',
  :syntax      => 'curl <url>',
  :description => '获取指定url的http头',
  :regex       => /^curl\s+.+$/
}) { |body, sender, message| 
  begin
    `curl -I #{message}`
  rescue Exception => e
    body.report("curl #{message}时发生一个异常：#{e}")
    '有一个错误产生，我要向我的主人报告下'
  end
}

nowa.preset_command({
  :command     => 'cstatus',
  :syntax      => 'cstatus <string>',
  :description => '更改机器人的签名',
  :regex       => /^cstatus\s+.+$/
}) { |body, sender, message| 
  body.status = message
  body.dump_config
  body.say(body.config[:master], "#{sender}把我的签名改成了：#{message}")
}

nowa.preset_command({
  :command      => 'dict',
  :syntax       => 'dict <word>',
  :description  => '中英互译，使用dict.cn的服务',
  :regex        => /^dict\s+.+$/
}) { |body, sender, message|
  trans = ""
  spec = body.dict_spec
  if spec["dict_spec"]["#{message}"]
    trans = spec["dict_spec"]["#{message}"]
  else
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
      body.report("#{sender} 查询 #{message} 时发生异常 ：\n #{e}")
      trans = "查询时有一个错误产生，我要向我的主人报告下"
    end
  end
  trans
}

nowa.preset_command({
  :command      => 'dict add',
  :syntax       => 'dict add <word mean>',
  :description  => '为dict命令添加特别词语的释义，如“nowa”的解释等',
  :regex        => /^dict\s+add\s+.+\s+.+$/
}) { |body, sender, message|
  begin
    word = [message.sub(/^add\s+(\S+)\s+.*/, '\1'), message.sub(/^add\s+\S+\s+(.*)$/, '\1')]
    result = body.add_dict_spec(word[0], word[1], sender)
    body.say(body.config[:master], "#{sender} 添加了生词\n#{message}") if result[0]
    result[1]
  rescue Exception => e
    body.report("#{sender} 添加单词释义 #{message} 时发生异常 ：\n #{e}")
    "添加生词时有一个错误产生，我要向我的主人报告下"
  end
}

nowa.preset_command({
  :command      => 'cpn',
  :syntax       => 'cpn <手机号码>',
  :description  => '查手机号码归属地，输入前7位即可',
  :regex        => /^cpn\s+.+$/
}) { |body, sender, message| 
  result = ""
  begin
    converter = Iconv.new('UTF-8', 'GBK')
    source = converter.iconv(`curl http://www.imobile.com.cn/search.php?searchkeyword=#{message}&searchcategory=号码地区`)
    match = /class="title_txt_pi_none">[0-9\+]+?<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>(.|\n)*class="title_txt_pi_none">(.+?)<\/font><\/td>/i.match(source)
    result = match ? "号码段：#{message}\n归属地：#{match[2]}\n卡类型：#{match[4]}\n邮政编码：#{match[6]}\n电话区号：#{match[8]}" : "非常抱歉，没有查询到你所需要的内容！"
  rescue Exception => e
    body.report("#{sender} 查询 #{message} 时发生异常 ：\n #{e}")
    result = "查询时有一个错误产生，我要向我的主人报告下"
  end
  result
}

nowa.preset_command({
  :command      => 'reborn',
  :syntax       => 'reborn [seconds]',
  :description  => '重启机器人，管理员专用。可以指定延迟秒数',
  :regex        => /^reborn(\s+?[0-9\-]+?)?$/
}) { |body, sender, message|
  begin
    delay = message.nil? ? 3 : (message.length == 0 ? 3 : message.to_i.abs)
    if body.config[:master].include?(sender)
      body.say(body.config[:master], "#{sender} 即将于#{delay}秒后重启偶！")
      sleep(delay)
      body.reborn
      nil
    else
      "你不是管理员，不能重启偶"
    end
  rescue Exception => e
    body.report("#{sender} 重启机器人时发生异常 ：\n #{e}")
    "重启时发生异常，偶要报告向主人报告下"
  end
}

nowa.preset_command({
  :command      => 'z',
  :syntax       => 'z <接受人 内容>',
  :description  => '转告某人，接受人必须是gtalk或者gtalk的email前缀',
  :regex        => /^z\s+.+[\n\s]+.+$/
}) { |body, sender, message|
  msg = [message.sub(/^(\S+)[\s\n]+.*/, '\1'), message.sub(/^\S+[\s\n]+(.*)$/, '\1')]
  msg[0] = msg[0].include?('@') ? msg[0] : (msg[0].gsub(/\n/, '') + "@gmail.com")
  begin
    body.say(msg[0], "#{sender.sub(/\@.+$/, '')}让我转告你：\n#{msg[1]}")
    body.contacts.set_last_zer(msg[0], sender)
    puts "m-1: #{message[-1]}"
    if message[-1] != 44
      contact = body.contacts.detect(sender)
      contact.enter_z_mode(msg[0]) unless contact.nil?
      body.say(sender, "哇咔咔，你现在进入了z模式，现在你所说的话都将会被转告给#{msg[0].sub(/\@.+$/, '')}。发送quitz给我可以退出z模式。")
    end
    nil
  rescue Exception => e
    body.report("#{sender} 转告时发生异常 ：\n #{e} \n\n#{message}")
    "转告时有一个错误产生，我要向我的主人报告下"
  end
}

nowa.preset_command({
  :command      => 'who',
  :syntax       => 'who',
  :description  => '偶的在线好友列表',
  :regex        => /^who\s?$/
}) { |body, sender, message|
  body.net.send_roser_query
  sleep(1)
  online = ""
  begin
    lists = body.contacts.all().sort.map {|c| c[1]}
    online += "--- 有#{lists.size}人在线：\n\n"
    c = 1
    lists.each { |item|
      online += c.to_s + ". " + item.nickname + (item.presence.show.nil? ? "" : (" - " + item.presence.show.to_s)) + (item.status.nil? ? "" : (" - " + item.status)) + "\n"
      c += 1
    }
  rescue Exception => e
    body.report("#{sender} 查看在线好友时发生异常 ：\n #{e}")
    online = "生成在线好友列表时有一个错误产生，我要向我的主人报告下"
  end
  online
}

nowa.preset_command({
  :command      => 'broadcast',
  :syntax       => 'broadcast <words>',
  :description  => '给所有在线好友放小广播',
  :regex        => /^broadcast\s+.+$/
}) { |body, sender, message|
  begin
    lists = body.contacts.all().values.map {|c| c.gid}
    body.say(lists, "广播(#{sender.sub(/\@.+$/, '')})：#{message}")
    nil
  rescue Exception => e
    body.report("#{sender} 广播时发生异常 ：\n#{message}\n\n #{e}")
    online = "广播时有一个错误产生，我要向我的主人报告下"
  end
}

nowa.born