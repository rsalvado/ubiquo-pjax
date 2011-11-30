module UbiquoI18n
  module Filters
    class LocaleFilter < Ubiquo::Filters::LinkFilter

      def configure(options={})
        defaults = {
          :field       => :filter_locale,
          :collection  => Locale.active,
          :id_field    => :iso_code,
          :name_field  => :humanized_name,
          :caption     => I18n.t('ubiquo.language')
        }
        @options = defaults.merge(options)
      end

    end
  end
end
