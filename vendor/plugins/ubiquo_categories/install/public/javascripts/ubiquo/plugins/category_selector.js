var CategorySelector = Class.create({
  initialize: function(link) {
    this.new_element_link = link;
    var link_id = link.id.gsub('link_new__', '').split('__');
    this.type = link_id[0];
    this.object_name = link_id[1];
    this.key = link_id[2];
  },
  counter: function() {
    return this.new_element_link.up().previous('div').select('div').size();
  },
  add_element: function(input_id) {
    var element_input = $(input_id);
    if (element_input.value != "") {
      if (this.type == "checkbox") {
        //We create the <ul> element if it's not present
        if (!element_input.up().up().previous('div')) {
          element_input.up().up().previous('legend').insert({after: '<div class="category-group"></div>'});
        }
        var element = "<div class='form-item-inline'><input type='"+this.type+"' checked='checked' value='"+element_input.value+"' id='new_"+this.object_name+"_"+this.key+"_"+this.counter()+"' name='"+this.object_name+"["+this.key+"][]' />";
        element += "<label for='new_"+this.object_name+"_"+this.key+"_"+this.counter()+"'>"+element_input.value+"</label></div>";
        element_input.up().up().previous('div').insert(element);
        this.toggle_new_category_input(element_input.up().previous('.new_category_controls'));
      } else if (this.type == "select") {
        var select = $(this.object_name + "_" + this.key + "_select");
        var option = document.createElement('option');
        option.text = element_input.value;
        option.value = element_input.value;
        option.selected = "selected";
        select.options.add(option);
        this.toggle_new_category_input(element_input.up().previous('.bt-add-category'));
      }
    }
  },
  toggle_new_category_input: function(link) {
    $("new_" + this.object_name + "_" + this.key).value = "";
    link.next('.add_new_category').toggle();
  }
});
document.observe("dom:loaded", function() {
  var selectors = {};
  $$('.new_category_controls .bt-add-category').each(function(link, index) {
    selectors[index] = new CategorySelector(link);
    link.observe(
      "click",
      function(event) {
        selectors[index].toggle_new_category_input(link);
        event.stop();
      }
    );
  $$('.new_category_controls .bt-create-category').each(function(add_link) {
      add_link.observe(
        "click",
        function(event) {
          selectors[index].add_element("new_" + selectors[index].object_name + "_" + selectors[index].key);
          event.stop();
        }
      );
    });
  });

  // Mark parent checkboxes in hierarchichal categories
  if ($$('.children_check_list').size() > 0) {
    $$('ul.children_check_list li input').each(function(item){
      item.observe("change", function(){
        var main_list = item.up('ul.hierarchical_check_list');
        if (item.checked) {
          main_list.select('input').first().checked = true;
        } else {
          if (main_list.select('input:checked').size() <= 1) {
            main_list.select('input').first().checked = false;
          }
        }
      })
    })
  }
});

