#= Page templates
#
#All pages on the design system belong to a page template which holds
#the view structure for both the public and the ubiquo page. The
#structure of these templates are defined in
#<tt>config/initialitzers/design_structure.rb</tt>.

module Ubiquo::DesignsHelper

  def block_for_design(page, type, num_cols, subblocks = [], options = {})
    default_margin = 1.5
    col_width = ((100 / page.template_cols) * num_cols) - default_margin
    options.reverse_merge!(:class => "column", :style => "width: #{col_width}%")    
    if subblocks.present?
      content_tag(:div, :class => options.delete(:class), :style => options.delete(:style) + ";margin:0") do      
        subblocks.map do |subblock, sb_cols|
          sb_width = (100.to_f * (sb_cols.to_f / num_cols.to_f)) - default_margin
          block_for_design(page, subblock, sb_cols, [], { :style => "width: #{sb_width}%" })
        end
      end
    else
      block = page.blocks.first(:conditions => { :block_type => type.to_s })
      unless block
        raise ActiveRecord::RecordNotFound.new("Block with block_type '#{type}' not found")
      end
      content_tag(:div, :class => options.delete(:class), :style => options.delete(:style)) do
        block_actions(page, block) +
          block_type_holder(page, type, block, options)
      end      
    end
  end
  
  def make_blocks_sortables(page)
    keys = page.blocks.map(&:block_type).uniq
    page.blocks.collect do |block|
      if block == block.real_block
        sortable_block_type_holder block.block_type,  change_order_ubiquo_page_design_widgets_path(page), keys
      end
    end
  end

  def block_type_holder(page, block_type, block, options = {})
    options.merge!(:id => "block_#{block_type}" )
    options[:class] ||= ''
    if !block.shared
      options[:class] << "block draggable_target"
    else
      options[:class] << "block non_draggable_target"
    end
    result = content_tag :div, options do
      content_tag :ul, :id =>"block_type_holder_#{block_type}", :class => 'block_type_holder' do
        widgets_for_block_type_holder(block.real_block)
      end
    end
    if block == block.real_block
      result += drop_receiving_element(
        options[:id],
        :url => ubiquo_page_design_widgets_path(@page),
        :method => :post,
        :accept => 'widget',
        :with => "'widget='+element.id.gsub(/^widget_/, '')+'&block=#{block.id}'"
      )
      drop_functions = "function activate_droppable_" + options[:id] + "() {"
      drop_functions += drop_receiving_element_js(
        options[:id],
        :url => ubiquo_page_design_widgets_path(@page),
        :method => :post,
        :accept => 'widget',
        :with => "'widget='+element.id.gsub(/^widget_/, '')+'&block=#{block.id}'"
      )
      drop_functions += "}"
      drop_functions += "function deactivate_droppable_" + options[:id] + "() {
                          Droppables.remove('"+options[:id]+"');
                          }"
      result += javascript_tag(drop_functions)
    end
    result
  end

  def options_for_shared_blocks_select(block)
    options = [[t("ubiquo.design.select_available_shared_blocks"), ""]]
    options += block.available_shared_blocks.map do |block|
      ["#{block.page.name} - #{block.block_type}", block.id]
    end
    options_for_select(options)
  end
  
  def widgets_for_block_type_holder(block)
    widgets = uhook_load_widgets(block)
    render :partial => "ubiquo/widgets/widget", :collection => widgets
  end

  def sortable_block_type_holder_options(id, url, containments=[])
    ["block_type_holder_#{id}", {
      :url => url,
      :handle => "move",
      :containment => containments.map{|i|"block_type_holder_#{i}"},
      :dropOnEmpty => true,
      :constraint => false,
      :with => "Sortable.serialize('block_type_holder_#{id}',{name: 'block[#{id}]'})"}
    ]
  end
  
  def sortable_block_type_holder(id,url, containments=[])
    id, opts = sortable_block_type_holder_options(id,url, containments)
    sortable_element id, opts
  end

  def block_actions(page, block)
    content_tag(:div,
      :id => "share_options_#{block.id}",
      :class => 'share_block_options') do
      if block.is_shared?
        content_tag(:div) do
          link_to_remote(t('ubiquo.design.stop_share_block'),
            :url => ubiquo_page_design_block_path(page, block),
            :method => :put,
            :confirm => t('ubiquo.design.stop_share_block_confirm'),
            :with => "'is_shared=false'")
        end
      elsif block.shared_id
        content_tag(:div) do
          link_to_remote(t('ubiquo.design.stop_use_shared_block', :key => block.shared.block_type),
            :url => ubiquo_page_design_block_path(page, block),
            :method => :put,
            :with => "'shared_id='")
        end
      else
        content_tag(:div) do
          link_to_remote(t('ubiquo.design.share_block'),
            :url => ubiquo_page_design_block_path(page, block),
            :method => :put,
            :with => "'is_shared=true'") + " #{t('ubiquo.or')} " +
            link_to_function(t('ubiquo.design.use_shared_block'), "toggleShareActions('share_options_#{block.id}')")
        end +
          content_tag(:div, :id => 'select_shared_block', :style => 'display:none') do
            select_tag("shared_blocks_#{block.id}", options_for_shared_blocks_select(block)) +
            link_to_remote(t('ubiquo.add'),
            :url => ubiquo_page_design_block_path(page, block),
            :method => :put,
            :confirm => t('ubiquo.design.replace_block_confirm'),
            :with => "'shared_id='+$F('shared_blocks_#{block.id}')") +
            link_to_function(t('ubiquo.cancel'), "toggleShareActions('share_options_#{block.id}')")
          end
      end
    end
  end

  def widget_tabs
    case ::Ubiquo::Config.context(:ubiquo_design).get(:widget_tabs_mode)
    when :auto
      ::Widget.groups.present? ? ::Widget.groups : @page.available_widgets_per_block
    when :groups
      ::Widget.groups
    when :blocks
      @page.available_widgets_per_block
    else
      ubiquo_config_call :widget_tabs_mode, :context => :ubiquo_design
    end

  end

end
