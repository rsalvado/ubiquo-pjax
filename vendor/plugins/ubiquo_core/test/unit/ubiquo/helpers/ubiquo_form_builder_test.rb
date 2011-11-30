# -*- coding: utf-8 -*-
require File.dirname(__FILE__) + "/../../../test_helper.rb"

class UbiquoFormBuilderTest < ActionView::TestCase

  attr_accessor :params

  def setup
    self.params = { :controller => 'tests', :action => 'index' }
  end

  test "form" do
    # Testing the tester.
    the_form do |ufb|
      assert_equal Ubiquo::Helpers::UbiquoFormBuilder, ufb.class
      concat("AAA")
    end
    assert_select "form" do |list|
      assert_equal "/ubiquo/users/1", list.first.attributes["action"]
    end
    assert_select "form", "AAA"
  end

  test "form field" do
    assert_nothing_thrown { 
      the_form do |form|
        concat( form.text_field :lastname )
        concat( form.hidden_field :lastname )
      end
    }
  end
  
  test "form field text_field" do
    the_form do |form|
      concat( form.text_field :lastname )
      concat( form.text_field :lastname, :class=> "alter" )
    end
    assert_select "form" do |list|
      assert_equal "/ubiquo/users/1", list.first.attributes["action"]
      assert_select "div.form-item" do
        assert_select "label", "Bar"
        assert_select "input[type='text'][name='user[lastname]'][value='Bar']"
        assert_select "input[type='text'][name='user[lastname]'][value='Bar'][class='alter']"
      end
    end
  end

  test "group" do
    the_form do |f|
      concat( f.group {} )
    end
    assert_select "form div.form-item"
  end

  test "group with block from erb" do
    # TODO: test with an erb block like. Dont try to use ERB.new(template) as
    # rails overloads it and it does not work stright away.