var AutoCompleteSelector = Class.create({
  initialize: function(url, object_name, key, initial_collection, style, editable, token_limit) {
    this.categories_url = url;
    this.object_name = object_name;
    this.key = key;
    this.searchDelay = 500;
    this.minChars = 1;
    this.tokenLimit = token_limit;
    this.jsonContainer = null,
    this.queryParam = 'name';
    this.onResult = null;
    this.prePopulate = initial_collection;
    this.editable = editable;
    this.CAPTIONS = {
      hintText: "Type in a search term",
      noResultsText: "No results",
      searchingText: "Searching..."
    },
    this.CLASSES = {
      tokenList: style + "-token-input-list",
      token: style + "-token-input-token",
      tokenDelete: style + "-token-input-delete-token",
      selectedToken: style + "-token-input-selected-token",
      highlightedToken: style + "-token-input-highlighted-token",
      dropdown: style + "-token-input-dropdown",
      dropdownItem: style + "-token-input-dropdown-item",
      dropdownItem2: style + "-token-input-dropdown-item2",
      selectedDropdownItem: style + "-token-input-selected-dropdown-item",
      inputToken: style + "-token-input-input-token"
    },
    this.POSITIONS = {
      BEFORE: 0,
      AFTER: 1,
      END: 2
    },
    this.KEYS = {
      BACKSPACE: 8,
      TAB: 9,
      RETURN: 13,
      ESC: 27,
      LEFT: 37,
      UP: 38,
      RIGHT: 39,
      DOWN: 40,
      COMMA: 188
    };
    // Save the tokens
    this.saved_tokens = [];
    // Keep track of the number of tokens in the list
    this.token_count = 0;

    // Basic cache to save on db hits
    this.cache = new TokenListCache();

    // Keep track of the timeout
    this.timeout = null;

    // Create a new text input an attach keyup events
    this.input_box = this.prepareInputBox();

    // Keep a reference to the original input box
    this.hidden_input = this.prepareHiddenInput();

    // Keep a reference to the selected token and dropdown item
    this.selected_token = null;
    this.selected_dropdown_item = null;

    // The list to store the token items in
    this.token_list = this.prepareTokenList();

    // The list to store the dropdown items in
    this.dropdown = this.prepareDropdown();

    // The token holding the input box
    this.input_token = this.prepareInputToken();

    this.init_list();
  },
  prepareInputBox: function() {
    var klass = this;
    var input_box = new Element('input', {type: 'text', style: 'outline:none; border:0;min-width:0'});
    input_box.observe('focus', function(event) {
      if (this.tokenLimit == null || this.tokenLimit <= this.token_count) {
        this.selected_dropdown_item = null;
        this.show_dropdown_hint();
        event.stop();
      }
    }.bind(klass));
    input_box.observe('blur', function(event) {
      this.hide_dropdown();
      event.stop();
    }.bind(klass));
    input_box.observe('keydown', function(event) {
      var previous_token;
      var next_token;
      switch(event.keyCode) {
        case klass.KEYS.LEFT:
        case klass.KEYS.RIGHT:
        case klass.KEYS.UP:
        case klass.KEYS.DOWN:
          if (!$(this).value) {
            previous_token = klass.input_token.previous(0);
            next_token = klass.input_token.next(0);
            if((previous_token && $(previous_token) === klass.selected_token) || (next_token && $(next_token) === klass.selected_token)) {
              // Check if there is a previous/next token and it is selected
              if(event.keyCode == klass.KEYS.LEFT || event.keyCode == klass.KEYS.UP) {
                klass.deselect_token($(klass.selected_token), klass.POSITIONS.BEFORE);
              } else {
                klass.deselect_token($(klass.selected_token), klass.POSITIONS.AFTER);
              }
            } else if((event.keyCode == klass.KEYS.LEFT || event.keyCode == klass.KEYS.UP) && previous_token) {
              // We are moving left, select the previous token if it exists
              klass.select_token($(previous_token));
            } else if((event.keyCode == klass.KEYS.RIGHT || event.keyCode == klass.KEYS.DOWN) && next_token) {
              // We are moving right, select the next token if it exists
              klass.select_token($(next_token));
            }
          } else {
            var dropdown_item = null;
            var first_li = $(klass.dropdown).select("li").first();
            if(klass.selected_dropdown_item){
              if(event.keyCode == klass.KEYS.DOWN || event.keyCode == klass.KEYS.RIGHT) {
                dropdown_item = $(klass.selected_dropdown_item).next(0);
              } else {
                if($(klass.selected_dropdown_item) == first_li){
                  klass.deselect_dropdown_item(first_li);
                } else {
                  dropdown_item = $(klass.selected_dropdown_item).previous(0);
                }
              }
              if(dropdown_item) {
                klass.select_dropdown_item(dropdown_item);
              }
            } else {
              klass.select_dropdown_item(first_li);
            }
            return false;
          }
        event.stop();
        break;
      case klass.KEYS.BACKSPACE:
        previous_token = klass.input_token.previous(0);
        if(!$(this).value) {
          if(klass.selected_token) {
            klass.delete_token($(klass.selected_token));
          } else if(previous_token) {
            klass.select_token($(previous_token));
          }
          return false;
        } else if($(this).value.length == 1) {
          klass.hide_dropdown();
          klass.selected_dropdown_item = null;
        } else {
          // set a timeout just long enough to let this function finish.
          setTimeout(function(){klass.do_search(false);}, 1);
        }
        break;
      case klass.KEYS.TAB:
        case klass.KEYS.RETURN:
          case klass.KEYS.COMMA:
            if(klass.selected_dropdown_item) {
              klass.add_token_from_li($(klass.selected_dropdown_item));
              event.stop();
              return false;
            } else {
              if (klass.editable == true) {
                klass.add_token_from_text(this.value);
              }
              event.stop();
              return false;
            }
            break;
          case klass.KEYS.ESC:
            klass.hide_dropdown();
            klass.selected_dropdown_item = null;
            event.stop();
            return true;
          default:
            if(klass.is_printable_character(event.keyCode)) {
            // set a timeout just long enough to let this function finish.
              setTimeout(function(){klass.do_search(false);}, 1);
            }
        return false;
        break;
      }
    });
    return input_box;
  },

  prepareHiddenInput: function() {
    var hidden_input = $(this.object_name + "_" + this.key + "_autocomplete");
    hidden_input.hide();
    hidden_input.observe('focus', function(event) {
                           this.input_box.focus();
                           event.stop();
                         });
    hidden_input.observe('blur', function(event) {
                           this.input_box.blur();
                           event.stop();
                         });
    hidden_input.value = "";
    return hidden_input;
  },

  prepareTokenList: function() {
    var klass = this;
    var token_list = document.createElement('ul');
    token_list.addClassName(this.CLASSES.tokenList);
    token_list.observe('click', function(event) {
      var li = this.get_element_from_event(event, 'LI');
      if(li && $(li) != $(this.input_token)) {
        this.toggle_select_token(li);
        event.stop();
      } else {
        this.input_box.focus();
        if(this.selected_token) {
          this.deselect_token($(this.selected_token), this.POSITIONS.END);
        }
        event.stop();
      }
    }.bind(klass));
    token_list.observe('mouseover', function(event) {
      var li = klass.get_element_from_event(event, "LI");
      if(li && klass.selected_token !== this) {
        li.addClassName(klass.CLASSES.highlightedToken);
      }
      event.stop();
    });
    token_list.observe('mouseout', function(event) {
      var li = klass.get_element_from_event(event, "LI");
      if(li && klass.selected_token !== this) {
        li.removeClassName(klass.CLASSES.highlightedToken);
      }
      event.stop();
    });
    token_list.observe('mousedown', function(event) {
      // Stop user selecting text on tokens
      var li = klass.get_element_from_event(event, "LI");
      if(li) {
        event.stop();
      }
    });
    this.hidden_input.insert({after: token_list});
    return token_list;
  },

  prepareDropdown: function() {
    var dropdown = document.createElement('div');
    dropdown.addClassName(this.CLASSES.dropdown);
    this.token_list.insert({after: dropdown});
    dropdown.hide();
    return dropdown;
  },

  prepareInputToken: function() {
    var input_token = document.createElement('li');
    input_token.addClassName(this.CLASSES.inputToken);
    this.token_list.insert(input_token);
    input_token.insert(this.input_box);
    return input_token;
  },
  // Pre-populate list if items exist
  init_list: function() {
    var klass = this;
    var li_data = this.prePopulate;
    if(li_data && li_data.length) {
      li_data.each(function(item) {
      var this_token = this.add_token_from_json(item['category'] || item);
    }.bind(this));
    }
  },
  is_printable_character: function(keycode) {
    if((keycode >= 48 && keycode <= 90) ||      // 0-1a-z
      (keycode >= 96 && keycode <= 111) ||     // numpad 0-9 + - / * .
       (keycode >= 186 && keycode <= 192) ||    // ; = , - . / ^
       (keycode >= 219 && keycode <= 222)       // ( \ ) '
      ) {
      return true;
    } else {
      return false;
    }
  },

  // Get an element of a particular type from an event (click/mouseover etc)
  get_element_from_event: function(event, element_type) {
    var target = $(event.target);
    var element = null;

    if(target.nodeName == element_type) {
      element = target;
    } else if(target.up(element_type)) {
      element = target.up(element_type);
    }

    return element;
  },

  // Inner function to a token to the list
  insert_token: function(id, value) {
    var klass = this;
    var this_token = document.createElement('li');
    this_token.insert('<p>'+value+'</p>');
    this_token.addClassName(this.CLASSES.token);
    this.input_token.insert({before: this_token});
    var delete_token_button = document.createElement('span');
    delete_token_button.insert("x");
    delete_token_button.addClassName(this.CLASSES.tokenDelete);
    delete_token_button.observe('click',function(event) {
      klass.delete_token($(this).up());
      event.stop();
    });
    this_token.insert(delete_token_button);
    var token_values = {};
    token_values['id'] = id;
    token_values[klass.queryParam] = value;
    this_token.writeAttribute('alt', Object.toJSON($H(token_values)));
    return this_token;
  },

  // Add a token to the token list based on user input
  add_token: function(id, value) {
    var this_token = this.insert_token(id, value);

    // Clear input box and make sure it keeps focus
    this.input_box.value = "";
    this.input_box.focus();
    this.selected_dropdown_item = null;
    // Don't show the help dropdown, they've got the idea
    this.hide_dropdown();

    // Save this token id
    var new_hidden_input = new Element('input', {type: 'hidden', name: this.object_name+"["+this.key+"][]", id: this.object_name+"_"+this.key+"_"+id, value: value});
    this.hidden_input.insert({after: new_hidden_input});
    this.token_count++;
    if(this.tokenLimit != null && this.tokenLimit <= this.token_count) {
      this.input_box.hide();
      this.hide_dropdown();
    }
  },

  add_token_from_li: function(item) {
    var li_data = item.readAttribute('alt').evalJSON();
    var value = null;
    if (li_data['category'] == undefined) {
      value =  li_data[this.queryParam];
    } else {
      value = li_data['category'][this.queryParam];
    }
    this.add_token(li_data.id, value);
  },

  add_token_from_json: function(item) {
    this.add_token(item.id, item.name);
  },

  add_token_from_text: function(value) {
    //ignore value if introduced text is blank
    //this regexp is the same that trim function
    if (value.replace(/^\s+|\s+$/g,'') != "") {
      this.add_token(3, value);
    }
  },
  // Select a token in the token list
  select_token: function(token) {
    token.addClassName(this.CLASSES.selectedToken);
    this.selected_token = $(token);
    // Hide input box
    this.input_box.value = "";
    // Hide dropdown if it is visible (eg if we clicked to select token)
    this.hide_dropdown();
  },

  // Deselect a token in the token list
  deselect_token: function(token, position) {
    token.removeClassName(this.CLASSES.selectedToken);
    this.selected_token = null;
    if(position == this.POSITIONS.BEFORE) {
      token.insert({before: this.input_token});
    } else if(position == this.POSITIONS.AFTER) {
      token.insert({after: this.input_token});
    } else {
      this.token_list.insert(this.input_token);
    }
    // Show the input box and give it focus again
    this.input_box.focus();
  },

  // Toggle selection of a token in the token list
  toggle_select_token: function(token) {
    if (this.selected_token == $(token)) {
      this.deselect_token(token, this.POSITIONS.END);
    } else {
      if (this.selected_token) {
        this.deselect_token($(this.selected_token), this.POSITIONS.END);
      }
      this.select_token(token);
    }
  },
  // Delete a token from the token list
  delete_token: function(token) {
    // Remove the id from the saved list
    var token_data = token.readAttribute("alt").evalJSON();

    // Delete the token
    token.remove();
    this.selected_token = null;

    // Delete hidden input
    $(this.object_name+"_"+this.key+"_"+token_data.id).remove();

    // Show the input box and give it focus again
    this.input_box.focus();
    this.token_count--;

    if (this.tokenLimit != null) {
      this.input_box.value = "";
      this.input_box.show();
      this.input_box.focus();
    }
  },
  // Hide and clear the results dropdown
  hide_dropdown: function() {
    this.dropdown.hide();
    this.dropdown.update('');
  },

  show_dropdown_searching: function() {
    this.dropdown.update("<p>"+this.CAPTIONS.searchingText+"</p>");
    this.dropdown.show();
  },

  show_dropdown_hint: function() {
    this.dropdown.update("<p>"+this.CAPTIONS.hintText+"</p>");
    this.dropdown.show();
  },

  // Highlight the query part of the search term
  highlight_term: function(value, term) {
    return value.replace(new RegExp("(?![^&;]+;)(?!<[^<>]*)(" + term + ")(?![^<>]*>)(?![^&;]+;)", "gi"), "<b>$1</b>");
  },

  populate_dropdown: function(query, results) {
    var klass = this;
    if(results.length) {
      this.dropdown.update('');
      var dropdown_ul = document.createElement('ul');
      dropdown_ul.observe('click', function(event) {
        klass.add_token_from_li(klass.get_element_from_event(event, "LI"));
        event.stop();
      });
      dropdown_ul.observe('mouseover', function(event) {
        klass.select_dropdown_item(klass.get_element_from_event(event, "LI"));
        event.stop();
      });
      dropdown_ul.observe('mousedown', function(event) {
        // Stop user selecting text on tokens
        event.stop();
        return false;
      });
      dropdown_ul.hide();
      this.dropdown.insert(dropdown_ul);
      for(var i in results) {
        if (results.hasOwnProperty(i)) {
          var this_li = document.createElement('li');
          var value = this.highlight_term(results[i][this.queryParam] || results[i]['category'][this.queryParam], query)
          this_li.insert(value);
          dropdown_ul.insert(this_li);
          if(i%2) {
            this_li.addClassName(this.CLASSES.dropdownItem);
          } else {
            this_li.addClassName(this.CLASSES.dropdownItem2);
          }

          // if(i == 0){
          //   this.select_dropdown_item(this_li);
          // }
          this_li.writeAttribute('alt', Object.toJSON($H(results[i])));
        }
      }

      this.dropdown.show();
      dropdown_ul.slideDown({duration: 0.3});
    } else {
      this.selected_dropdown_item = null;
      this.dropdown.update("<p>"+this.CAPTIONS.noResultsText+"</p>");
      this.dropdown.show();
    }
  },
  // Highlight an item in the results dropdown
  select_dropdown_item: function(item) {
    if(item) {
      if(this.selected_dropdown_item) {
        this.deselect_dropdown_item($(this.selected_dropdown_item));
      }
      item.addClassName(this.CLASSES.selectedDropdownItem);
      this.selected_dropdown_item = $(item);
    }
  },

  // Remove highlighting from an item in the results dropdown
  deselect_dropdown_item: function(item) {
    item.removeClassName(this.CLASSES.selectedDropdownItem);
    this.selected_dropdown_item = null;
  },

  // Do a search and show the "searching" dropdown if the input is longer
  // than settings.minChars
  do_search: function(immediate) {
    var query = this.input_box.value.toLowerCase();
    if (query && query.length) {
      if(this.selected_token) {
        this.deselect_token($(this.selected_token), this.POSITIONS.AFTER);
      }
      if(query.length >= this.minChars) {
        this.show_dropdown_searching();
        if(immediate) {
          this.run_search(query);
        } else {
          clearTimeout(this.timeout);
          this.timeout = setTimeout(function(){
            this.run_search(query);
          }.bind(this), this.searchDelay);
        }
      } else {
        this.hide_dropdown();
      }
    }
  },

  // Do the actual search
  run_search: function(query) {
    var klass = this;
    var cached_results = this.cache.get(query);
    if(cached_results) {
      this.populate_dropdown(query, cached_results);
    } else {
      var queryStringDelimiter = this.categories_url.indexOf("?") < 0 ? "?" : "&";
      var callback = function(results) {
        if(Object.isFunction(klass.onResult)) {
          results = klass.onResult.call(this, results);
        }
        klass.cache.add(query, results.responseText.evalJSON(true));
        klass.populate_dropdown(query, results.responseText.evalJSON(true));
      };
      new Ajax.Response(new Ajax.Request(this.categories_url + queryStringDelimiter + "filter_text" + "=" + query, { method: "get", asynchronous: false, onSuccess: callback }));
    }
  }
});

var TokenListCache = Class.create({
  initialize: function(options) {
    this.max_size = 50;
    this.data = $H();
    this.size = 0;
    this.flush = function() {
      this.data = {};
      this.size = 0;
    };
  },
  add: function(query, results) {
    if(this.size > this.max_size) {
      this.flush();
    }

    if(!this.data.get(query)) {
      this.size++;
    }

    this.data.set(query, results);
  },
  get: function(query) {
    return this.data.get(query);
  }
});
