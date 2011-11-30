require 'yaml'

class Hash
  def deep_merge(other)
    # deep_merge by Stefan Rusterholz, see http://www.ruby-forum.com/topic/142809
    merger = proc { |key, v1, v2| (Hash === v1 && Hash === v2) ? v1.merge(v2, &merger) : v2 }
    merge(other, &merger)
  end

  def set(keys, value)
    key = keys.shift
    if keys.empty?
      self[key] = value
    else
      self[key] ||= {}
      self[key].set keys, value
    end
  end

  if ENV['SORT']
    # copy of ruby's to_yaml method, prepending sort.
    # before each so we get an ordered yaml file
    def to_yaml( opts = {} )
      YAML::quick_emit( self, opts ) do |out|
        out.map( taguri, to_yaml_style ) do |map|
          sort.each do |k, v| #<- Adding sort.
            map.add( k, v )
          end
        end
      end
    end
  end
end

namespace :translate do
  desc "Show untranslated keys for locale LOCALE"
  task :untranslated => :environment do
    from_locale = I18n.default_locale
    untranslated = Translate::Keys.new.untranslated_keys

    messages = []
    untranslated.each do |locale, keys|
      keys.each do |key|
        from_text = I18n.backend.send(:lookup, from_locale, key)
        messages << "#{locale}.#{key} (#{from_locale}.#{key}='#{from_text}')"
      end
    end

    if messages.present?
      messages.each { |m| puts m }
    else
      puts "No untranslated keys"
    end
  end

  desc "Show I18n keys that are missing in the config/locales/default_locale.yml YAML file"
  task :missing => :environment do
    missing = Translate::Keys.new.missing_keys.inject([]) do |keys, (key, filename)|
      keys << "#{key} in \t  #{filename} is missing"
    end
    puts missing.present? ? missing.join("\n") : "No missing translations in the default locale file"
  end

  desc "Remove all translation texts that are no longer present in the locale they were translated from"
  task :remove_obsolete_keys => :environment do
    I18n.backend.send(:init_translations)
    master_locale = ENV['LOCALE'] || I18n.default_locale
    Translate::Keys.translated_locales.each do |locale|
      texts = {}
      Translate::Keys.new.i18n_keys(locale).each do |key|
        if I18n.backend.send(:lookup, master_locale, key).to_s.present?
          texts[key] = I18n.backend.send(:lookup, locale, key)
        end
      end
      I18n.backend.send(:translations)[locale] = nil # Clear out all current translations
      I18n.backend.store_translations(locale, Translate::Keys.to_deep_hash(texts))
      Translate::Storage.new(locale).write_to_file
    end
  end

  desc "Merge I18n keys from log/translations.yml into config/locales/*.yml (for use with the Rails I18n TextMate bundle)"
  task :merge_keys => :environment do
    I18n.backend.send(:init_translations)
    new_translations = YAML::load(IO.read(File.join(Rails.root, "log", "translations.yml")))
    raise("Can only merge in translations in single locale") if new_translations.keys.size > 1
    locale = new_translations.keys.first

    overwrites = false
    Translate::Keys.to_shallow_hash(new_translations[locale]).keys.each do |key|
      new_text = key.split(".").inject(new_translations[locale]) { |hash, sub_key| hash[sub_key] }
      existing_text = I18n.backend.send(:lookup, locale.to_sym, key)
      if existing_text && new_text != existing_text
        puts "ERROR: key #{key} already exists with text '#{existing_text.inspect}' and would be overwritten by new text '#{new_text}'. " +
          "Set environment variable OVERWRITE=1 if you really want to do this."
        overwrites = true
      end
    end

    if !overwrites || ENV['OVERWRITE']
      I18n.backend.store_translations(locale, new_translations[locale])
      Translate::Storage.new(locale).write_to_file
    end
  end

  desc "Apply Google translate to auto translate all texts in locale ENV['FROM'] to locale ENV['TO']"
  task :google => :environment do
    raise "Please specify FROM and TO locales as environment variables" if ENV['FROM'].blank? || ENV['TO'].blank?

    # Depends on httparty gem
    # http://www.robbyonrails.com/articles/2009/03/16/httparty-goes-foreign
    class GoogleApi
      include HTTParty
      base_uri 'ajax.googleapis.com'
      def self.translate(string, to, from)
        tries = 0
        begin
          get("/ajax/services/language/translate",
            :query => {:langpair => "#{from}|#{to}", :q => string, :v => 1.0},
            :format => :json)
        rescue
          tries += 1
          puts("SLEEPING - retrying in 5...")
          sleep(5)
          retry if tries < 10
        end
      end
    end

    I18n.backend.send(:init_translations)

    start_at = Time.now
    translations = {}
    Translate::Keys.new.i18n_keys(ENV['FROM']).each do |key|
      from_text = I18n.backend.send(:lookup, ENV['FROM'], key).to_s
      to_text = I18n.backend.send(:lookup, ENV['TO'], key)
      if !from_text.blank? && to_text.blank?
        print "#{key}: '#{from_text[0, 40]}' => "
        if !translations[from_text]
          response = GoogleApi.translate(from_text, ENV['TO'], ENV['FROM'])
          translations[from_text] = response["responseData"] && response["responseData"]["translatedText"]
        end
        if !(translation = translations[from_text]).blank?
          translation.gsub!(/\(\(([a-z_.]+)\)\)/i, '{{\1}}')
          # Google translate sometimes replaces {{foobar}} with (()) foobar. We skip these
          if translation !~ /\(\(\)\)/
            puts "'#{translation[0, 40]}'"
            I18n.backend.store_translations(ENV['TO'].to_sym, Translate::Keys.to_deep_hash({key => translation}))
          else
            puts "SKIPPING since interpolations were messed up: '#{translation[0,40]}'"
          end
        else
          puts "NO TRANSLATION - #{response.inspect}"
        end
      end
    end

    puts "\nTime elapsed: #{(((Time.now - start_at) / 60) * 10).to_i / 10.to_f} minutes"
    Translate::Storage.new(ENV['TO'].to_sym).write_to_file
  end

  desc "List keys that have changed I18n texts between YAML file ENV['FROM_FILE'] and YAML file ENV['TO_FILE']. Set ENV['VERBOSE'] to see changes"
  task :changed => :environment do
    from_hash = Translate::Keys.to_shallow_hash(Translate::File.new(ENV['FROM_FILE']).read)
    to_hash = Translate::Keys.to_shallow_hash(Translate::File.new(ENV['TO_FILE']).read)
    from_hash.each do |key, from_value|
      if (to_value = to_hash[key]) && to_value != from_value
        key_without_locale = key[/^[^.]+\.(.+)$/, 1]
        if ENV['VERBOSE']
          puts "KEY: #{key_without_locale}"
          puts "FROM VALUE: '#{from_value}'"
          puts "TO VALUE: '#{to_value}'"
        else
          puts key_without_locale
        end
      end
    end
  end

  desc "Apply I18n keys from locales/#locale.yml into the origin file where it should be"
  task :save_to_origin => :environment do
    Translate::Storage.mode = :origin
    error = false
    begin
      I18n.backend.send(:init_translations)
    rescue Exception => e
      error = true
      puts "One dump file do not have the correct format. Check that it is not empty
      and is has a valid YAML structure"
      puts "ORIGINAL ERROR: #{e}"
    end
    I18n.supported_locales.map(&:to_s).each do |locale|
      result = {}
      puts "--------------------------------------------------------------------------"
      puts "Saving translation of locale #{locale.upcase}, please wait"
      filepath = File.join(Rails.root, "config", "locales", "#{locale}.yml")
      # Locale file dump for locale exists
      if File.exists?(filepath)
        new_translations = YAML::load(File.read(filepath))
        if new_translations[locale].present?
          storage = Translate::Storage.new(locale)
          hash = Translate::Keys.to_shallow_hash(new_translations[locale])
          result = storage.write_to_file(hash) unless hash.blank?
        end
      end
      puts "Saved to origin translations of locale #{locale.upcase} to #{result.length} files"
      result.each do |path, keys|
        puts "    Saved to file #{path} #{keys.length} keys"
      end
    end unless error
  end

  desc "Dumps all translations of each language to a unique file con config/locales/#locale.yml"
  task :save_to_application => :environment do
    Translate::Storage.mode = :origin
    I18n.backend.send(:init_translations)
    I18n.supported_locales.map(&:to_s).each do |locale|
      filepath = File.join(Rails.root, "config", "locales", "#{locale}.yml")
      if translations = I18n.backend.send(:translations)[locale.to_sym]
        Translate::File.new(filepath).write(locale => translations)
      end
    end
  end
end
