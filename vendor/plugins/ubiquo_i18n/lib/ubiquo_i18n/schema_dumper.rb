module UbiquoI18n
  # This module performs the necessary steps to preserve the validity of an schema
  # dump if, when creating a table, the :translatable option has been set
  module SchemaDumper
    def self.included(klass)
      klass.send(:alias_method_chain, :table, :translations)
    end
    
    def table_with_translations(table, stream)
      tbl = StringIO.new
      table_without_translations(table, tbl)
      tbl.rewind
      result = tbl.read
      # The "integer" content_id field is in fact a sequence
      result.gsub!(/integer([\s]*) (\"content_id\")([^\n]*)/, ('sequence\1"'+table+'", \2'))
      stream.print result
    end
  end
end


ActiveRecord::SchemaDumper.send(:include, UbiquoI18n::SchemaDumper)
