#= How to create a widget and use it on ubiquo_design
#
#== Widgets
#
#The _ubiquo_widgets_ allow the reuse of typical blocks of logic and views on your public website.
#
#We combine the simplicity of these widgets with the ubiquo_design models (pages and blocks) to build the website.
#
#=== How to use it
#
#Let's see an example of a widget that displays the last news. The first step is using the _ubiquo_widget_ widget to build the skeleton:
#
#  script/generate ubiquo_widget last_news news_to_show:integer
#
#This will create the views directory <tt>app/views/widgets/last_news</tt>, the widget main file <tt>app/widgets/last_news.rb</tt>, the associated model and all the corresponding tests. The file <tt>last_news.rb</tt> looks like this:
#
#  Widget.behaviour :last_news do |widget|
#    ...
#  end
#
#This is equivalent to a piece of a controller, and all the code you put in the block will be executed in the controller space.
#
#By default, the view of the widget is located at <tt>app/views/widgets/NAME/show.html.erb</tt>.
#
#== Creating the widget model
#
#A widget has an associated model (subclass of _Widget_), since we are always rendering an instance of a model.
#
#You can edit the associated model (<tt>app/models/widgets/last_news.rb</tt>) and use the class method _allowed_options_ to define the configurable attributes. We can also add validations over these fields:
#
#  class LastNews < Widget
#    self.allowed_options = [:news_to_show]
#    validates_numericality_of :news_to_show
#
#    def last_news(number = nil)
#      News.all(:limit => number || news_to_show, :order => :publish_date)
#    end
#  end
#
#== Implementing the widget
#
#Edit <tt>widgets/last_news.rb</tt>:
#
#  Widget.behaviour :last_news do |widget|
#    @news = widget.last_news(params[:max_news])
#  end
#
#And on the view:
#
#  <% @news.each do |news| %>
#    <p><%= news.body %></p>
#  <% end %>
#
#As the widget is configurable (to set the default :news_to_show), we can prepare an ubiquo view, which could look like this:
#
#  # app/views/widgets/last_news/ubiquo/_form.html.erb
#  <%= widget_header widget %>
#  <% widget_form(page, widget) do |f| %>
#      <%= f.label :news_to_show, Widget.human_attribute_name :news_to_show %><br/>
#      <%= f.text_field :default_news_to_show, %>
#      <%= widget_submit %>
#  <% end %>
#
#== Reading from params
#
#All the params that your widget needs can be accessed from the params structure, since the widget behaviour is executed in the controller scope
#
#And that's it, you should now be able to insert the widget on your page, configure it, publish the page and see the results on the public page.
#
#== Testing the widget
#
#The skeleton created the basic infrastructure to test the widget:
#
#* unit/widgets/name_test.rb: Test the associated model.
#* functional/widgets/name_test.rb: Test the widget and public views.
#* functional/widgets/ubiquo/name_test.rb: Test the ubiquo views.
#
#Check the bundled tests of existing widgets for more details and examples.
module UbiquoDesign
  module UbiquoWidgets
    # Define error exceptions
    class WidgetError < StandardError; end
    class WidgetNotFound < WidgetError; end
    class WidgetTemplateNotFound < WidgetError; end

    # Returns an array with all the available widgets
    #
    # Example: available_widgets.include?(:my_widgets)
    def available_widgets
      ::Widget.behaviours.keys
    end

    # Run a widget behaviour, given a +widget+ instance
    def run_behaviour widget
      ::Widget.behaviours[widget.key][:proc].bind(self).call(widget)
    end

    # Renders the widget as a string
    #
    # The +widget+ is the instance to be rendered
    def render_widget widget
      widget_name = widget.key
      unless available_widgets.include?(widget_name)
        require_dependency "widgets/#{widget_name}_widget"
        raise WidgetNotFound.new("Widget #{widget_name} not found") unless available_widgets.include?(widget_name)
      end
      run_behaviour(widget)
      render_to_string :file => File.join("widgets", widget_name.to_s, "show.html.erb")
    end

  end
end
