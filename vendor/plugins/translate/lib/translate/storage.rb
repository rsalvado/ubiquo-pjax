class Translate::Storage
  attr_accessor :locale
  attr_accessor :from_locale
  cattr_accessor :mode

  class OriginTranslationNotFound < StandardError; end

  def initialize(locale, from_locale = nil)
    self.locale = locale.to_sym
    self.from_locale = from_locale.to_sym if from_locale
  end

  #
  # Write a list of translations to filesystem
  # Returns a hash of paths and the keys that have been written
  #
  def write_to_file keys
    init_translations_and_ignore_app_mode_file_dump if self.class.mode == :origin
    # Hash to capture the files updated on origin mode and the keys for each one
    result = {}
    keys.each do |key, value|
      #
      # Search the files where the translation will be applied to
      decide_filenames(key).each do |filename|        
        (result[filename] ||= []) << key
        # Apply the current translation to the filenames
        #
        # It will save a key 'ubiquo.categories.index.title' with a value 'Title'
        # mergin the content of $filename with it
        #
        # Load the file
        hash = YAML.load_file(filename)
        # Morph the translation key
        #   from: 'ubiquo.categories.index.title'
        #   to:   { :ubiquo => {
        #              :categories => {
        #                 :index => {
        #                     :title  => 'Title'
        #                 }
        #             }
        #         }
        #      }
        #   }
        branch_hash = Translate::Keys.to_deep_hash({key => value})
        #
        # Cast all the hash keys to String
        #
        branch_hash = Translate::File.deep_stringify_keys({self.locale => branch_hash})
        #
        # Merge the translation with the content of the file
        #
        #
        hash.deep_merge!(branch_hash)
        #
        # Save to file updated to disk
        Translate::File.new(filename).write(hash)
      end      
    end
    result
  end

  def find_or_create_origin_filename(filename, found_locale)
    #
    # Replace the origin file read from metadata path gessing what might be
    # the path in the locale that we want to translace to
    #
    #   From:
    #     $SOMETHING/$FOUND_LOCALE/models/locale.yml
    #
    #     ie:
    #       $PROJECT_HOME/vendor/plugins/ubiquo_i18n/config/locales/en/models/locale.yml
    #
    #   To:
    #     $SOMETHING/$SELF.LOCALE/models/locale.yml
    #
    #     ie:
    #       $PROJECT_HOME/vendor/plugins/ubiquo_i18n/config/locales/es/models/locale.yml
    #
    suposed_filename = filename.sub(/(.*)\/#{found_locale}\//, "\\1/#{locale}/")

    # The file may not exist, so we check it and create an empty YAML file if not
    if File.exists?(suposed_filename)
      filename = suposed_filename
    else
      filename = suposed_filename
      FileUtils.mkdir_p File.dirname(filename)
      Translate::File.new(filename).write(Translate::File.deep_stringify_keys({self.locale => {}}))
    end
    filename
  end

  #
  # Decide in which files the translations supplied will be saved
  #
  def decide_filenames key
    filenames = []
    # Origin or developer mode, the translations will be applied to the original
    # file where those where setup, including plugin folders
    if self.class.mode == :origin
      filename, found_locale = get_translation_origin_filename(key)
      # If filename is outside rail.root send it to config/locales/external_#{translations_locale_name}.yml
      filename = replace_external_to_application_file_paths(filename) if filename.present?

      # Doesn't exist the translation for current locale, but it does in another
      if found_locale.present? && found_locale.to_s != self.locale.to_s
        # We try to generate the filename replacing the '/existing_locale/' section
        # in path for the new_locale
        filename = find_or_create_origin_filename(filename, found_locale)
      end
      if filename
        filenames << filename
      end
    end
    #
    # Normal app mode, the translation will be dumped together to /config/locales/#{locale}.yml to keep
    # in sync with the original source of the translation
    #
    create_empty_translations_file(application_mode_file_path) if !File.exists?(application_mode_file_path)
    filenames << application_mode_file_path
    #
    # Path to the backup file of the current translation request/transaction
    #
    filenames << log_file_path

    filenames
  end

  # Must ignore  file_path = /config/locales/#{locale}.yml
  def get_translation_origin_filename key, options = {}

    # List of locale where the translation will be looked for
    locales = options[:locales] || ([self.locale] + I18n.available_locales)

    # First locale to try
    current_locale = locales.first

    translation = nil
    begin
      # There are yml files, event translation files that do not start
      # with a locale, so we must avoid them
      #
      # Find the translation in the current_locale
      translation = I18n.t!(key, :locale => current_locale)
      # If we found metadata we return the filename
      if (metadata = translation.instance_variable_get(:@metadata)).present? &&
          metadata[:filename].present?
        return metadata[:filename], current_locale
      end
    # The translation do not exists for the locale checked
    # We select the next available locale or continue to raise
    # an error
    rescue Exception => e
      # The locale is not valid for this translation and origin filename
      locales.delete(current_locale)
      # Select the next one
      current_locale = locales.first
      retry if current_locale
    end

    # puts "Forgetting about key #{key} we could not find the origin translation
    #  (or the unique valid translation was in the dump file)"
    nil
  end

  #
  # We reset i18n load_path to avoid the application mode dump files
  def init_translations_and_ignore_app_mode_file_dump
    # Get the current yaml file list sorted
    files = (I18n.load_path + Dir.glob(File.join("config", "locales", "**","*.{rb,yml}"))).uniq.sort
    # Avoid application mode file paths
    files -= I18n.available_locales.map{|l| application_mode_file_path(l)}
    files -= I18n.available_locales.map{|l| File.join("config", "locales", "#{l}.yml")}
    # Load the new translation file list
    I18n.load_path = files
    # Reset I18n to track the updated file list
    I18n.reload!
    I18n.backend.send(:init_translations)
  end

  #
  # Return a unique backup filename for this translation storage request
  # It will contain all the translations requested
  #
  def log_file_path
    @translation_session ||= "#{Time.now.strftime("%Y-%m-%d-%H-%M-%S-%3N").parameterize}_#{rand(2**8)}"
    file_path = File.join(self.class.root_dir, "tmp", "locales", "log", locale.to_s, "#{@translation_session}.yml.backup")
    create_empty_translations_file(file_path) if !File.exists?(file_path)
    file_path
  end

  def create_empty_translations_file file_path
    FileUtils.mkdir_p File.dirname(file_path)
    Translate::File.new(file_path).write(Translate::File.deep_stringify_keys({self.locale => {}}))
  end

  def replace_external_to_application_file_paths path
    unless File.expand_path(path).include?(File.expand_path(self.class.root_dir))
      path = self.class.external_application_file_path(locale)
      create_empty_translations_file(path) if !File.exists?(path)
    end
    path
  end

  def self.external_application_file_path locale
    File.join(Translate::Storage.root_dir, "config", "locales", "application_external_#{locale}.yml.commit")
  end

  def self.file_paths(locale)
    Dir.glob(File.join(root_dir, "config", "locales", "**","#{locale}.yml"))
  end

  def self.root_dir
    Rails.root
  end

  # Return a path to the dump file of the locale provided
  def application_mode_file_path locale = locale
    File.join(Translate::Storage.root_dir, "config", "locales", "#{locale}.yml")
  end
end

