require File.dirname(__FILE__) + '/../test_helper'

class ArticleTest < ActiveSupport::TestCase

  test "should create article" do
    assert_difference 'Article.count' do
      article = create_article
      assert !article.new_record?, "#{article.errors.full_messages.to_sentence}"
    end
  end

  test "should require title" do
    assert_no_difference 'Article.count' do
      article = create_article(:title => "")
      assert article.errors.on(:title)
    end
  end

  test "should filter by title" do
    Article.destroy_all
    article_1,article_2,article_3 = [
      create_article(:title => "try to find me"),
      create_article(:title => "try to FinD me"),
      create_article(:title => "I don't appear"),
    ]

    params = { "filter_text" => "find" }
    assert_equal_set [article_1,article_2], Article.filtered_search(params)
  end
  
  test "should filter by publish_date" do
    Article.destroy_all
    article_1,article_2,article_3 = [
      create_article(:published_at => 5.day.ago),
      create_article(:published_at => 10.days.ago),
      create_article(:published_at => 5.days.from_now),
    ]

    assert_equal_set [], Article.filtered_search({"filter_publish_start" => 10.day.from_now})
    assert_equal_set [article_3], Article.filtered_search({"filter_publish_start" => 3.day.ago})
    assert_equal_set [article_1, article_3], Article.filtered_search({"filter_publish_start" => 7.day.ago})
    assert_equal_set [article_1, article_2, article_3], Article.filtered_search({"filter_publish_start" => 12.day.ago})

    assert_equal_set [], Article.filtered_search({"filter_publish_end" => 12.day.ago})
    assert_equal_set [article_2], Article.filtered_search({"filter_publish_end" => 7.day.ago})
    assert_equal_set [article_1, article_2], Article.filtered_search({"filter_publish_end" => 3.day.ago})
    assert_equal_set [article_1, article_2, article_3], Article.filtered_search({"filter_publish_end" => 10.day.from_now})

    assert_equal_set [article_1], Article.filtered_search({"filter_publish_start" => 7.day.ago, "filter_publish_end" => 3.day.ago})
  end
  private

  def create_article(options = {})
    default_options = {
      :title => 'MyString', # string
      :description => 'MyText', # text
      :published_at => '2011-11-29 10:02:43', # datetime
    }
    Article.create(default_options.merge(options))
  end
end
