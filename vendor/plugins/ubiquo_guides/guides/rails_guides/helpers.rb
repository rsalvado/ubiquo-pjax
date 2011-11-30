module RailsGuides
  module Helpers
    def guide(name, url, options = {}, &block)
      plugin = url.gsub('.html','')
      link = content_tag(:a, :href => url) { name }

      if options[:rdoc]
        rdoc = content_tag(:a, :href => "http://rdoc.ubiquo.me/edge/#{plugin}", :class => 'rdoc') { "Rdoc" }
        link = link + " " + rdoc
      end

      result = content_tag(:dt, link)

      if ticket = options[:ticket]
        result << content_tag(:dd, lh(ticket), :class => 'ticket')
      end

      result << content_tag(:dd, capture(&block))
      concat(result)
    end

    def lh(id, label = "Lighthouse Ticket")
      url = "http://rails.lighthouseapp.com/projects/16213/tickets/#{id}"
      content_tag(:a, label, :href => url)
    end

    def author(name, nick, image = 'credits_pic_blank.gif', &block)
      image = "images/#{image}"

      result = content_tag(:img, nil, :src => image, :class => 'left pic', :alt => name)
      result << content_tag(:h3, name)
      result << content_tag(:p, capture(&block))
      concat content_tag(:div, result, :class => 'clearfix', :id => nick)
    end

    def rdoc(plugin)
      concat(content_tag(:a, :href => "http://rdoc.ubiquo.me/edge/#{plugin}", :class => 'rdoc') { "Rdoc" })
    end

    def code(&block)
      c = capture(&block)
      content_tag(:code, c)
    end
  end
end
