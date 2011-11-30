require File.dirname(__FILE__) + "/../test_helper.rb"

class UbiquoDesign::StructureTest < ActiveSupport::TestCase

  def teardown
    UbiquoDesign::Structure.clear(:test)
    UbiquoDesign::Structure.clear(:other)
  end

  def test_should_initialize_structure
    UbiquoDesign::Structure.define(:test) {}
    assert_equal({}, UbiquoDesign::Structure.get(:test))
  end

  def test_should_clear
    UbiquoDesign::Structure.define(:test) do
      widget :logo
    end
    UbiquoDesign::Structure.clear(:test)
    assert_equal({}, UbiquoDesign::Structure.get(:test))
  end

  def test_should_clean_scope
    UbiquoDesign::Structure.define(:other) do
      page_template :a
    end
    assert_raise ZeroDivisionError do
      UbiquoDesign::Structure.define(:test) do
        page_template :pt do
          widget :logo
          1/0
        end
      end
    end
    assert_equal(
      {:page_templates => [:a => []]},
      UbiquoDesign::Structure.get(:other)
    )
  end

  def test_should_store_structures
    UbiquoDesign::Structure.define(:test) do
      widget :logo
      page_template :pt
    end

    assert_equal(
      {:widgets => [:logo => []], :page_templates => [:pt => []]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_store_structures_when_multiple_at_once
    UbiquoDesign::Structure.define(:test) do
      widget :logo, :sidebar
    end

    assert_equal(
      {:widgets => [{:logo => []}, {:sidebar => []}]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_store_repeated_structures
    UbiquoDesign::Structure.define(:test) do
      widget :logo, :head
      widget :lemma
    end

    assert_equal(
      {:widgets => [{:logo => []}, {:head => []}, {:lemma => []}]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_store_nested_structures
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
      end
      widget :head
    end

    assert_equal({
        :page_templates => [:pt => [{:widgets => [:logo => []]}]],
        :widgets => [{:head => []}]},
      UbiquoDesign::Structure.get(:test)
    )
  end

  def test_should_get_nested_structures_page_template
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
        block :block do
          widget :exclusive
        end
      end
      widget :head
    end

    assert_equal({
        :widgets => [{:logo => []}, {:head => []}],
        :blocks => [{:block => [{:widgets => [:exclusive => []]}]}]
      },
      UbiquoDesign::Structure.get(:test, {:page_template => :pt})
    )
  end

  def test_should_get_nested_structures_widgets_by_block
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
        block :block do
          widget :exclusive
        end
        block :other do
          widget :other
        end
      end
      widget :exclusive
    end

    assert_equal({
        :widgets => [{:logo => []}, {:exclusive => []}],
      },
      UbiquoDesign::Structure.get(:test, {:page_template => :pt, :block => :block})
    )
  end

  def test_get_should_accept_string_params
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
      end
    end

    assert_equal(
      {:widgets => [{:logo => []}]},
      UbiquoDesign::Structure.get(:test, {:page_template => 'pt'})
    )
  end

  def test_get_should_accept_arrays_of_different_options
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        widget :logo
      end
      page_template :new do
        widget :detail
      end
    end

    assert_equal(
      {:widgets => [{:logo => []}]},
      UbiquoDesign::Structure.get(:test, {:page_template => ['pt', :pt]})
    )
    assert_equal(
      {:widgets => [{:logo => []}]},
      UbiquoDesign::Structure.get(:test, {:page_template => [:no, 'pt']})
    )
    assert_equal(
      {:widgets => [{:detail => []}, {:logo => []}]},
      UbiquoDesign::Structure.get(:test, {:page_template => [:new, 'pt']})
    )
    assert_equal(
      {},
      UbiquoDesign::Structure.get(:test, {:page_template => [:no, :thing]})
    )
  end

  def test_should_store_options
    UbiquoDesign::Structure.define(:test) do
      page_template :pt, :cols => 4 do
        block :block, :cols => 1
      end
    end

    assert_equal({
        :blocks => [:block => [{:options=> {:cols => 1}}]],
        :options => {:cols => 4}
      },
      UbiquoDesign::Structure.get(:test, {:page_template => :pt})
    )
  end

  def test_should_find
    UbiquoDesign::Structure.define(:test) do
      page_template :pt do
        block :block do
          widget :in
        end
        widget :middle
      end
      widget :out
    end

    assert_equal(
      [:in, :middle, :out],
      UbiquoDesign::Structure.find(
        :widgets,
        {:page_template => :pt, :block => :block},
        :test
      )
    )
  end

  def test_find_should_return_always_a_list
    UbiquoDesign::Structure.define(:test) do
      widget :logo
    end

    assert_equal [], UbiquoDesign::Structure.find(:widgets,{},:missing)
    assert_equal [], UbiquoDesign::Structure.find(:missing,{},:test)
  end

end