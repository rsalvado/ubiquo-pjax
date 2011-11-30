//Init namespace
if( !Ubiquo ){
    var Ubiquo = {};
}

document.observe("dom:loaded", function() {
  //action buttons
  var remove_actions_cell = true;
  $$('#content table.edit_on_row_click tr').each(function(e,index) {
    var edit_btn, del_btn, edit_url;
    if(index == 0){
      //first row (headers)
      e.insert({
        bottom: '<th class="delete">&nbsp;</th>'
      });
    }else{
      edit_btn = e.down('.btn-edit');
      del_btn = e.down('.btn-delete');
      if(del_btn){
          del_btn.update('<span>'+del_btn.text+'</span>');
          del_btn.remove();
          e.insert('<td class="delete"></td>');
          e.down('td.delete').insert(del_btn);
          del_btn.observe('click', function(ev){
            Event.stop(ev);
          });
      }
      
      edit_url = null;
      if(edit_btn != undefined){ 
          e.addClassName("editable");
          edit_url = edit_btn.readAttribute('href');
          e.writeAttribute('title',edit_btn.readAttribute('title'));
          edit_btn.remove();
          e.observe('mouseover', function(ev){
            e.addClassName('hover');
          });
          e.observe('mouseout', function(ev){
            e.removeClassName('hover');
          });
          e.observe('click', function(ev){
             // Weird case when a link does some ajax call and the event gets here.
             // Detected on "remove translation" link
             if(Event.element(ev).tagName.toUpperCase() != "A"){
                 if (edit_url != null) window.location.href = edit_url;
             }
          });

      }
      
      
      // Is there any action left?
      // otherways remove the "actions" cell from everywhere
      if( e.select(".actions a").length > 0 ) remove_actions_cell = false;
    }
  });
  if(remove_actions_cell){
    $$('#content table.edit_on_row_click tr .actions').each(function(e){
      e.remove();
    });
  }

});

document.observe("dom:loaded", function() {

  //links open in new window
  $$('a[rel="external"]').each(function(e,index) {
    e.observe('click', function(ev){
      ev.stop();
      var url = e.readAttribute('href');
      window.open(url,'New window');
    });
  });

  //ubiquo_authentication
  if($('send_confirm_creation') && $("welcome_message_block")) {
    $('send_confirm_creation').observe("change", function() {
      if ($('send_confirm_creation').checked) {
        Effect.BlindDown("welcome_message_block");
      } else {
        Effect.BlindUp("welcome_message_block");
      }
    });
    if($('send_confirm_creation').checked) {
      $("welcome_message_block").show();
    } else {
      $("welcome_message_block").hide();
    }
  }
  //ubiquo_i18n
  if($('locale_selector') != undefined) {
    var locale_selector = $('locale_selector');
    locale_selector.observe(
      "change",
      function(){
        this.up('form').submit();
      }
    );
  }

  // Prepare Hints with help info for form fields (ubiquo_form_builder)
  $$('.form-help .content').each(function(div_fh){
    div_fh.insert("<span class='arrow'></span>");
  });
  Event.observe(document, 'keydown', function(event){
    if(event.keyCode == Event.KEY_ESC){
      $$('.form-help').each(function(div_fh){
        div_fh.removeClassName('active');
      });
    }
  })

});

function send_as_form(div_id, url, method) {
  var fo = $(div_id);
  var ie = navigator.appVersion.indexOf("MSIE") != -1;
  var f;
  if(ie) {
    f = $(document.createElement('<form enctype="multipart/form-data">'));
  } else {
    f = document.createElement('form');
    f.enctype= 'multipart/form-data';
  }
  f.action = url;
  f.target = 'upload_frame';
  f.method = method;
  f.setAttribute('style', 'display = "hidden"');
  document.getElementsByTagName('body')[0].appendChild(f);
  f.appendChild(fo);
  f.submit();
  f.remove();
}

function killeditor(reference) {
  reference = reference || 'visual_editor';
  var first = true;
  $$("."+reference+", #"+reference).each(function(v) {
    if(first) {
      tinyMCE.triggerSave(true,true);
      first = false;
    }
    tinyMCE.execCommand('mceRemoveControl', true, $(v).id);
  });
}

function reviveEditor(reference) {
  reference = reference || 'visual_editor';
  $$("."+reference+", #"+reference).each(function(v) {
    tinyMCE.execCommand('mceAddControl', true, $(v).id);
  });
}

function blind_toggle(desired_elem, brother) {
  if($(desired_elem).visible()) {
    new Effect.BlindUp($(desired_elem));
  } else {
    new Effect.BlindUp($(brother));
    new Effect.BlindDown($(desired_elem));
  }
}

if(!Ubiquo.Forms){
    Ubiquo.Forms = {};
}
/*
 * Creates tabbed content
 * @param string parent_selector The css selector for the parent
 * @param string title_selector The css selector for the tag where the child's (each child will be a tab) titles are (will be hidden and serve as the tab menu items)
 */
Ubiquo.Forms.createTabs = function(parent_selector,title_selector){
    $$(parent_selector).each( function(group){
        if(group && !group.hasClassName("tabbed")){
            group.addClassName('tabbed');

            //create wrappers
            var newparent = new Element('div',{
                'class':'tabs-container'
            });
            // Move childs to new div
            // We avoid using innerHTML as we would lose the observers
            group.childElements().each(function(child){newparent.appendChild(child);});
            group.update(newparent);

            var tab_menu = new Element('ul', {'class': 'tabs-menu'});
            group.insert({ top: tab_menu });

            //hide titles and put them as tab menu items
            var tabs = group.down('.tabs-container').childElements();
            tabs.each(function(i,index) {
                i.addClassName('tab');

                //Create menu tab
                var tab_menu_option = new Element('li').update(i.down(title_selector).innerHTML);
                if (index == 0){ tab_menu_option.addClassName('current'); }
                tab_menu.insert(tab_menu_option);

                i.down(title_selector).hide();
                if (index == 0) i.addClassName('current-tab');
            });

            //tab menu behavior
            var menu_tabs = tab_menu.childElements();
            menu_tabs.each(function(i,index){
                i.observe('click',function(ev){
                    //We do not check if the tab is already shown as sometimes it gets hidden
                    tabs.invoke("removeClassName",'current-tab');
                    tabs[index].addClassName('current-tab');

                    menu_tabs.invoke("removeClassName",'current');
                    i.addClassName('current');
                });
            });

            //Highlights the tab that contains errors
            group.select(".error_field").each(function(error_field){
                //Detect the position of the tab and highlight the tab and all its upper tabs!
                var tab = error_field;
                var container = null;
                while( (tab = tab.up(".tab")) ){
                    var container = tab.up(".tabs-container");
                    if( container ){
                        var idx = container.childElements().indexOf( tab );
                        container.up().down(".tabs-menu").childElements()[idx].addClassName("with-errors");
                    }
                }
            });
        }
    });
}

/*
 * Registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request. Necessary to
 * work with rails applications which have fixed
 * CVE-2011-0447
 */

Ajax.Responders.register({
  onCreate: function(request) {
    var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
          token = csrf_meta_tag.readAttribute('content');

      if (!request.options.requestHeaders) {
        request.options.requestHeaders = {};
      }
      request.options.requestHeaders[header] = token;
    }
  }
});

//Init tabs before page load but after required dom objects loaded.
//This initalization could be done on dom:loaded but it creates a strange effect.
Ubiquo.Forms.createTabs(".form-tab-container","legend");

