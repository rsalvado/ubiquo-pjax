module UbiquoScaffold
  class TranslationUpdater

    attr_accessor :locales
    attr_accessor :template_path
    attr_accessor :translations_path

    def initialize(template_path)
      @locales = Ubiquo.supported_locales.map(&:to_s)
      @template_path = template_path
      @translations_path = Rails.root.join('config', 'locales')
    end

    def update_with(file, tpl_file_pattern, b)
      @locales.each do |locale|
        tpl_file  = @template_path.join(tpl_file_pattern.gsub(/locale/,locale))
        orig_file = @translations_path.join(locale, file)
        contents  = YAML.load(File.read(orig_file))
        new_model = YAML.load(ERB.new(File.read(tpl_file), nil, '-').result(b))
        yield contents, new_model, locale
        write_yaml(contents, orig_file)
      end
    end

    private

    def write_yaml(contents, file)
      contents
      File.open(file, 'w') do |f|
        # Using ya2yaml, if available, for UTF8 support
        yaml_translations = contents.respond_to?(:ya2yaml) ? contents.ya2yaml(:escape_as_utf8 => true) : contents.to_yaml
        f.puts yaml_translations
      end
    end
  end
end