#   <% form.submit_group do %>
#    <%= form.create_button %>
#    <%= form.back_button %>
#  <% end %>
    #
    
  end

  test "submit group" do
    the_form do |f|
      concat f.submit_group {}
    end
    assert_select "form div.form-item-submit"
  end

  test "Submit group for new and edit" do
    self.expects(:ubiquo_users_path).returns("/ubiquo/users")
    self.expects(:t).with("ubiquo.create").returns("ubiquo.create-value")
    self.expects(:t).with("ubiquo.save").returns("ubiquo.save-value")
    self.expects(:t).with("ubiquo.back_to_list").returns("ubiquo.back_to_list-value")

    the_form do |f|
      concat( f.submit_group do
        concat f.create_button 
        concat f.back_button
        concat f.update_button
      end )
    end
    
    assert_select "form div.form-item-submit" do |blocks|
      assert_equal 1, blocks.size
      block = blocks.first
      assert_select block, "input[type='submit'][value='ubiquo.create-value']"
      assert_select block, "input[type='submit'][value='ubiquo.save-value']"
      assert_select block, "input[type='button']" do |buttons|
        assert buttons.first.attributes["onclick"].include?( "href=" )
      end
    end
  end

  test "Custom params for submit buttons" do
    self.expects(:ubiquo_users_path).returns("/ubiquo/users")
    self.expects(:t).with("ubiquo.create-custom").returns("ubiquo.create-custom-value")
    self.expects(:t).with("ubiquo.save-custom").returns("ubiquo.save-custom-value")

    the_form do |f|
      concat( f.submit_group( :class => "alter-submit" ) do
        # Custom params
        concat f.create_button( "c-custom", :class => "bt-create2" )
        concat f.create_button( nil, :i18n_label_key => "ubiquo.create-custom")
        concat f.back_button( "back-custom", {:js_function => "alert('foo');", :class => "bt-back2"} )
        concat f.update_button( "u-custom", :class => "bt-update2" )
        concat f.update_button( nil, :i18n_label_key => "ubiquo.save-custom")
      end )
    end
    
    assert_select "form div.alter-submit", 1 do |blocks|
      block = blocks.first
      assert_select block, "input[type='submit'][value='c-custom'][class='bt-create2']"
      assert_select block, "input[type='submit'][value='ubiquo.create-custom-value']"
      assert_select block, "input[type='button'][value='back-custom'][class='bt-back2']" do |buttons|
        assert buttons.first.attributes["onclick"].include?( "alert('foo');" )
      end
      assert_select block, "input[type='submit'][value='u-custom'][class='bt-update2']"
      assert_select block, "input[type='submit'][value='ubiquo.save-custom-value']"
    end
  end

  test "custom_block" do
    the_form do |form|
      concat( form.custom_block do
        concat( '<div class="custom-form-item">' )
        concat( form.label :lastname, "imalabel")
        concat( form.text_field :lastname)
        concat("</div>")
     end )
    end

    assert_select "form > div.form-item", 0
    # Only a label (means that text_field has not generated any label)
    assert_select "form label", "imalabel", 1

    assert_select "form input[type='text'][value='Bar']", 1
  end

  test "disable group on selectors" do
    self.expects(:relation_selector).returns("rel")
    assert_nothing_raised{
      the_form do |form|
        concat( form.group :label => "custom_label_group", :type => :fieldset do
          concat( form.relation_selector :actors, :type => :checkbox )
        end )
      end
    }
  end
  test "show description, help info and translatable hints" do
    self.expects(:t).with("ubiquo.translatable_field").returns("ubiquo.translatable_field")

    the_form do |form|
      concat( form.group(:class => "a0") do
        concat( form.text_field :lastname, :translatable => true )
      end)
      concat( form.group(:class => "a1") do
        concat( form.text_field :lastname, :class=> "alter", :translatable => "foo" )
      end)
      concat( form.group(:class => "a2") do
        concat( form.text_field :lastname, :class=> "alter2", :description => "foo2", :help => "Info text")
      end )
      concat( form.group(:class => "a3") do
        concat( form.text_field :lastname, :class=> "alter3", :translatable => "foo3", :description => "bar" )
      end )

    end

    assert_select "form" do |list|
      assert_equal "/ubiquo/users/1", list.first.attributes["action"]
      assert_select ".a0" do
        assert_select "p.translation-info", "ubiquo.translatable_field"
        assert_select "p.description",0
      end
      assert_select ".a1" do
        assert_select "p.translation-info", "foo"
        assert_select "p.description",0
      end
      assert_select ".a2" do
        assert_select "p.translation-info",0
        assert_select "p.description", "foo2"
        assert_select "div.form-help" do
          assert_select "a.btn-help" do |link|
            assert_equal link.first.attributes["onclick"],
              "this.getOffsetParent().toggleClassName('active'); return false;",
              "Should have a js method to assign 'active' class to parent <div>"
            assert_equal link.first.attributes["tabindex"], "100",
              "Should have a big 'tabindex' attribute to jump <a> " +
              "tag when navigating with TAB key within the form."
          end
          assert_select "div.content" do
            assert_select "p", "Info text"
          end
        end
      end
      assert_select ".a3" do
        assert_select "p.translation-info","foo3"
        assert_select "p.description", "bar"
      end
    end
  end

  test "show checkox correctly" do
    the_form do |form|
      concat( form.group(:class => "a0") do
        concat( form.check_box :is_admin )
      end )
      
      concat( form.group(:class => "a1") do
        concat( form.check_box :is_admin, :translatable => true )
      end )
    end

    assert_select "form" do |list|
      assert_select ".a0" do
        assert_select ".form-item" do
          assert_equal ["label", "input","input"], css_select(".form-item *").map(&:name)

          assert_select "input[label_on_bottom='false']", 0
        end
      end

      assert_select ".a1" do
        assert_select ".form-item" do
          assert_equal ["label", "input","input","p"], css_select(".form-item *").map(&:name)
          assert_select "input[label_on_bottom='false']", 0
        end
      end
    end

  end

  test "tabbed blocks" do
    self.expects(:t).with("personal_data").returns("personal_data").at_least_once
    self.expects(:t).with("rights").returns("rights").at_least_once
    
    the_form do |form|
       concat( form.group(:type => :tabbed, :class=> "a-group-of-tabs") do |group|
         concat( group.add(t("personal_data")) do
           concat( form.text_field :lastname )
         end )
         concat( group.add(t("rights"), :class => "custom-tab-class") do
           concat( form.check_box :is_admin )
         end )
       end )
    end

    assert_select ".form-tab-container.a-group-of-tabs .form-tab" do |tabs|
      assert 2, tabs.size
      assert_equal "custom-tab-class form-tab", tabs.last.attributes["class"]
    end
    assert_select ".a-group-of-tabs .form-tab input"
  end

  test "tabbed blocks easy syntax" do
    the_form do |form|
       concat( form.group(:type => :tabbed, :class=> "a-group-of-tabs") do
         concat( form.tab(("personal_data"),:class => "parenttab") do
           concat( form.text_field :lastname )
           concat( form.group(:type => :tabbed, :class=> "childtab") do
             concat( form.tab(("inner tab"),:class =>"childtab") do
               concat( form.text_field :is_admin )
             end )
           end )
         end )
         concat( form.tab(("rights"), :class => "custom-tab-class") do
           concat( form.check_box :is_admin )
         end )
       end )
    end

    assert_select ".form-tab-container.a-group-of-tabs .form-tab" do |tabs|
      assert 2, tabs.size
      assert_equal "custom-tab-class form-tab", tabs.last.attributes["class"]
    end
    assert_select ".a-group-of-tabs .form-tab input"

  end

  test "tabs can be unfolded" do
    original_value = Ubiquo::Config.context(:ubiquo_form_builder).get(:unfold_tabs)
    Ubiquo::Config.context(:ubiquo_form_builder).set(:unfold_tabs,true)
    begin
      the_form do |form|
         concat( form.group(:type => :tabbed, :class=> "a-group-of-tabs") do
           concat( form.tab(("personal_data")) do
             concat( form.text_field :lastname )
          end )
         end )
      end

      assert_select ".form-tab-container.a-group-of-tabs .form-tab", 0
      assert_select ".form-tab-container-unfolded.a-group-of-tabs .form-tab", 1
    ensure
      # Restore config
      Ubiquo::Config.context(:ubiquo_form_builder).set(:unfold_tabs, original_value )
    end
  end

  test "we cannot call tab without a tabbed parent group defined" do
    assert_raise(RuntimeError) {
      the_form do |form|
         concat( form.tab(t("personal_data")) do
           concat( form.text_field :lastname )
         end )
      end
    }
  end
  
  test "can append content inside the field, after and before the content" do
    the_form do |form|
      concat( form.text_field :lastname, :group => {:after => '<div class="after">A</div>'} )
      concat( form.text_field :lastname, :class=> "alter", :group => {:before => '<div class="before">A</div>'} )
    end
    assert_select "form .form-item" do |form_items|
      assert_select form_items.first, ".after"
      assert_select form_items.first, "div *" do |items|
        assert_equal "after", items.last.attributes["class"]
      end
      assert_select form_items.last, ".before"
      assert_select form_items.last, "div *" do |items|
        assert_equal "before", items.first.attributes["class"]
      end
    end
  end
  
  test "use check_box with all options" do
    the_form do |form|
      # Weird use but useful sometimes
      concat( form.check_box( :lastname ))
      concat( form.check_box( :lastname, {:class => "simple"}))
      concat( form.check_box( :lastname, {:class => "complex"}, "GARCIA", "OFF" ))
    end
    assert_select "form input[type=hidden][value=0]",2
    assert_select "form input[type=checkbox][class=checkbox][value=1]"
    assert_select "form input[type=checkbox][class=simple][value=1]"
    assert_select "form input[type=hidden][value=OFF]"
    assert_select "form input[type=checkbox][class=complex][value=GARCIA]"
  end

  protected

  # helper to build a ubiquo form to test
  def the_form( options={}, &proc)
    self.expects(:ubiquo_user_path).returns("/ubiquo/users/1")
    options[:builder] = Ubiquo::Helpers::UbiquoFormBuilder
    user = User.new
    form_for([:ubiquo,user], options, &proc)
    @rendered = ""
  end

end


# Testing purpose class to simulate an ActiveRecord model
class User

  def id
    123
  end

  def lastname
    "Bar"
  end

  def born_at
    Time.parse("2011-01-01 12:00")
  end

  def is_admin
    true
  end

  def self.human_attribute_name( attr )
    {
      :lastname => "Bar",
      :is_admin => "Is admin",
      :born_at => "Born at"
     }[ attr.to_sym ] || attr.to_s
  end
end


