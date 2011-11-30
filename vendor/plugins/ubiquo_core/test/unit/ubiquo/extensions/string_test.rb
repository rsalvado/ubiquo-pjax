require File.dirname(__FILE__) + "/../../../test_helper.rb"

class Ubiquo::Extensions::StringTest < ActiveSupport::TestCase
  
  test "should truncate by word" do
    
    assert_equal "hello...",       "hello world too long".truncate_words(:max_chars => 8)
    assert_equal "hello...",       "hello world too long".truncate_words(:max_chars => 13)
    assert_equal "hello world...", "hello world too long".truncate_words(:max_chars => 14)
    assert_equal "hello world...", "<p>hello world too long</p>".truncate_words(:max_chars => 14)
    assert_equal "...", "<p>helloworldtoolong</p>".truncate_words(:max_chars => 14)
  end
  
  test "should center truncation on word" do 
    
    assert_equal "...b c d...", "a b c d e f g h".truncate_words(:max_chars => 12, :center => "c")
    assert_equal "...b c d...", "a b c d e f g h".truncate_words(:max_chars => 13, :center => "c")
    assert_equal "...b c d...", "a b c d e f g h".truncate_words(:max_chars => 14, :center => "c")
    assert_equal "...a b c d e...", "a b c d e f g h i j k".truncate_words(:max_chars => 15, :center => "c")
    assert_equal "...b c d...", "a <p>b</p> <div>c</div> <div>d</div> e f g h".truncate_words(:max_chars => 14, :center => "c")
    
    assert_equal "...b HOLA d...", "a b HOLA d e f g h i j k".truncate_words(:max_chars => 14, :center => "HOLA")
  end
  
  test "should highlight words with spans" do 
    
    assert_equal "hola <span class=\"highlight\">mundo</span>", "hola mundo".truncate_words(:highlight => "mundo")
    assert_equal "hola <span class=\"highlight\">mundo</span>", "hola mundo".truncate_words(:highlight => ["mundo"])
    assert_equal "<span class=\"highlight\">mundo</span> <span class=\"highlight\">mundo</span>", "mundo mundo".truncate_words(:highlight => ["mundo"])
    
    assert_equal "hola <span class=\"test\">mundo</span>", "hola mundo".truncate_words(:highlight => "mundo", :highlight_class => "test")
    
  end
  
  # http://es.wikipedia.org/wiki/Don_Quijote_de_la_Mancha
  test "some real example" do 
    assert_equal "...de dos partes: la primera, El ingenioso hidalgo don <span class=\"quijote\">Quijote</span> de la <span class=\"quijote\">Mancha</span>, fue publicada en...", <<QUIJOTE.truncate_words(:max_chars => 100, :center => "hidalgo", :highlight => ["Quijote", "Mancha"], :highlight_class => "quijote")

<p>La novela consta de dos partes: la primera, <i>El ingenioso <a href="/wiki/Hidalgo_(noble)" title="Hidalgo (noble)" class="mw-redirect">hidalgo</a> don Quijote de <a href="/wiki/La_Mancha" title="La Mancha">la Mancha</a></i>, fue publicada en <a href="/wiki/1605" title="1605">1605</a>; la segunda, <i>Segunda parte del ingenioso <a href="/wiki/Caballero" title="Caballero">caballero</a> don Quijote de la Mancha</i>, en <a href="/wiki/1615" title="1615">1615</a>.<sup id="cite_ref-0" class="reference"><a href="#cite_note-0"><span class="corchete-llamada">[</span>1<span class="corchete-llamada">]</span></a></sup></p>
QUIJOTE
  end
end
