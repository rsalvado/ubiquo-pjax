document.observe("dom:loaded", function() {
  //Add observers for url compose in pages form
  if($('page_parent_id')) {
    var parent_page_select = $('page_parent_id');
    parent_page_select.observe(
      "change",
      function() {
        update_url_example();
      }
    )
  }
  if($('page_url_name')) {
    update_url_example();
    var url_name_field = $('page_url_name');
    url_name_field.observe(
      "keyup",
      function() {
        update_url_example();
      }
    );
  }
  if($('save_publish')) {
    var save_publish_button = $('save_publish');
    save_publish_button.observe(
      "click",
      function() {
        $('publish_page').value = 'true';
        this.up('form').submit();
      }
    )
  }

  //Sidebar scroll
  if ($('slide_wrapper')) {
    var scrolling = false;
    var last_scroll;
    
    last_scroll = document.viewport.getScrollOffsets()[1];
    
    setInterval(function(){
      var current_scroll = document.viewport.getScrollOffsets()[1];
      if (scrolling){
        if (current_scroll == last_scroll){
          scrolling = false;
          slide_that_div();
        }
      } else if(current_scroll != last_scroll){
        scrolling = true;
      }
      last_scroll = current_scroll;
    }, 200);
  }
});


function slide_that_div(){
  var scroll_offset = document.viewport.getScrollOffsets()[1];
	scroll_offset = (scroll_offset > 340) ? scroll_offset-340 : 0;
	new Effect.Move('widgets', { y: scroll_offset, mode: 'absolute', duration: '0.5' });
}

//------------
function update_url_example() {
  var selected_parent = $('page_parent_id').options[$('page_parent_id').selectedIndex].title;
  var host = $('url_example').textContent.match(/http\:\/\/.*\.[a-z]{2,3}\//).first();
  var page_value = $('page_url_name').value;
  if (selected_parent != "") {
    var replace = "^" + selected_parent + "/";
    page_value = page_value.gsub(replace, '');
    $('page_url_name').value = page_value;
    var value = host + selected_parent + "/" + page_value;
  } else {
    var value = host + page_value;
  }
  $('url_example').update(value);
} 

function update_error_on_widgets(widget_ids) {
  $$("#content .widget").each(function(i) {
    i.removeClassName("error");
  })
	
  widget_ids.each(function(id) {
    $("widget_" + id).addClassName("error");
  })
}

function toggleShareActions(id) {
  $(id).select('div').each(function(div) {
    div.toggle();
  });
}

function isIE7(){
  if(Prototype.Browser.IE && parseInt(navigator.userAgent.substring(navigator.userAgent.indexOf("MSIE")+5)) <=7) {
    return true;
	}
	return false;
}

function explorerScrollPositioner(positionType){
  // IE<=7 needs to change the position style of dragContainer from static to relative on drag start so that the images can be dragged successfully from an overflowed container.
  if(isIE7()) {
    $$(".available_widgets, .scroll-innerBox").each(function(el) {el.style.position = positionType;});
	}
}

function showAllowedBlocks(widgetType){
  $('shadow').setStyle({height: $('inner-content').getHeight()+"px"});
  $('shadow').show();

  $$('.block').each(function(block) {
    var block_key = block.id.gsub(/^block_/, '')
    if($(block.id).hasClassName("draggable_target") && BlockStructure.blocks[block_key].include(widgetType))
    {
      $(block.id).getOffsetParent().setStyle({zIndex: '200'});
    }
    else{
      if($(block.id).hasClassName("draggable_target"))
        eval("deactivate_droppable_"+block.id+"()");
    }
  });
}

function hideAllowedBlocks(widgetType){
  $('shadow').hide();

  $$('.block').each(function(block) {
    var block_key = block.id.gsub(/^block_/, '')
    if($(block.id).hasClassName("draggable_target") && BlockStructure.blocks[block_key].include(widgetType))
    {
      $(block.id).getOffsetParent().setStyle({zIndex: '1'});
    }
    else{
      if($(block.id).hasClassName("draggable_target"))
        eval("activate_droppable_"+block.id+"()");
    }
  });
}

// Stores the widget structure and the allowed blocks of each widget
BlockStructure = Class.create({});
Object.extend(BlockStructure, {
  blocks: {},

  add: function(block, allowed_widgets){
    if(!allowed_widgets) allowed_widgets = []
    this.blocks[block] = allowed_widgets
  }
});
//ALLOWED BLOCKS FOR EACH WIDGET
//var allowedBlocks = new Array();
//for each widget specify allowed blocks
//allowedBlocks['static_section'] = ['block_top','block_sidebar'];
//allowedBlocks['free'] = ['block_main'];

function toggleWidgetGroups(selected_group) {
  $$('.available_widgets').each(function(aw){aw.hide()});
  $('widgets_' + selected_group.value).show();
  Scroller.updateAll();
}

